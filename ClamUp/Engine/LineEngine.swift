import Foundation

struct LineContext {
    var minutes: Int = 0
    var taskName: String = ""
    var streakDays: Int = 0
    var brokenStreak: Int = 0
    /// Completed sessions including this one.
    var totalCompleted: Int = 0
    var date: Date = .now
    var completed: Bool = true
    var itemsFound: [Item] = []
    var itemCounts: [String: Int] = [:]
    /// Planned minutes of the last few completed sessions, newest first.
    var recentPlannedMinutes: [Int] = []
}

/// Picks what the oyster says. Handwritten pools carry the voice. Context lines and improvised lines add surprise.
final class LineEngine {
    static let shared = LineEngine(bags: .shared, defaults: .standard)

    private let bags: ShuffleBagStore
    private let defaults: UserDefaults
    private let recentKey = "recentLines.v1"

    init(bags: ShuffleBagStore, defaults: UserDefaults) {
        self.bags = bags
        self.defaults = defaults
    }

    // MARK: Pools

    func line(_ moment: LineMoment, _ ctx: LineContext = LineContext()) -> String {
        let pool = LineLibrary.pool(moment)
        let index = bags.next(pool: moment.rawValue, count: pool.count)
        return fill(pool[index], ctx)
    }

    func fill(_ template: String, _ ctx: LineContext) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        formatter.amSymbol = "am"
        formatter.pmSymbol = "pm"
        let task = ctx.taskName.trimmingCharacters(in: .whitespacesAndNewlines)
        return template
            .replacingOccurrences(of: "{minutes}", with: "\(ctx.minutes)")
            .replacingOccurrences(of: "{days}", with: "\(ctx.streakDays)")
            .replacingOccurrences(of: "{task}", with: task.isEmpty ? "whatever that was" : task)
            .replacingOccurrences(of: "{time}", with: formatter.string(from: ctx.date))
    }

    // MARK: Reveal

    /// The oyster's main comment when the shell opens.
    func revealLine(_ ctx: LineContext) -> String {
        guard ctx.completed else { return line(.early, ctx) }

        if Int.random(in: 0..<200) == 0 { return line(.secret, ctx) }
        if ctx.totalCompleted == 1 { return line(.firstEver, ctx) }
        if let milestone = LineLibrary.milestones[ctx.totalCompleted] { return milestone }
        if let contextual = contextualLine(ctx), Double.random(in: 0..<1) < 0.35 { return contextual }
        if ctx.totalCompleted >= 50, Double.random(in: 0..<1) < 0.15 { return line(.veteran, ctx) }

        switch ctx.minutes {
        case ..<30: return line(.completeShort, ctx)
        case ..<90: return line(.completeMedium, ctx)
        default: return line(.completeLong, ctx)
        }
    }

    /// Lines that react to the situation. These feel fresh because the situation is new.
    func contextualLine(_ ctx: LineContext) -> String? {
        let hour = Calendar.current.component(.hour, from: ctx.date)
        var options: [String] = []

        if (0..<5).contains(hour) { options.append(line(.lateNight, ctx)) }
        if (5..<7).contains(hour) { options.append(line(.earlyMorning, ctx)) }
        if !ctx.taskName.trimmingCharacters(in: .whitespaces).isEmpty { options.append(line(.taskNamed, ctx)) }

        let recent = ctx.recentPlannedMinutes.prefix(5)
        if recent.count == 5, Set(recent).count == 1, let m = recent.first {
            options.append("You always pick \(m) minutes. Predictable. I like that.")
        }
        return options.randomElement()
    }

    func streakLine(_ ctx: LineContext) -> String? {
        guard ctx.completed else { return nil }
        if ctx.brokenStreak >= 3 { return line(.streakBroken, ctx) }
        switch ctx.streakDays {
        case 1: return ctx.totalCompleted > 1 ? line(.streakStart, ctx) : nil
        case 2...: return line(.streakContinue, ctx)
        default: return nil
        }
    }

    // MARK: Items

    /// A flavor line for an item card. `count` includes this find.
    func itemLine(_ item: Item, count: Int, pastTasks: [String]) -> String {
        if item.id == "bottle", let task = pastTasks.filter({ !$0.isEmpty }).randomElement(), Bool.random() {
            return "The note inside says \"\(task)\". It's in your handwriting."
        }
        if count >= 5, item.rarity == .common, Double.random(in: 0..<1) < 0.4 {
            let options = [
                "That's \(item.countName) number \(count). Are you okay?",
                "\(item.countName.prefix(1).uppercased() + item.countName.dropFirst()) number \(count). This is a collection now.",
                "Another \(item.countName). That's \(count). The oyster is running out of shelf.",
            ]
            return options.randomElement()!
        }
        let index = bags.next(pool: "item.\(item.id)", count: item.lines.count)
        return item.lines[index]
    }

    // MARK: Recent memory

    var recentLines: [String] { defaults.stringArray(forKey: recentKey) ?? [] }

    func remember(_ line: String) {
        var recent = recentLines
        recent.insert(line, at: 0)
        defaults.set(Array(recent.prefix(40)), forKey: recentKey)
    }

    /// A few handwritten lines to show the model what the voice sounds like. Rotated so the model doesn't parrot the same four.
    func voiceExamples(count: Int = 5) -> [String] {
        let source = LineLibrary.completeShort + LineLibrary.completeMedium + LineLibrary.early + LineLibrary.prying
            + Catalog.all.flatMap(\.lines)
        return Array(source.filter { !$0.contains("{") }.shuffled().prefix(count))
    }
}
