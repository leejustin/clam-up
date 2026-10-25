import SwiftUI
import SwiftData

struct LogView: View {
    @Query(sort: \Catch.endDate, order: .reverse) private var catches: [Catch]
    @State private var necklaceImage: Image?

    private var thisWeek: [Catch] {
        guard let week = Calendar.current.dateInterval(of: .weekOfYear, for: .now) else { return [] }
        return catches.filter { week.contains($0.endDate) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                OceanBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        stats
                        necklace
                        history
                    }
                    .padding(20)
                    .frame(maxWidth: 760)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Log")
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    // MARK: Stats

    private var stats: some View {
        let completed = catches.filter(\.completed)
        let minutes = catches.reduce(0) { $0 + $1.focusedSeconds } / 60
        let tiles: [(String, String, String)] = [
            ("flame.fill", "\(Streak.current(completions: catches.completions))", "day streak"),
            ("circle.fill", "\(completed.count)", "pearls"),
            ("clock", minutes >= 120 ? "\(minutes / 60) hr" : "\(minutes) min", "focused"),
            ("hand.raised", "\(catches.count - completed.count)", "opened early"),
        ]
        return LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
            ForEach(tiles, id: \.2) { icon, value, label in
                VStack(alignment: .leading, spacing: 6) {
                    Image(systemName: icon).foregroundStyle(Theme.sand)
                    Text(value)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.foam)
                    Text(label)
                        .font(Theme.ui(13))
                        .foregroundStyle(Theme.mist)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .card(radius: 16)
            }
        }
    }

    // MARK: Necklace

    private var necklace: some View {
        let pearls = thisWeek.reversed().compactMap(\.pearl)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("This week's necklace")
                    .font(Theme.ui(18, .semibold))
                    .foregroundStyle(Theme.foam)
                Spacer()
                if let necklaceImage, !pearls.isEmpty {
                    ShareLink(item: necklaceImage, preview: SharePreview("My week", image: necklaceImage)) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(Theme.sand)
                    }
                    .accessibilityLabel("Share necklace")
                }
            }
            NecklaceView(pearls: pearls)
                .frame(height: 130)
            Text(Recap.week(thisWeek))
                .font(Theme.voice(16))
                .foregroundStyle(Theme.mist)
            if !pearls.isEmpty {
                Text("Wear your productivity. Metaphorically. Please don't actually wear this.")
                    .font(Theme.ui(12))
                    .foregroundStyle(Theme.mist.opacity(0.6))
            }
        }
        .padding(16)
        .card()
        .task(id: pearls.count) {
            let card = NecklaceShareCard(pearls: pearls, recap: Recap.week(thisWeek))
            let renderer = ImageRenderer(content: card)
            renderer.scale = 3
            necklaceImage = renderer.uiImage.map { Image(uiImage: $0) }
        }
    }

    // MARK: History

    @ViewBuilder
    private var history: some View {
        Text("Every session")
            .font(Theme.ui(18, .semibold))
            .foregroundStyle(Theme.foam)
        if catches.isEmpty {
            EmptyNote(text: "Nothing here yet. The oyster keeps very good records, of nothing so far.")
        } else {
            LazyVStack(spacing: 10) {
                ForEach(catches) { record in
                    HistoryRow(record: record)
                }
            }
        }
    }
}

struct HistoryRow: View {
    let record: Catch

    var body: some View {
        HStack(spacing: 14) {
            Group {
                if let pearl = record.pearl {
                    PearlView(spec: pearl, diameter: 20 + 18 * pearl.size)
                } else if let regret = record.items.first {
                    ItemArtView(item: regret, size: 40)
                }
            }
            .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text(record.taskName.isEmpty ? (record.pearl?.title ?? "Opened early") : record.taskName)
                    .font(Theme.ui(16, .semibold))
                    .foregroundStyle(Theme.foam)
                    .lineLimit(1)
                Text("\(record.endDate.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute())) · \(record.focusedMinutes) min")
                    .font(Theme.ui(12))
                    .foregroundStyle(Theme.mist)
                if !record.line.isEmpty {
                    Text(record.line)
                        .font(Theme.voice(13))
                        .foregroundStyle(Theme.mist.opacity(0.85))
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 0)
            HStack(spacing: -6) {
                ForEach(Array(record.items.filter { $0.rarity != .regret }.prefix(3).enumerated()), id: \.offset) { _, item in
                    ItemArtView(item: item, size: 26)
                }
            }
        }
        .padding(12)
        .card(radius: 16)
    }
}

/// Pearls strung along a drooping curve.
struct NecklaceView: View {
    let pearls: [PearlSpec]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let point = { (t: CGFloat) -> CGPoint in
                CGPoint(x: w * (0.04 + 0.92 * t), y: h * 0.18 + h * 0.62 * (1 - pow(2 * t - 1, 2)))
            }
            ZStack {
                Path { p in
                    p.move(to: point(0))
                    for i in 1...40 { p.addLine(to: point(CGFloat(i) / 40)) }
                }
                .stroke(Theme.sand.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))

                if pearls.isEmpty {
                    Text("No pearls yet this week.")
                        .font(Theme.voice(15))
                        .foregroundStyle(Theme.mist.opacity(0.7))
                        .position(x: w / 2, y: h * 0.45)
                } else {
                    let shown = Array(pearls.prefix(14))
                    ForEach(Array(shown.enumerated()), id: \.offset) { i, pearl in
                        let t = shown.count == 1 ? 0.5 : 0.12 + 0.76 * CGFloat(i) / CGFloat(shown.count - 1)
                        PearlView(spec: pearl, diameter: 16 + 18 * pearl.size)
                            .position(point(t))
                    }
                }
            }
        }
        .accessibilityLabel("\(pearls.count) pearls this week")
    }
}

struct NecklaceShareCard: View {
    let pearls: [PearlSpec]
    let recap: String

    var body: some View {
        VStack(spacing: 16) {
            Text("My week in pearls")
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundStyle(Theme.foam)
            NecklaceView(pearls: pearls).frame(height: 140)
            Text(recap)
                .font(Theme.voice(17))
                .foregroundStyle(Theme.foam.opacity(0.9))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text("Clam Up")
                .font(Theme.ui(13, .semibold))
                .foregroundStyle(Theme.mist)
        }
        .padding(28)
        .frame(width: 380)
        .background(LinearGradient(colors: [Theme.abyss, Theme.sea], startPoint: .top, endPoint: .bottom))
    }
}
