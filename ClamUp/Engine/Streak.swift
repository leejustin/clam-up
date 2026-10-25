import Foundation

enum Streak {
    /// Consecutive days with at least one completed session, ending today or yesterday.
    static func current(completions: [Date], now: Date = .now, calendar: Calendar = .current) -> Int {
        let days = Set(completions.map { calendar.startOfDay(for: $0) })
        let today = calendar.startOfDay(for: now)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }
        var cursor: Date
        if days.contains(today) { cursor = today } else if days.contains(yesterday) { cursor = yesterday } else { return 0 }
        var count = 0
        while days.contains(cursor) {
            count += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return count
    }

    /// Length of the streak that just ended, if the last completion was before yesterday. Zero otherwise.
    static func brokenLength(completions: [Date], now: Date = .now, calendar: Calendar = .current) -> Int {
        guard let last = completions.max() else { return 0 }
        let today = calendar.startOfDay(for: now)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }
        guard calendar.startOfDay(for: last) < yesterday else { return 0 }
        return current(completions: completions, now: last, calendar: calendar)
    }
}
