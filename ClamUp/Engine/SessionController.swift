import SwiftUI
import SwiftData

enum Prefs {
    static let improvise = "improvise"
    static let haptics = "haptics"
    static let notifications = "notifications"
    static let skin = "skin"
    static let lastDuration = "lastDuration"
    static let sawHinge = "sawHinge"
    static let activeSession = "activeSession.v1"
}

struct ActiveSession: Codable, Equatable {
    var taskName: String
    var plannedSeconds: Int
    var armedAt: Date
    var startedAt: Date?
}

struct SetProgress: Equatable {
    let set: CollectionSet
    let have: Int
    let total: Int
    var isComplete: Bool { have >= total }
}

struct RevealedItem: Identifiable, Equatable {
    let item: Item
    let isNew: Bool
    let count: Int
    let line: String
    let setProgress: SetProgress?
    var id: String { item.id }
}

struct RevealResult: Identifiable, Equatable {
    let id = UUID()
    let completed: Bool
    let minutes: Int
    let taskName: String
    let pearl: PearlSpec?
    let items: [RevealedItem]
    let streakLine: String?
    let unlockedSkins: [OysterSkin]
}

enum SessionPhase: Equatable {
    /// Nothing going on.
    case idle
    /// Task picked. Waiting for the shell to close.
    case armed
    /// The shell is closed and the pearl is growing.
    case growing
    /// Opened before the pearl was ready. Close it again before the deadline or lose the pearl.
    case prying
    /// Showing what came out of the shell.
    case revealing
}

/// The session state machine. Hinge changes, buttons, and app launches all funnel into `close()` and `open()`.
@Observable
final class SessionController {
    private(set) var phase: SessionPhase = .idle
    private(set) var active: ActiveSession?
    private(set) var reveal: RevealResult?
    private(set) var revealLine = ""
    private(set) var revealLineImprovised = false
    /// True while the on-device model is writing a line for the current reveal.
    private(set) var isImprovising = false
    private(set) var pryDeadline: Date?
    private(set) var hinge: HingeReading = .unavailable

    private(set) var idleLine: String
    private(set) var armedLine = ""
    private(set) var coverLine = ""
    private(set) var readyLine = ""
    private(set) var pryLine = ""

    /// True once this device has ever reported a hinge. Decides between "close the phone" and on-screen buttons.
    private(set) var sawHinge: Bool

    #if DEBUG
    /// Lets the simulator pretend to fold. Real hinge readings still win when they change.
    private(set) var debugFold: HingeReading.Status?
    #endif

    let graceSeconds: TimeInterval = 6

    private let engine: LineEngine
    private let defaults: UserDefaults
    private var modelContext: ModelContext?
    private var savedCatch: Catch?
    private var revealLineShown = false
    private var pryTask: Task<Void, Never>?

    init(context: ModelContext?, engine: LineEngine = .shared, defaults: UserDefaults = .standard) {
        self.modelContext = context
        self.engine = engine
        self.defaults = defaults
        self.sawHinge = defaults.bool(forKey: Prefs.sawHinge)
        self.idleLine = engine.line(.idle)
        restore()
    }

    // MARK: Derived state

    var usesHinge: Bool {
        #if DEBUG
        if debugFold != nil { return true }
        #endif
        return sawHinge
    }

    /// How far open the shell is, in degrees: 0 shut, 180 flat. 180 on phones without a hinge.
    var openDegrees: Double {
        #if DEBUG
        if let angle = Self.debugAngle { return angle }
        if let debugFold { return debugFold == .closed ? 0 : 180 }
        #endif
        return hinge.degrees ?? 180
    }

    #if DEBUG
    /// `-hingeAngle 70` pretends the shell is part open, to check the lighting without a hinge.
    private static let debugAngle: Double? = {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-hingeAngle"), i + 1 < args.count else { return nil }
        return Double(args[i + 1])
    }()
    #endif

    var shellClosed: Bool {
        #if DEBUG
        if let debugFold { return debugFold == .closed }
        #endif
        return hinge.status == .closed
    }

    func elapsed(at now: Date = .now) -> TimeInterval {
        guard let start = active?.startedAt else { return 0 }
        return max(0, now.timeIntervalSince(start))
    }

    func isDone(at now: Date = .now) -> Bool {
        guard let active, active.startedAt != nil else { return false }
        return elapsed(at: now) >= TimeInterval(active.plannedSeconds)
    }

    func progress(at now: Date = .now) -> Double {
        guard let active, active.plannedSeconds > 0 else { return 0 }
        return min(1, elapsed(at: now) / TimeInterval(active.plannedSeconds))
    }

    // MARK: Inputs

