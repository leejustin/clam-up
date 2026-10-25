import Foundation

/// Deals every line in a pool once before repeating, and never repeats a line across a reshuffle.
/// State is persisted so rotation survives app launches.
final class ShuffleBagStore {
    static let shared = ShuffleBagStore(defaults: .standard)

    private struct Bag: Codable {
        var remaining: [Int]
        var last: Int?
        var size: Int
    }

    private let defaults: UserDefaults
    private let key = "shuffleBags.v1"
    private var bags: [String: Bag]

    init(defaults: UserDefaults) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode([String: Bag].self, from: data) {
            bags = decoded
        } else {
            bags = [:]
        }
    }

    /// Returns the next index for a pool of `count` items.
    func next<R: RandomNumberGenerator>(pool name: String, count: Int, using rng: inout R) -> Int {
        precondition(count > 0, "Empty pool \(name)")
        if count == 1 { return 0 }

        var bag = bags[name] ?? Bag(remaining: [], last: nil, size: count)
        if bag.size != count {
            // The pool changed in an app update. Start a fresh round.
            bag = Bag(remaining: [], last: bag.last.flatMap { $0 < count ? $0 : nil }, size: count)
        }
        if bag.remaining.isEmpty {
            var fresh = Array(0..<count).shuffled(using: &rng)
            // Make sure the end of one round doesn't repeat at the start of the next.
            if let last = bag.last, fresh.last == last {
                fresh.swapAt(fresh.count - 1, 0)
            }
            bag.remaining = fresh
        }
        let index = bag.remaining.removeLast()
        bag.last = index
        bags[name] = bag
        save()
        return index
    }

    func next(pool name: String, count: Int) -> Int {
        var rng = SystemRandomNumberGenerator()
        return next(pool: name, count: count, using: &rng)
    }

    func reset() {
        bags = [:]
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(bags) {
            defaults.set(data, forKey: key)
        }
    }
}
