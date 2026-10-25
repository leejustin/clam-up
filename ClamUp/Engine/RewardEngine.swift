import Foundation

struct RewardInput {
    var focusedSeconds: Double
    var completed: Bool
    /// Streak including the session being rewarded.
    var streakDays: Int
    var itemCounts: [String: Int]
    var totalCompleted: Int
}

struct Reward: Equatable {
    var pearl: PearlSpec?
    var itemIDs: [String]
}

enum RewardEngine {
    static let dropChance = 0.6

    static func rolls(forMinutes minutes: Double) -> Int {
        switch minutes {
        case ..<45: 1
        case ..<90: 2
        default: 3
        }
    }

    /// Rarity weights in percent. Streaks and long sessions lean toward the good stuff.
    static func weights(streakDays: Int, minutes: Double) -> [(Rarity, Double)] {
        let luck = Double(min(streakDays, 14)) * 0.5
        let deep = minutes >= 90 ? 3.0 : 0
        return [
            (.common, 68 - luck * 1.5 - deep),
            (.uncommon, 23 + luck * 0.5),
            (.rare, 8 + luck * 0.7 + deep * 0.8),
            (.legendary, 1 + luck * 0.3 + deep * 0.2),
        ]
    }

    static func roll<R: RandomNumberGenerator>(_ input: RewardInput, using rng: inout R) -> Reward {
        let minutes = input.focusedSeconds / 60

        guard input.completed else {
            // Opening early always gives you something. It's just never good.
            let regret = Catalog.items(of: .regret).randomElement(using: &rng)!
            return Reward(pearl: nil, itemIDs: [regret.id])
        }

        var jitter = Double.random(in: -1...1, using: &rng)
        if abs(jitter) < 0.01 { jitter = 0.01 }
        var color = PearlColor.forStreak(input.streakDays)
        // A small chance of a black pearl on any day keeps things interesting.
        if color != .black, Double.random(in: 0..<1, using: &rng) < 0.02 { color = .black }
        let pearl = PearlSpec(
            size: PearlSpec.size(forMinutes: minutes),
            color: color,
            hueJitter: jitter,
            grade: .forMinutes(minutes)
        )

        // Your very first pearl always comes with a bottle cap, so the joke lands.
        if input.totalCompleted == 0 {
            return Reward(pearl: pearl, itemIDs: ["bottlecap"])
        }

        var found: [String] = []
        let table = weights(streakDays: input.streakDays, minutes: minutes)
        for _ in 0..<rolls(forMinutes: minutes) {
            guard Double.random(in: 0..<1, using: &rng) < dropChance else { continue }
            let rarity = pick(table, using: &rng)
            let candidates = Catalog.items(of: rarity).filter { !found.contains($0.id) }
            guard !candidates.isEmpty else { continue }
            // Undiscovered items are a little more likely, which helps finish sets.
            let weighted = candidates.map { ($0, input.itemCounts[$0.id, default: 0] == 0 ? 1.5 : 1.0) }
            found.append(pick(weighted, using: &rng).id)
        }
        return Reward(pearl: pearl, itemIDs: found)
    }

    static func pick<T, R: RandomNumberGenerator>(_ weighted: [(T, Double)], using rng: inout R) -> T {
        let total = weighted.reduce(0) { $0 + max(0, $1.1) }
        var roll = Double.random(in: 0..<total, using: &rng)
        for (value, weight) in weighted {
            roll -= max(0, weight)
            if roll < 0 { return value }
        }
        return weighted[weighted.count - 1].0
    }
}