    func hingeChanged(_ reading: HingeReading) {
        let previous = hinge.status
        hinge = reading
        if reading.status != .unavailable, !sawHinge {
            sawHinge = true
            defaults.set(true, forKey: Prefs.sawHinge)
        }
        #if DEBUG
        // A real hinge movement takes over from the simulated one.
        if reading.status != .unavailable { debugFold = nil }
        #endif
        guard reading.status != previous || phase == .armed else { return }
        apply(reading.status)
    }

    #if DEBUG
    func debugSetFold(closed: Bool) {
        debugFold = closed ? .closed : .fullyOpen
        apply(debugFold!)
    }

    /// Pretends the session started earlier, so long sessions can be tested without waiting.
    func debugBackdate(by seconds: TimeInterval) {
        guard var session = active, let start = session.startedAt else { return }
        session.startedAt = start.addingTimeInterval(-seconds)
        active = session
        persist()
    }
    #endif

    /// For phones without a hinge, and for testing: same rules as folding.
    func close() { apply(.closed) }
    func open() { apply(.fullyOpen) }

    private func apply(_ status: HingeReading.Status) {
        switch status {
        case .closed: handleClose()
        case .partiallyOpen, .fullyOpen: handleOpen()
        case .unavailable:
            // Leaving a hierarchy that reports the hinge isn't the same as opening. Ignore it.
            break
        }
    }

    private func handleClose() {
        switch phase {
        case .armed:
            start()
        case .prying:
            pryTask?.cancel()
            pryDeadline = nil
            coverLine = engine.line(.cover)
            phase = .growing
        default:
            break
        }
    }

    private func handleOpen() {
        guard phase == .growing else { return }
        if isDone() {
            finish(completed: true)
        } else {
            beginPrying()
        }
    }

    // MARK: Flow

    func arm(task: String, seconds: Int) {
        active = ActiveSession(taskName: task.trimmingCharacters(in: .whitespacesAndNewlines),
                               plannedSeconds: seconds, armedAt: .now, startedAt: nil)
        armedLine = engine.line(.armed)
        phase = .armed
        persist()
        if flag(Prefs.notifications) {
            Task { await PearlNotifications.requestAuthorization() }
        }
        // Already shut, for example when armed from the cover display.
        if shellClosed { start() }
    }

    func cancelArm() {
        guard phase == .armed else { return }
        active = nil
        phase = .idle
        idleLine = engine.line(.idle)
        persist()
    }

    private func start() {
        guard var session = active else { return }
        session.startedAt = .now
        active = session
        coverLine = engine.line(.cover)
        readyLine = engine.line(.ready)
        phase = .growing
        persist()
        if flag(Prefs.notifications) {
            let readyAt = Date.now.addingTimeInterval(TimeInterval(session.plannedSeconds))
            PearlNotifications.scheduleReady(at: readyAt, body: engine.line(.notification))
        }
    }

