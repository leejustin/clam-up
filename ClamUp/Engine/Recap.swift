import Foundation

enum Recap {
    /// "a bottle cap", "3 bottle caps", "2 sets of dentures".
    static func count(_ n: Int, _ countName: String) -> String {
        n == 1 ? "one \(countName)" : "\(n) \(plural(countName))"
    }

    static func plural(_ name: String) -> String {
        if name == "half a pearl" { return "half pearls" }
        if name.hasSuffix("fish") { return name }
        for joiner in [" of ", " in ", " with "] where name.contains(joiner) {
            let parts = name.components(separatedBy: joiner)
            return plural(parts[0]) + joiner + parts.dropFirst().joined(separator: joiner)
        }
        if name.hasSuffix("ss") || name.hasSuffix("sh") || name.hasSuffix("ch") { return name + "es" }
        return name + "s"
    }

    /// "This week you grew 12 pearls, found 4 bottle caps, and one very startled fish."
    static func week(_ catches: [Catch]) -> String {
        let pearls = catches.filter { $0.pearl != nil }.count
        guard !catches.isEmpty else { return "Nothing this week yet. The string is just a string." }

        var counts: [String: Int] = [:]
        for c in catches { for id in c.itemIDs { counts[id, default: 0] += 1 } }
        let ranked = counts.sorted { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value }
            .compactMap { pair in Catalog.item(pair.key).map { ($0, pair.value) } }

        var parts = ["grew \(pearls == 1 ? "one pearl" : "\(pearls) pearls")"]
        let finds = ranked.prefix(2).map { count($0.1, $0.0.countName) }
        if !finds.isEmpty { parts.append("found " + finds.joined(separator: " and ")) }
        let early = catches.filter { !$0.completed }.count
        if early > 0 { parts.append("opened early \(early == 1 ? "once" : "\(early) times")") }

        let list: String
        switch parts.count {
        case 1: list = parts[0]
        case 2: list = "\(parts[0]) and \(parts[1])"
        default: list = parts.dropLast().joined(separator: ", ") + ", and " + parts.last!
        }
        return "This week you \(list)."
    }
}
