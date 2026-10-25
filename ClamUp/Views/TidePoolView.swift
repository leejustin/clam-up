import SwiftUI
import SwiftData

struct TidePoolView: View {
    @Query(sort: \Catch.endDate, order: .reverse) private var catches: [Catch]
    @AppStorage(Prefs.skin) private var skinRaw = OysterSkin.classic.rawValue
    @State private var section: Section = .treasures
    @State private var selected: Item?
    @State private var selectedPearl: Catch?

    enum Section: String, CaseIterable, Identifiable {
        case treasures = "Treasures", pearls = "Pearls", sets = "Sets"
        var id: String { rawValue }
    }

    var body: some View {
        let counts = catches.itemCounts
        NavigationStack {
            ZStack {
                OceanBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        summary(counts)
                        Picker("Section", selection: $section) {
                            ForEach(Section.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)

                        switch section {
                        case .treasures: treasures(counts)
                        case .pearls: pearls
                        case .sets: sets(counts)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: 900)
                    .frame(maxWidth: .infinity)
                }
            }
            #if DEBUG
            .onAppear {
                let args = ProcessInfo.processInfo.arguments
                if let i = args.firstIndex(of: "-poolSection"), i + 1 < args.count, let s = Section(rawValue: args[i + 1]) { section = s }
            }
            #endif
            .navigationTitle("Tide pool")
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(item: $selected) { item in
                ItemDetailView(item: item)
                    .presentationDetents([.medium, .large])
            }
            .sheet(item: $selectedPearl) { record in
                PearlDetailView(record: record)
                    .presentationDetents([.medium])
            }
        }
    }

    private func summary(_ counts: [String: Int]) -> some View {
        let found = Catalog.all.filter { counts[$0.id, default: 0] > 0 }.count
        let caps = counts["bottlecap", default: 0]
        return Text(caps > 0
            ? "\(found) of \(Catalog.all.count) things found. Also \(caps) bottle cap\(caps == 1 ? "" : "s"), for some reason."
            : "\(found) of \(Catalog.all.count) things found. The pool is looking a little empty.")
            .font(Theme.voice(17))
            .foregroundStyle(Theme.mist)
    }

    // MARK: Treasures

