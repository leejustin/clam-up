#if DEBUG
import Foundation
import SwiftData

enum DebugTools {
    /// Launch arguments for testing: `-seedDemo` fills the tide pool, `-resetAll` wipes everything first.
    static func handleLaunchArguments(_ context: ModelContext) {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-resetAll") {
            erase(context)
            UserDefaults.standard.removeObject(forKey: Prefs.activeSession)
            UserDefaults.standard.removeObject(forKey: Prefs.sawHinge)
        }
        if args.contains("-seedDemo") { seed(context) }
    }

    /// `-demo armed|cover|prying|reveal|early` jumps straight to a screen, for screenshots in the simulator.
    /// Runs after a short delay so the simulator's real hinge reading lands first.
    static func runDemo(_ session: SessionController) async {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-demo"), i + 1 < args.count else { return }
        try? await Task.sleep(for: .seconds(1.5))
        switch args[i + 1] {
        case "armed":
            session.arm(task: "Tax return", seconds: 25 * 60)
        case "cover":
            session.arm(task: "Tax return", seconds: 25 * 60)
            session.debugSetFold(closed: true)
        case "prying":
            session.arm(task: "Tax return", seconds: 25 * 60)
            session.debugSetFold(closed: true)
            session.debugSetFold(closed: false)
        case "reveal":
            let seconds = Int(args.dropFirst(i + 2).first ?? "") ?? 0
            session.arm(task: "Thesis chapter 3", seconds: seconds)
            session.debugSetFold(closed: true)
            session.debugBackdate(by: TimeInterval(seconds))
            session.debugSetFold(closed: false)
        case "early":
            session.arm(task: "Emails", seconds: 25 * 60)
            session.debugSetFold(closed: true)
            session.debugSetFold(closed: false)
            session.giveUp()
        case "lab":
            // Prints a batch of improvised lines and the filter's verdict, for tuning from the command line.
            let cap = Catalog.item("bottlecap")!
            let contexts = [
                LineContext(minutes: 25, taskName: "Tax return", totalCompleted: 8),
                LineContext(minutes: 120, taskName: "Thesis", totalCompleted: 40, itemsFound: [cap], itemCounts: ["bottlecap": 12]),
                LineContext(minutes: 6, taskName: "Emails", totalCompleted: 12, completed: false),
            ]
            print("LAB status \(OysterImproviser.status)")
            var passed: [String] = []
            for n in 0..<15 {
                let ctx = contexts[n % contexts.count]
                let raw = await OysterImproviser.rawAttempt(ctx, examples: LineEngine.shared.voiceExamples()) ?? "(no response)"
                switch LineFilter.evaluate(raw, recent: passed) {
                case .success(let line): passed.append(line); print("LAB PASS | \(line)")
                case .failure(let why): print("LAB FAIL (\(why)) | \(raw)")
                }
            }
            print("LAB done \(passed.count)/15")
        default:
            break
        }
    }

    static func seed(_ context: ModelContext) {
        var rng = SeededGenerator(seed: UInt64(Date.now.timeIntervalSince1970))
        let tasks = ["Tax return", "Thesis chapter 3", "Emails", "", "Portfolio site", "Read 40 pages", "Budget", "", "Practice scales", "Cover letter"]
        var counts: [String: Int] = [:]
        var completions: [Date] = []
        var total = 0
        let now = Date.now
        for i in (0..<24).reversed() {
            let end = now.addingTimeInterval(-Double(i) * 60 * 60 * 9 - 3600)
            let planned = [10, 25, 25, 45, 60, 90].randomElement(using: &rng)! * 60
            let completed = Double.random(in: 0..<1, using: &rng) > 0.15
            let focused = completed ? planned : Int(Double(planned) * .random(in: 0.1...0.7, using: &rng))
            if completed { completions.append(end) }
            let streak = Streak.current(completions: completions, now: end)
            let reward = RewardEngine.roll(RewardInput(focusedSeconds: Double(focused), completed: completed, streakDays: streak,
                                                       itemCounts: counts, totalCompleted: total), using: &rng)
            for id in reward.itemIDs { counts[id, default: 0] += 1 }
            if completed { total += 1 }
            let record = Catch(startDate: end.addingTimeInterval(-Double(focused)), endDate: end, plannedSeconds: planned,
                               focusedSeconds: focused, taskName: tasks.randomElement(using: &rng)!, completed: completed,
                               pearl: reward.pearl, itemIDs: reward.itemIDs,
                               line: completed ? LineLibrary.completeMedium.randomElement(using: &rng)! : LineLibrary.early.randomElement(using: &rng)!)
            context.insert(record)
        }
        try? context.save()
    }

    static func erase(_ context: ModelContext) {
        try? context.delete(model: Catch.self)
        try? context.save()
    }
}
#endif
