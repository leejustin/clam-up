import Foundation
import SwiftData

/// One focus session and everything the oyster gave you for it.
@Model
final class Catch {
    var id: UUID = UUID()
    var startDate: Date = Date.now
    var endDate: Date = Date.now
    var plannedSeconds: Int = 0
    var focusedSeconds: Int = 0
    var taskName: String = ""
    var completed: Bool = false
    var pearlSize: Double = 0
    var pearlColorRaw: String = PearlColor.white.rawValue
    var pearlHueJitter: Double = 0
    var pearlGradeRaw: String = PearlGrade.seed.rawValue
    var itemIDs: [String] = []
    var line: String = ""
    var lineImprovised: Bool = false

    init(startDate: Date, endDate: Date, plannedSeconds: Int, focusedSeconds: Int, taskName: String,
         completed: Bool, pearl: PearlSpec?, itemIDs: [String], line: String) {
        self.startDate = startDate
        self.endDate = endDate
        self.plannedSeconds = plannedSeconds
        self.focusedSeconds = focusedSeconds
        self.taskName = taskName
        self.completed = completed
        self.itemIDs = itemIDs
        self.line = line
        if let pearl {
            pearlSize = pearl.size
            pearlColorRaw = pearl.color.rawValue
            pearlHueJitter = pearl.hueJitter
            pearlGradeRaw = pearl.grade.rawValue
        }
    }

    var pearl: PearlSpec? {
        guard completed, pearlSize > 0 else { return nil }
        return PearlSpec(
            size: pearlSize,
            color: PearlColor(rawValue: pearlColorRaw) ?? .white,
            hueJitter: pearlHueJitter,
            grade: PearlGrade(rawValue: pearlGradeRaw) ?? .seed
        )
    }

    var items: [Item] { itemIDs.compactMap { Catalog.item($0) } }

    var focusedMinutes: Int { focusedSeconds / 60 }
}

extension Array where Element == Catch {
    var itemCounts: [String: Int] {
        var counts: [String: Int] = [:]
        for c in self { for id in c.itemIDs { counts[id, default: 0] += 1 } }
        return counts
    }

    var completions: [Date] { filter(\.completed).map(\.endDate) }

    var unlockedSkins: Set<OysterSkin> {
        let counts = itemCounts
        var skins: Set<OysterSkin> = [.classic]
        for set in CollectionSet.allCases where set.items.allSatisfy({ counts[$0.id, default: 0] > 0 }) {
            skins.insert(set.skin)
        }
        return skins
    }
}
