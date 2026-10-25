import Foundation

enum PearlColor: String, Codable, CaseIterable {
    case white, cream, rose, silver, gold, black

    var name: String {
        switch self {
        case .white: "White"
        case .cream: "Cream"
        case .rose: "Rosé"
        case .silver: "Silver"
        case .gold: "Golden"
        case .black: "Black"
        }
    }

    /// Streak days needed before this color shows up.
    static func forStreak(_ days: Int) -> PearlColor {
        switch days {
        case ..<2: .white
        case 2: .cream
        case 3...4: .rose
        case 5...6: .silver
        case 7...13: .gold
        default: .black
        }
    }
}

enum PearlGrade: String, Codable, CaseIterable {
    case seed, button, round, bigRound, whopper

    var name: String {
        switch self {
        case .seed: "Seed pearl"
        case .button: "Button pearl"
        case .round: "Round pearl"
        case .bigRound: "Big round pearl"
        case .whopper: "Whopper"
        }
    }

    static func forMinutes(_ minutes: Double) -> PearlGrade {
        switch minutes {
        case ..<15: .seed
        case ..<30: .button
        case ..<60: .round
        case ..<90: .bigRound
        default: .whopper
        }
    }
}

struct PearlSpec: Codable, Equatable, Hashable {
    var size: Double          // 0...1, drives the drawn diameter
    var color: PearlColor
    var hueJitter: Double     // small per-pearl variation, -1...1
    var grade: PearlGrade

    var title: String {
        color == .white ? grade.name : "\(color.name) \(grade.name.lowercased())"
    }

    /// Bigger with time, with diminishing returns so a three hour session isn't a beach ball.
    static func size(forMinutes minutes: Double) -> Double {
        min(1, 0.3 + 0.7 * (max(0, minutes) / 120).squareRoot())
    }
}