    private func beginPrying() {
        let deadline = Date.now.addingTimeInterval(graceSeconds)
        pryDeadline = deadline
        pryLine = engine.line(.prying)
        phase = .prying
        pryTask?.cancel()
        pryTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(self?.graceSeconds ?? 6))
            guard !Task.isCancelled else { return }
            self?.checkPryDeadline()
        }
    }

    /// Opening during the grace period on purpose. Ends the session now.
    func giveUp() {
        guard phase == .prying || phase == .growing else { return }
        finish(completed: false)
    }

    /// Called when the app comes back to the foreground, since timers don't run while suspended.
    func refresh() {
        checkPryDeadline()
        if phase == .growing, usesHinge, !shellClosed, hinge.status != .unavailable {
            handleOpen()
        }
    }

    private func checkPryDeadline() {
        guard phase == .prying, let deadline = pryDeadline, Date.now >= deadline else { return }
        finish(completed: false)
    }

    // MARK: Rewards

    private func finish(completed: Bool) {
        guard let session = active, let start = session.startedAt else { return }
        pryTask?.cancel()
        PearlNotifications.cancelReady()

        let now = Date.now
        let focused = completed ? Double(session.plannedSeconds) : min(elapsed(at: now), Double(session.plannedSeconds))
        let history = fetchHistory()
        let completions = history.completions
        let streak = completed ? Streak.current(completions: completions + [now], now: now) : Streak.current(completions: completions, now: now)
        let broken = completed ? Streak.brokenLength(completions: completions, now: now) : 0
        let countsBefore = history.itemCounts
        let completedBefore = history.filter(\.completed).count

        var rng = SystemRandomNumberGenerator()
        let reward = RewardEngine.roll(RewardInput(
            focusedSeconds: focused, completed: completed, streakDays: streak,
            itemCounts: countsBefore, totalCompleted: completedBefore
        ), using: &rng)

        var countsAfter = countsBefore
        for id in reward.itemIDs { countsAfter[id, default: 0] += 1 }

        let items = reward.itemIDs.compactMap { Catalog.item($0) }
        let ctx = LineContext(
            minutes: Int(focused / 60), taskName: session.taskName, streakDays: streak, brokenStreak: broken,
            totalCompleted: completedBefore + (completed ? 1 : 0), date: now, completed: completed,
            itemsFound: items, itemCounts: countsAfter,
            recentPlannedMinutes: ([session.plannedSeconds / 60] + history.filter(\.completed).map { $0.plannedSeconds / 60 })
        )
        let pastTasks = history.map(\.taskName)
        let revealed = items.map { item in
            RevealedItem(
                item: item,
                isNew: countsBefore[item.id, default: 0] == 0,
                count: countsAfter[item.id, default: 1],
                line: engine.itemLine(item, count: countsAfter[item.id, default: 1], pastTasks: pastTasks),
                setProgress: item.set.map { set in
                    SetProgress(set: set, have: set.items.filter { countsAfter[$0.id, default: 0] > 0 }.count, total: set.items.count)
                }
            )
        }

        let skinsBefore = history.unlockedSkins
        let line = engine.revealLine(ctx)
        let record = Catch(
            startDate: start, endDate: now, plannedSeconds: session.plannedSeconds, focusedSeconds: Int(focused),
            taskName: session.taskName, completed: completed, pearl: reward.pearl, itemIDs: reward.itemIDs, line: line
        )
        modelContext?.insert(record)
        try? modelContext?.save()
        savedCatch = record
        let skinsAfter = (history + [record]).unlockedSkins

        reveal = RevealResult(
            completed: completed, minutes: Int(focused / 60), taskName: session.taskName, pearl: reward.pearl,
            items: revealed, streakLine: engine.streakLine(ctx),
            unlockedSkins: OysterSkin.allCases.filter { skinsAfter.contains($0) && !skinsBefore.contains($0) }
        )
        revealLine = line
        revealLineImprovised = false
        revealLineShown = false
        active = nil
        pryDeadline = nil
        phase = .revealing
        persist()

        let improviseOn = flag(Prefs.improvise)
        if improviseOn, Double.random(in: 0..<1) < OysterImproviser.chance {
            let examples = engine.voiceExamples()
            let recent = engine.recentLines
            isImprovising = OysterImproviser.status == .available
            Task { [weak self] in
                let improvised = await OysterImproviser.improvise(ctx, examples: examples, recent: recent)
                self?.isImprovising = false
                if let improvised { self?.useImprovised(improvised) }
            }
        }
    }

    private func useImprovised(_ line: String) {
        guard phase == .revealing, !revealLineShown else { return }
        revealLine = line
        revealLineImprovised = true
    }

    /// The reveal animation calls this when the line appears. After that, a late improvised line can't swap it out.
    func markRevealLineShown() {
        guard !revealLineShown else { return }
        revealLineShown = true
        engine.remember(revealLine)
        savedCatch?.line = revealLine
        savedCatch?.lineImprovised = revealLineImprovised
        try? modelContext?.save()
    }

    func dismissReveal() {
        markRevealLineShown()
        reveal = nil
        savedCatch = nil
        idleLine = engine.line(.idle)
        phase = .idle
    }

    private func fetchHistory() -> [Catch] {
        guard let modelContext else { return [] }
        let descriptor = FetchDescriptor<Catch>(sortBy: [SortDescriptor(\.endDate, order: .reverse)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// A setting that defaults to on. `bool(forKey:)` also understands "YES"/"NO" strings from launch arguments.
    private func flag(_ key: String) -> Bool {
        defaults.object(forKey: key) == nil ? true : defaults.bool(forKey: key)
    }

    // MARK: Persistence

    private func persist() {
        if let active, let data = try? JSONEncoder().encode(active) {
            defaults.set(data, forKey: Prefs.activeSession)
        } else {
            defaults.removeObject(forKey: Prefs.activeSession)
        }
    }

    private func restore() {
        guard let data = defaults.data(forKey: Prefs.activeSession),
              let saved = try? JSONDecoder().decode(ActiveSession.self, from: data) else { return }
        active = saved
        if saved.startedAt != nil {
            // The next hinge reading decides what happened while the app was away.
            coverLine = engine.line(.cover)
            readyLine = engine.line(.ready)
            phase = .growing
        } else if Date.now.timeIntervalSince(saved.armedAt) < 30 * 60 {
            armedLine = engine.line(.armed)
            phase = .armed
        } else {
            active = nil
            persist()
        }
    }
}
