import Testing
import Foundation
import SwiftData
@testable import ClamUp

private func freshDefaults() -> UserDefaults {
    let name = "clamup-tests-\(UUID().uuidString)"
    let d = UserDefaults(suiteName: name)!
    d.removePersistentDomain(forName: name)
    return d
}

// MARK: Shuffle bags

struct ShuffleBagTests {
    @Test func dealsEveryLineBeforeRepeating() {
        let bags = ShuffleBagStore(defaults: freshDefaults())
        var rng = SeededGenerator(seed: 1)
        let drawn = (0..<10).map { _ in bags.next(pool: "p", count: 10, using: &rng) }
        #expect(Set(drawn).count == 10)
    }

    @Test func neverRepeatsAcrossReshuffles() {
        let bags = ShuffleBagStore(defaults: freshDefaults())
        for seed in 1...200 {
            var rng = SeededGenerator(seed: UInt64(seed))
            var last: Int?
            for _ in 0..<30 {
                let next = bags.next(pool: "p\(seed)", count: 4, using: &rng)
                #expect(next != last)
                last = next
            }
        }
    }

    @Test func rotationSurvivesRelaunch() {
        let defaults = freshDefaults()
        var rng = SeededGenerator(seed: 9)
        var seen: [Int] = []
        let first = ShuffleBagStore(defaults: defaults)
        for _ in 0..<3 { seen.append(first.next(pool: "p", count: 6, using: &rng)) }
        let second = ShuffleBagStore(defaults: defaults)
        for _ in 0..<3 { seen.append(second.next(pool: "p", count: 6, using: &rng)) }
        #expect(Set(seen).count == 6)
    }

    @Test func handlesPoolGrowingInAnUpdate() {
        let bags = ShuffleBagStore(defaults: freshDefaults())
        var rng = SeededGenerator(seed: 3)
        _ = bags.next(pool: "p", count: 3, using: &rng)
        let drawn = (0..<8).map { _ in bags.next(pool: "p", count: 8, using: &rng) }
        #expect(Set(drawn).count == 8)
        #expect(drawn.allSatisfy { $0 < 8 })
    }
}

// MARK: Line filter

struct LineFilterTests {
    @Test func acceptsTheOystersVoice() {
        #expect(LineFilter.clean("Someone in 1987 really enjoyed this soda.") == "Someone in 1987 really enjoyed this soda.")
        #expect(LineFilter.clean("Another bottle cap. That's twelve. Are you okay?") != nil)
        #expect(LineFilter.clean("One. Two. Three. Four.") == nil) // four sentences is a paragraph
        #expect(LineFilter.clean("Twelve bottle caps. The oyster is concerned.") != nil)
    }

    @Test func stripsWrappingQuotesAndAddsAPeriod() {
        #expect(LineFilter.clean("\"The oyster has seen worse\"") == "The oyster has seen worse.")
        #expect(LineFilter.clean("- A pearl. Don't make it weird.") == "A pearl. Don't make it weird.")
    }

    @Test(arguments: [
        ("Great job! You crushed it.", "exclamation"),
        ("Pearl-fect work today.", "pun"),
        ("Ah, another pearl for the collection.", "opener"),
        ("Well, that took a while.", "opener"),
        ("Your journey continues, one pearl at a time.", "hype"),
        ("A pearl 🦪 for you.", "emoji"),
        ("A pearl — finally.", "dash"),
        ("Time to shell-ebrate.", "pun"),
        ("As an AI, I can't make pearls.", "meta"),
        ("#focus #pearls", "hashtag"),
        ("This line goes on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on forever.", "length"),
        ("It's not just a pearl, it's a statement.", "structure"),
        ("The oyster feels the weight of the dark.", "model crutch"),
    ])
    func rejectsAIisms(line: String, kind: String) {
        #expect(LineFilter.clean(line) == nil, "Should reject \(kind): \(line)")
    }

