import Foundation

/// Rejects lines that sound generated. Every improvised line passes through here before anyone sees it.
enum LineFilter {
    enum Rejection: Error, Equatable, CustomStringConvertible {
        case empty, tooLong, tooManySentences, exclamation, emoji, dash, hashtag
        case bannedOpener(String), bannedPhrase(String), tooSimilar, meta

        var description: String {
            switch self {
            case .empty: "empty"
            case .tooLong: "too long"
            case .tooManySentences: "more than three sentences"
            case .exclamation: "exclamation point"
            case .emoji: "emoji"
            case .dash: "dash"
            case .hashtag: "hashtag"
            case .bannedOpener(let s): "opener \"\(s)\""
            case .bannedPhrase(let s): "phrase \"\(s)\""
            case .tooSimilar: "too close to a recent line"
            case .meta: "talks about being an AI"
            }
        }
    }

    static let maxLength = 110

    static let bannedOpeners = [
        "ah", "well", "oh", "behold", "fun fact", "wow", "congrat", "great", "nice job", "good job",
        "hey there", "alright", "so,", "look at you", "here's", "sure,", "certainly", "absolutely,", "absolutely!",
    ]

    static let bannedPhrases = [
        // Hype and coaching
        "journey", "embark", "dive in", "dive into", "delve", "testament", "unlock", "crush it", "crushed it",
        "you've got this", "you got this", "keep it up", "keep up the", "proud of you", "so proud", "amazing",
        "awesome", "incredible", "fantastic", "superstar", "rockstar", "level up", "game changer", "game-changer",
        "champ", "buddy", "my friend", "remember,", "tapestry", "vibrant", "realm", "elevate", "unleash",
        "whether you're", "not just", "it's not about", "at the end of the day", "in a world",
        // Crutches the on-device model leans on, found with the oyster lab
        "the weight of", "feels the weight", "heavier now",
        // Theme puns the model reaches for
        "shell-ebrate", "shellebrate", "pearl-fect", "pearlfect", "shellfish", "clam-tastic", "clamtastic",
        "oyster-ly", "shell yeah", "shell-ver", "pearly gates", "shucks", "oh my cod", "holy mackerel",
        "you're a pearl", "world is your oyster",
    ]

    static let metaPhrases = ["as an ai", "language model", "i cannot", "i can't help", "here is a line", "here's a line", "line:"]

    /// Cleans a raw model response and returns it, or the reason it was rejected.
    static func evaluate(_ raw: String, recent: [String] = []) -> Result<String, Rejection> {
        var line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        // Models often wrap the answer in quotes or prefix it with a dash.
        let wrappers = CharacterSet(charactersIn: "\"“”'‘’*-• ")
        line = line.trimmingCharacters(in: wrappers)
        if let firstLine = line.split(separator: "\n").first { line = String(firstLine) }
        line = line.trimmingCharacters(in: .whitespaces)
        if !line.isEmpty, let last = line.last, !".?\"".contains(last) { line += "." }

        guard !line.isEmpty, line.count > 3 else { return .failure(.empty) }
        guard line.count <= maxLength else { return .failure(.tooLong) }

        let lower = line.lowercased()
        if metaPhrases.contains(where: lower.contains) { return .failure(.meta) }
        if line.contains("!") { return .failure(.exclamation) }
        if line.contains("#") { return .failure(.hashtag) }
        if line.contains("—") || line.contains("–") || line.contains(" - ") || line.contains("--") { return .failure(.dash) }
        if containsEmoji(line) { return .failure(.emoji) }
        // The oyster talks in clipped fragments, so three short sentences is fine. The length cap keeps it tight.
        if sentenceCount(line) > 3 { return .failure(.tooManySentences) }
        if let opener = bannedOpeners.first(where: { lower.hasPrefix($0) }) { return .failure(.bannedOpener(opener)) }
        if let phrase = bannedPhrases.first(where: { lower.contains($0) }) { return .failure(.bannedPhrase(phrase)) }
        if recent.contains(where: { similarity($0, line) > 0.6 }) { return .failure(.tooSimilar) }
        return .success(line)
    }

    static func clean(_ raw: String, recent: [String] = []) -> String? {
        if case .success(let line) = evaluate(raw, recent: recent) { return line }
        return nil
    }

    static func containsEmoji(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            scalar.properties.isEmojiPresentation || (scalar.properties.isEmoji && scalar.value > 0x238C)
        }
    }

    static func sentenceCount(_ text: String) -> Int {
        // Count sentence-ending punctuation that is followed by a space or the end of the line.
        let chars = Array(text)
        var count = 0
        for (i, c) in chars.enumerated() where ".?".contains(c) {
            let next = i + 1 < chars.count ? chars[i + 1] : " "
            let prev = i > 0 ? chars[i - 1] : " "
            if (next == " " || next == "\"") && prev != "." { count += 1 }
        }
        return max(count, 1)
    }

    /// Word-set Jaccard similarity.
    static func similarity(_ a: String, _ b: String) -> Double {
        func words(_ s: String) -> Set<String> {
            Set(s.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init))
        }
        let wa = words(a), wb = words(b)
        guard !wa.isEmpty, !wb.isEmpty else { return 0 }
        return Double(wa.intersection(wb).count) / Double(wa.union(wb).count)
    }
}
