import Foundation
import FoundationModels

/// Writes the occasional line with Apple's on-device model. Handwritten lines are always the fallback.
enum OysterImproviser {
    /// Roughly one reveal in four gets an improvised line, when the model is available and the setting is on.
    static let chance = 0.25
    static let timeout: Duration = .seconds(4)

    enum Status: Equatable {
        case available
        case unavailable(String)
    }

    static var status: Status {
        switch SystemLanguageModel.default.availability {
        case .available:
            return .available
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible: return .unavailable("This device can't run Apple Intelligence.")
            case .appleIntelligenceNotEnabled: return .unavailable("Turn on Apple Intelligence in Settings.")
            case .modelNotReady: return .unavailable("The model is still downloading.")
            @unknown default: return .unavailable("Not available right now.")
            }
        @unknown default:
            return .unavailable("Not available right now.")
        }
    }

    static func instructions(examples: [String]) -> String {
        """
        You are an oyster in a focus timer app. You are dry, deadpan, and a little tired.
        You speak in one short sentence, sometimes two. Under 90 characters.
        You never cheer, coach, or motivate. Understatement is funnier than enthusiasm.
        Mild disappointment is funnier than praise.
        Don't list the facts back. Use one detail at most, then say how the oyster feels about it,
        or make a dry observation about the oyster's own life on the sea floor.

        Never use exclamation points, emojis, hashtags, or dashes.
        Never make puns about shells, pearls, clams, or fish.
        Never use these words: journey, embark, dive, delve, testament, unlock, amazing, awesome, proud.
        Never start with Ah, Well, Oh, Wow, Behold, Great, or Congratulations.
        Never explain the joke. Never mention being an AI.
        Reply with the line only.

        Examples of your voice:
        \(examples.map { "- \($0)" }.joined(separator: "\n"))
        """
    }

    static func prompt(_ ctx: LineContext) -> String {
        var facts: [String] = []
        if ctx.completed {
            facts.append("The user kept you closed for the full \(ctx.minutes) minutes they planned, right on time. You made them a pearl.")
        } else {
            facts.append("The user opened you early after \(ctx.minutes) minutes. There is no pearl, only a regret.")
        }
        let task = ctx.taskName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !task.isEmpty { facts.append("They were working on: \(task).") }
        for item in ctx.itemsFound where item.rarity != .regret {
            let count = ctx.itemCounts[item.id, default: 1]
            facts.append("You also coughed up a \(item.countName). They now have \(count) of those.")
        }
        if ctx.streakDays >= 2 { facts.append("They have focused \(ctx.streakDays) days in a row.") }
        let hour = Calendar.current.component(.hour, from: ctx.date)
        if (0..<5).contains(hour) { facts.append("It is the middle of the night.") }
        if (5..<7).contains(hour) { facts.append("It is very early in the morning.") }
        facts.append("Write one line reacting to this.")
        return facts.joined(separator: "\n")
    }

    /// Returns a filtered line, or nil if the model is off, slow, unavailable, or wrote something that sounds generated.
    static func improvise(_ ctx: LineContext, examples: [String], recent: [String]) async -> String? {
        let result = await rawAttempt(ctx, examples: examples)
        guard let raw = result else { return nil }
        return LineFilter.clean(raw, recent: recent)
    }

    /// The unfiltered model output. Used by the lab screen to show what gets rejected.
    static func rawAttempt(_ ctx: LineContext, examples: [String]) async -> String? {
        guard status == .available else { return nil }
        let instructions = instructions(examples: examples)
        let prompt = prompt(ctx)
        let timeout = timeout
        return await withTaskGroup(of: String?.self) { group in
            group.addTask {
                let session = LanguageModelSession(instructions: instructions)
                let options = GenerationOptions(temperature: 0.9, maximumResponseTokens: 60)
                return try? await session.respond(to: prompt, options: options).content
            }
            group.addTask {
                try? await Task.sleep(for: timeout)
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
    }
}