    @Test func rejectsRepeatsOfRecentLines() {
        let recent = ["That's a big one. The oyster needs to lie down."]
        #expect(LineFilter.clean("That's a big one. The oyster needs a lie down.", recent: recent) == nil)
        #expect(LineFilter.clean("The oyster has never been this tired.", recent: recent) != nil)
    }

    @Test func everyHandwrittenLinePassesTheSameRules() {
        let all = LineMoment.allCases.flatMap { LineLibrary.pool($0) } + Catalog.all.flatMap(\.lines) + Array(LineLibrary.milestones.values)
        for line in all {
            let filled = line
                .replacingOccurrences(of: "{minutes}", with: "25")
                .replacingOccurrences(of: "{days}", with: "4")
                .replacingOccurrences(of: "{task}", with: "Taxes")
                .replacingOccurrences(of: "{time}", with: "2:14am")
            if case .failure(let why) = LineFilter.evaluate(filled) {
                Issue.record("Handwritten line fails (\(why)): \(line)")
            }
        }
    }
}

// MARK: Rewards

struct RewardTests {
    private func input(minutes: Double = 25, completed: Bool = true, streak: Int = 1, total: Int = 5) -> RewardInput {
        RewardInput(focusedSeconds: minutes * 60, completed: completed, streakDays: streak, itemCounts: [:], totalCompleted: total)
    }

    @Test func firstPearlAlwaysComesWithABottleCap() {
        for seed in 1...50 {
            var rng = SeededGenerator(seed: UInt64(seed))
            let reward = RewardEngine.roll(input(total: 0), using: &rng)
            #expect(reward.pearl != nil)
            #expect(reward.itemIDs == ["bottlecap"])
        }
    }

    @Test func openingEarlyGivesExactlyOneRegretAndNoPearl() {
        for seed in 1...50 {
            var rng = SeededGenerator(seed: UInt64(seed))
            let reward = RewardEngine.roll(input(completed: false), using: &rng)
            #expect(reward.pearl == nil)
            #expect(reward.itemIDs.count == 1)
            #expect(Catalog.item(reward.itemIDs[0])?.rarity == .regret)
        }
    }

    @Test func longerSessionsGetMoreRollsAndBiggerPearls() {
        #expect(RewardEngine.rolls(forMinutes: 25) == 1)
        #expect(RewardEngine.rolls(forMinutes: 60) == 2)
        #expect(RewardEngine.rolls(forMinutes: 120) == 3)
        #expect(PearlSpec.size(forMinutes: 10) < PearlSpec.size(forMinutes: 60))
        #expect(PearlSpec.size(forMinutes: 60) < PearlSpec.size(forMinutes: 120))
        #expect(PearlSpec.size(forMinutes: 600) == 1)
    }

    @Test func neverMoreItemsThanRollsAndNoDuplicates() {
        for seed in 1...300 {
            var rng = SeededGenerator(seed: UInt64(seed))
            let reward = RewardEngine.roll(input(minutes: 120, streak: 10), using: &rng)
            #expect(reward.itemIDs.count <= 3)
            #expect(Set(reward.itemIDs).count == reward.itemIDs.count)
            #expect(reward.itemIDs.allSatisfy { Catalog.item($0)?.rarity != .regret })
        }
    }

    @Test func streaksImproveTheOdds() {
        let cold = Dictionary(uniqueKeysWithValues: RewardEngine.weights(streakDays: 0, minutes: 25).map { ($0.0, $0.1) })
        let hot = Dictionary(uniqueKeysWithValues: RewardEngine.weights(streakDays: 14, minutes: 25).map { ($0.0, $0.1) })
        #expect(hot[.rare]! > cold[.rare]!)
        #expect(hot[.legendary]! > cold[.legendary]!)
        #expect(hot[.common]! < cold[.common]!)
        #expect(hot.values.allSatisfy { $0 > 0 })
    }