    private func treasures(_ counts: [String: Int]) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach([Rarity.legendary, .rare, .uncommon, .common, .regret], id: \.self) { rarity in
                VStack(alignment: .leading, spacing: 12) {
                    Text(rarity.label)
                        .font(Theme.ui(15, .semibold))
                        .foregroundStyle(Theme.rarityColor(rarity))
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 12)], spacing: 12) {
                        ForEach(Catalog.items(of: rarity)) { item in
                            let count = counts[item.id, default: 0]
                            Button {
                                if count > 0 { selected = item }
                            } label: {
                                ItemCell(item: item, count: count)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: Pearls

    @ViewBuilder
    private var pearls: some View {
        let pearled = catches.filter { $0.pearl != nil }
        if pearled.isEmpty {
            EmptyNote(text: "No pearls yet. The oyster is waiting. Patiently. It has no other option.")
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                ForEach(pearled) { record in
                    Button { selectedPearl = record } label: {
                        VStack(spacing: 8) {
                            if let pearl = record.pearl {
                                PearlView(spec: pearl, diameter: 26 + 34 * pearl.size)
                                    .frame(height: 64)
                            }
                            Text(record.taskName.isEmpty ? (record.pearl?.grade.name ?? "") : record.taskName)
                                .font(Theme.ui(13, .medium))
                                .foregroundStyle(Theme.foam)
                                .lineLimit(1)
                            Text(record.endDate.formatted(.dateTime.month(.abbreviated).day()))
                                .font(Theme.ui(11))
                                .foregroundStyle(Theme.mist)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .card(radius: 16)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Sets

    private func sets(_ counts: [String: Int]) -> some View {
        let unlocked = catches.unlockedSkins
        return VStack(spacing: 14) {
            wardrobe(unlocked)
            ForEach(CollectionSet.allCases, id: \.self) { set in
                let have = set.items.filter { counts[$0.id, default: 0] > 0 }.count
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(set.name)
                            .font(Theme.ui(18, .semibold))
                            .foregroundStyle(Theme.foam)
                        Spacer()
                        Text("\(have) of \(set.items.count)")
                            .font(Theme.ui(14, .medium))
                            .foregroundStyle(have == set.items.count ? Theme.sand : Theme.mist)
                    }
                    Text(set.blurb)
                        .font(Theme.voice(15))
                        .foregroundStyle(Theme.mist)
                    HStack(spacing: 6) {
                        ForEach(set.items) { item in
                            ItemArtView(item: item, size: 44, silhouette: counts[item.id, default: 0] == 0)
                        }
                    }
                    Text(have == set.items.count ? "Unlocked: \(set.skin.name)" : "Finish it to unlock: \(set.skin.name)")
                        .font(Theme.ui(12, .medium))
                        .foregroundStyle(have == set.items.count ? Theme.sand : Theme.mist.opacity(0.7))
                }
                .padding(16)
                .card()
            }
        }
    }

    private func wardrobe(_ unlocked: Set<OysterSkin>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Wardrobe")
                .font(Theme.ui(18, .semibold))
                .foregroundStyle(Theme.foam)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(OysterSkin.allCases) { skin in
                        let isOn = unlocked.contains(skin)
                        let wearing = skin.rawValue == skinRaw
                        Button {
                            if isOn { skinRaw = skin.rawValue }
                        } label: {
                            VStack(spacing: 6) {
                                OysterView(skin: skin, breathing: false)
                                    .frame(width: 72)
                                    .opacity(isOn ? 1 : 0.25)
                                    .overlay { if !isOn { Image(systemName: "lock.fill").foregroundStyle(Theme.mist) } }
                                Text(skin.name)
                                    .font(Theme.ui(11, .medium))
                                    .foregroundStyle(wearing ? Theme.sand : Theme.mist)
                                    .lineLimit(1)
                            }
                            .frame(width: 92)
                            .padding(.vertical, 8)
                            .background(wearing ? Theme.sand.opacity(0.12) : .clear, in: .rect(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(isOn ? (wearing ? "\(skin.name), wearing" : skin.name) : "\(skin.name), locked")
                    }
                }
            }
        }
        .padding(16)
        .card()
    }
}

struct ItemCell: View {
    let item: Item
    let count: Int

    var body: some View {
        VStack(spacing: 6) {
            ItemArtView(item: item, size: 50, silhouette: count == 0)
                .frame(width: 68, height: 68)
                .background(SpecimenDish(rarity: item.rarity, lit: count > 0))
            Text(count > 0 ? item.name : "???")
                .font(Theme.ui(12, .medium))
                .foregroundStyle(count > 0 ? Theme.foam : Theme.mist.opacity(0.6))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .overlay(alignment: .topTrailing) {
            if count > 1 {
                Text("×\(count)")
                    .font(Theme.ui(11, .bold))
                    .foregroundStyle(Theme.abyss)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Theme.rarityColor(item.rarity), in: .capsule)
                    .offset(x: 4, y: -4)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity)
        .card(radius: 16)
    }
}

struct EmptyNote: View {
    let text: String
    var body: some View {
        Text(text)
            .font(Theme.voice(18))
            .foregroundStyle(Theme.mist)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
    }
}

struct ItemDetailView: View {
    let item: Item
    @Query(sort: \Catch.endDate) private var catches: [Catch]
    @State private var line = ""

    var body: some View {
        let finds = catches.filter { $0.itemIDs.contains(item.id) }
        ZStack {
            OceanBackground()
            ScrollView {
                VStack(spacing: 16) {
                    ItemArtView(item: item, size: 140)
                        .padding(.top, 28)
                    Text(item.name)
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundStyle(Theme.foam)
                    Text(item.rarity.label + (item.set.map { " · \($0.name)" } ?? ""))
                        .font(Theme.ui(14, .semibold))
                        .foregroundStyle(Theme.rarityColor(item.rarity))
                    Text(line)
                        .font(Theme.voice(19))
                        .foregroundStyle(Theme.foam)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    if let first = finds.first {
                        Text(firstFound(first, total: finds.count))
                            .font(Theme.ui(14))
                            .foregroundStyle(Theme.mist)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            line = LineEngine.shared.itemLine(item, count: finds.count, pastTasks: catches.map(\.taskName))
        }
    }

    private func firstFound(_ c: Catch, total: Int) -> String {
        let date = c.endDate.formatted(.dateTime.month(.wide).day())
        let task = c.taskName.isEmpty ? "" : " while you worked on \"\(c.taskName)\""
        let times = total > 1 ? " Found \(total) times so far." : ""
        return "First found \(date)\(task).\(times)"
    }
}

struct PearlDetailView: View {
    let record: Catch

    var body: some View {
        ZStack {
            OceanBackground()
            VStack(spacing: 14) {
                if let pearl = record.pearl {
                    PearlView(spec: pearl, diameter: 80 + 80 * pearl.size)
                        .padding(.top, 30)
                    Text(pearl.title)
                        .font(.system(size: 26, weight: .bold, design: .serif))
                        .foregroundStyle(Theme.foam)
                }
                Text("\(record.focusedMinutes) min" + (record.taskName.isEmpty ? "" : " · \(record.taskName)"))
                    .font(Theme.ui(15))
                    .foregroundStyle(Theme.mist)
                Text(record.endDate.formatted(date: .abbreviated, time: .shortened))
                    .font(Theme.ui(13))
                    .foregroundStyle(Theme.mist.opacity(0.8))
                if !record.line.isEmpty {
                    Text(record.line)
                        .font(Theme.voice(18))
                        .foregroundStyle(Theme.foam)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }
                Spacer()
            }
        }
    }
}