    @Test func pearlColorFollowsTheStreak() {
        #expect(PearlColor.forStreak(1) == .white)
        #expect(PearlColor.forStreak(3) == .rose)
        #expect(PearlColor.forStreak(7) == .gold)
        #expect(PearlColor.forStreak(30) == .black)
    }

    @Test func everySetCanBeCompleted() {
        for set in CollectionSet.allCases {
            #expect(set.items.count >= 3, "\(set.name) is too small")
        }
        #expect(Set(Catalog.all.map(\.id)).count == Catalog.all.count, "Duplicate item ids")
    }
}

// MARK: Streaks and recaps

struct StreakTests {
    let cal = Calendar(identifier: .gregorian)
    func day(_ offset: Int, from now: Date) -> Date { cal.date(byAdding: .day, value: offset, to: now)! }

    @Test func countsConsecutiveDays() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        #expect(Streak.current(completions: [], now: now, calendar: cal) == 0)
        #expect(Streak.current(completions: [now, day(-1, from: now), day(-2, from: now)], now: now, calendar: cal) == 3)
        // Yesterday still counts, so the streak isn't lost before you've had a chance today.
        #expect(Streak.current(completions: [day(-1, from: now), day(-2, from: now)], now: now, calendar: cal) == 2)
        #expect(Streak.current(completions: [day(-2, from: now)], now: now, calendar: cal) == 0)
    }

    @Test func detectsABrokenStreak() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let old = [day(-3, from: now), day(-4, from: now), day(-5, from: now)]
        #expect(Streak.brokenLength(completions: old, now: now, calendar: cal) == 3)
        #expect(Streak.brokenLength(completions: [day(-1, from: now)], now: now, calendar: cal) == 0)
    }

    @Test func pluralizesOddItemNames() {
        #expect(Recap.plural("bottle cap") == "bottle caps")
        #expect(Recap.plural("set of dentures") == "sets of dentures")
        #expect(Recap.plural("pair of sunglasses") == "pairs of sunglasses")
        #expect(Recap.plural("compass") == "compasses")
        #expect(Recap.plural("startled fish") == "startled fish")
        #expect(Recap.count(1, "sock") == "one sock")
    }
}

// MARK: Line engine

struct LineEngineTests {
    @Test func fillsPlaceholders() {
        let engine = LineEngine(bags: ShuffleBagStore(defaults: freshDefaults()), defaults: freshDefaults())
        let ctx = LineContext(minutes: 90, taskName: "  Taxes ", streakDays: 4)
        #expect(engine.fill("{minutes} min, day {days}, \"{task}\"", ctx) == "90 min, day 4, \"Taxes\"")
        #expect(engine.fill("\"{task}\"", LineContext()) == "\"whatever that was\"")
    }

    @Test func revealLinesNeverContainRawPlaceholders() {
        let engine = LineEngine(bags: ShuffleBagStore(defaults: freshDefaults()), defaults: freshDefaults())
        for i in 0..<300 {
            let ctx = LineContext(minutes: [5, 25, 60, 120][i % 4], taskName: i % 3 == 0 ? "" : "Essay",
                                  streakDays: i % 6, totalCompleted: i, completed: i % 7 != 0)
            let line = engine.revealLine(ctx)
            #expect(!line.contains("{") && !line.contains("}"), "Unfilled: \(line)")
            #expect(!line.isEmpty)
        }
    }

    @Test func firstPearlGetsTheFirstPearlLine() {
        let engine = LineEngine(bags: ShuffleBagStore(defaults: freshDefaults()), defaults: freshDefaults())
        let line = engine.revealLine(LineContext(minutes: 25, totalCompleted: 1))
        #expect(LineLibrary.firstEver.contains(line) || LineLibrary.secret.contains(line))
    }
}

// MARK: Session state machine

@MainActor
struct SessionTests {
    /// The container is returned too, so it stays alive for the whole test.
    private func makeSession() throws -> (SessionController, ModelContext, ModelContainer) {
        let container = try ModelContainer(for: Catch.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let defaults = freshDefaults()
        defaults.set(false, forKey: Prefs.notifications)
        defaults.set(false, forKey: Prefs.improvise)
        let engine = LineEngine(bags: ShuffleBagStore(defaults: defaults), defaults: defaults)
        let session = SessionController(context: container.mainContext, engine: engine, defaults: defaults)
        return (session, container.mainContext, container)
    }

    @Test func closingTheShellStartsTheSession() throws {
        let (session, _, container) = try makeSession(); _ = container
        session.hingeChanged(HingeReading(status: .fullyOpen, degrees: 180))
        session.arm(task: "Essay", seconds: 1500)
        #expect(session.phase == .armed)
        session.hingeChanged(HingeReading(status: .closed, degrees: 0))
        #expect(session.phase == .growing)
        #expect(session.active?.startedAt != nil)
    }

    @Test func openingEarlyStartsTheGracePeriodAndClosingResumes() throws {
        let (session, _, container) = try makeSession(); _ = container
        session.hingeChanged(HingeReading(status: .fullyOpen, degrees: 180))
        session.arm(task: "", seconds: 1500)
        session.hingeChanged(HingeReading(status: .closed, degrees: 0))
        session.hingeChanged(HingeReading(status: .partiallyOpen, degrees: 40))
        #expect(session.phase == .prying)
        #expect(session.pryDeadline != nil)
        session.hingeChanged(HingeReading(status: .closed, degrees: 0))
        #expect(session.phase == .growing)
        #expect(session.pryDeadline == nil)
    }

    @Test func givingUpRecordsARegret() throws {
        let (session, context, container) = try makeSession(); _ = container
        session.arm(task: "Emails", seconds: 1500)
        session.close()
        session.open()
        session.giveUp()
        #expect(session.phase == .revealing)
        #expect(session.reveal?.completed == false)
        #expect(session.reveal?.pearl == nil)
        let saved = try context.fetch(FetchDescriptor<Catch>())
        #expect(saved.count == 1)
        #expect(saved[0].completed == false)
        #expect(saved[0].items.first?.rarity == .regret)
    }

    @Test func openingAfterTimeIsUpGivesAPearl() throws {
        let (session, context, container) = try makeSession(); _ = container
        session.arm(task: "Taxes", seconds: 0)
        session.close()
        #expect(session.isDone())
        session.open()
        #expect(session.phase == .revealing)
        #expect(session.reveal?.completed == true)
        #expect(session.reveal?.pearl != nil)
        #expect(session.reveal?.items.map(\.item.id) == ["bottlecap"])
        session.dismissReveal()
        #expect(session.phase == .idle)
        let saved = try context.fetch(FetchDescriptor<Catch>())
        #expect(saved.first?.taskName == "Taxes")
        #expect(saved.first?.line.isEmpty == false)
    }

    @Test func losingTheHingeSignalIsNotAnEarlyOpen() throws {
        let (session, _, container) = try makeSession(); _ = container
        session.hingeChanged(HingeReading(status: .fullyOpen, degrees: 180))
        session.arm(task: "", seconds: 1500)
        session.hingeChanged(HingeReading(status: .closed, degrees: 0))
        session.hingeChanged(.unavailable)
        #expect(session.phase == .growing)
    }

    @Test func armingWhileAlreadyClosedStartsRightAway() throws {
        let (session, _, container) = try makeSession(); _ = container
        session.hingeChanged(HingeReading(status: .closed, degrees: 0))
        session.arm(task: "", seconds: 600)
        #expect(session.phase == .growing)
    }

    @Test func cancelReturnsToIdle() throws {
        let (session, _, container) = try makeSession(); _ = container
        session.arm(task: "", seconds: 600)
        session.cancelArm()
        #expect(session.phase == .idle)
        #expect(session.active == nil)
    }
}
