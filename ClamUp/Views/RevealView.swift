import SwiftUI

/// The payoff. Shell opens, pearl appears, the oyster says something, then any extras come out one at a time.
struct RevealView: View {
    @Environment(SessionController.self) private var session
    @AppStorage(Prefs.skin) private var skinRaw = OysterSkin.classic.rawValue
    @AppStorage(Prefs.haptics) private var haptics = true

    private enum Stage: Int, Comparable {
        case shut, opening, pearl, line, items, done
        static func < (a: Stage, b: Stage) -> Bool { a.rawValue < b.rawValue }
    }

    @State private var stage: Stage = .shut
    @State private var shownItems = 0
    @State private var shareImage: Image?
    @State private var skipped = false

    var body: some View {
        if let result = session.reveal {
            content(result)
                .task(id: result.id) { await play(result) }
        }
    }

    private func content(_ r: RevealResult) -> some View {
        ClamInterior(openDegrees: stage >= .opening ? 180 : 15, flush: r.completed ? 0 : 0.5) {
            // Lid: what the oyster has to say about it.
            VStack(spacing: 14) {
                Spacer(minLength: 8)
                if stage >= .pearl { headline(r).transition(.opacity.combined(with: .move(edge: .top))) }
                if stage >= .line {
                    VStack(spacing: 8) {
                        Text(session.revealLine)
                            .font(Theme.voice(22))
                            .foregroundStyle(Theme.foam)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: 500)
                        #if DEBUG
                        if session.revealLineImprovised {
                            Text("Improvised on device")
                                .font(Theme.ui(11, .medium))
                                .foregroundStyle(.orange)
                        }
                        #endif
                    }
                    .transition(.opacity)
                }
                Spacer(minLength: 8)
            }
            .padding(.horizontal, 24)
        } bowl: {
            // Bowl: the pearl, right where it grew, then whatever else washed in.
            ScrollView {
                VStack(spacing: 18) {
                    pearlSpot(r)
                    VStack(spacing: 12) {
                        ForEach(Array(r.items.prefix(shownItems))) { item in
                            ItemRevealCard(found: item)
                                .transition(.scale(scale: 0.8).combined(with: .opacity))
                        }
                    }
                    if stage >= .done {
                        if let streak = r.streakLine {
                            Label(streak, systemImage: "flame.fill")
                                .font(Theme.ui(15, .medium))
                                .foregroundStyle(Theme.sand)
                                .multilineTextAlignment(.center)
                        }
                        ForEach(r.unlockedSkins) { skin in
                            unlockBanner(skin)
                        }
                        buttons
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 24)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .scrollEdgeEffectHidden(true, for: .all)
            // Let the pearl's glow spill up toward the hinge instead of stopping at a hard edge.
            .scrollClipDisabled()
            .mask {
                VStack(spacing: 0) {
                    LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom).frame(height: 50)
                    Color.black
                }
                .padding(.top, -50)
            }
        }
        .animation(.easeInOut(duration: 0.9), value: stage >= .opening)
        .contentShape(Rectangle())
        .onTapGesture { if stage < .done { skipped = true } }
        .sensoryFeedback(trigger: stage) { _, new in
            guard haptics else { return nil }
            switch new {
            case .pearl: return r.completed ? .success : .error
            case .opening: return .impact(weight: .light)
            default: return nil
            }
        }
        .sensoryFeedback(trigger: shownItems) { _, _ in haptics ? .impact(weight: .medium) : nil }
    }

    @ViewBuilder
    private func pearlSpot(_ r: RevealResult) -> some View {
        let d: CGFloat = r.pearl.map { 56 + 64 * $0.size } ?? 40
        ZStack {
            if let pearl = r.pearl, stage >= .pearl {
                Circle()
                    .fill(Theme.nacre.opacity(0.35))
                    .frame(width: d * 2.2, height: d * 2.2)
                    .blur(radius: d * 0.5)
                PearlView(spec: pearl, diameter: d)
                    .transition(.scale(scale: 0.2).combined(with: .opacity))
            } else if stage < .pearl {
                SandGrain(size: 14, glow: 0.6)
            } else {
                // Where the pearl would have been.
                Ellipse()
                    .fill(.black.opacity(0.35))
                    .frame(width: 54, height: 18)
                    .blur(radius: 3)
            }
        }
        .frame(height: max(d, 60) + 16)
    }

    private func headline(_ r: RevealResult) -> some View {
        VStack(spacing: 6) {
            Text(r.pearl?.title ?? "No pearl")
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundStyle(r.completed ? Theme.foam : Theme.coral)
            Text(subtitle(r))
                .font(Theme.ui(15))
                .foregroundStyle(Theme.mist)
        }
    }

    private func subtitle(_ r: RevealResult) -> String {
        let time = r.minutes < 1 ? "Under a minute" : "\(r.minutes) min"
        return r.taskName.isEmpty ? time : "\(time) · \(r.taskName)"
    }

    private func unlockBanner(_ skin: OysterSkin) -> some View {
        HStack(spacing: 14) {
            ShellSwatch(skin: skin).frame(width: 64)
            VStack(alignment: .leading, spacing: 4) {
                Text("Set complete")
                    .font(Theme.ui(13, .semibold))
                    .foregroundStyle(Theme.sand)
                Text("New shell: \(skin.name)")
                    .font(Theme.ui(17, .semibold))
                    .foregroundStyle(Theme.foam)
            }
            Spacer()
            Button("Use it") { skinRaw = skin.rawValue }
                .font(Theme.ui(15, .semibold))
                .foregroundStyle(Theme.abyss)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(Theme.sand, in: .capsule)
        }
        .padding(14)
        .card()
    }

    private var buttons: some View {
        HStack(spacing: 12) {
            if let shareImage {
                ShareLink(item: shareImage, preview: SharePreview("My catch", image: shareImage)) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(QuietButtonStyle())
            }
            Button("Done") { session.dismissReveal() }
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.top, 8)
    }

    // MARK: Sequence

    private func pause(_ seconds: Double) async {
        guard !skipped else { return }
        let steps = Int(seconds * 20)
        for _ in 0..<max(1, steps) {
            if skipped { return }
            try? await Task.sleep(for: .milliseconds(50))
        }
    }

    private func play(_ r: RevealResult) async {
        await pause(0.5)
        withAnimation { stage = .opening }
        await pause(0.8)
        withAnimation(.spring(duration: 0.6, bounce: 0.4)) { stage = .pearl }
        await pause(0.9)
        // Give an improvised line a moment to land. Fall back to the handwritten one if it's slow.
        var waited = 0.0
        while session.isImprovising, waited < 2.5, !skipped {
            try? await Task.sleep(for: .milliseconds(100))
            waited += 0.1
        }
        session.markRevealLineShown()
        withAnimation(.easeOut(duration: 0.5)) { stage = .line }
        await pause(0.9)
        withAnimation { stage = .items }
        for _ in r.items {
            await pause(0.7)
            withAnimation(.spring(duration: 0.5, bounce: 0.35)) { shownItems += 1 }
        }
        await pause(0.4)
        withAnimation { stage = .done }
        shareImage = renderShareImage(r)
    }

    private func renderShareImage(_ r: RevealResult) -> Image? {
        let card = ShareCard(result: r, line: session.revealLine, skin: OysterSkin(rawValue: skinRaw) ?? .classic)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        return renderer.uiImage.map { Image(uiImage: $0) }
    }
}

struct ItemRevealCard: View {
    let found: RevealedItem

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ItemArtView(item: found.item, size: 52)
                .frame(width: 70, height: 70)
                .background(SpecimenDish(rarity: found.item.rarity))
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(found.item.name)
                        .font(Theme.ui(18, .semibold))
                        .foregroundStyle(Theme.foam)
                    if found.isNew {
                        Text("NEW")
                            .font(Theme.ui(11, .bold))
                            .foregroundStyle(Theme.abyss)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Theme.sand, in: .capsule)
                    }
                    Spacer(minLength: 0)
                    Text(found.item.rarity.label)
                        .font(Theme.ui(12, .semibold))
                        .foregroundStyle(Theme.rarityColor(found.item.rarity))
                }
                Text(found.line)
                    .font(Theme.voice(16))
                    .foregroundStyle(Theme.mist)
                    .fixedSize(horizontal: false, vertical: true)
                if let progress = found.setProgress {
                    Text(progress.isComplete ? "\(progress.set.name) complete" : "\(progress.set.name): \(progress.have) of \(progress.total)")
                        .font(Theme.ui(12, .medium))
                        .foregroundStyle(progress.isComplete ? Theme.sand : Theme.mist.opacity(0.8))
                }
            }
        }
        .padding(14)
        .card()
    }
}

/// The image people share. Fixed size so it looks the same everywhere.
struct ShareCard: View {
    let result: RevealResult
    let line: String
    let skin: OysterSkin

    var body: some View {
        VStack(spacing: 18) {
            OpenOyster(pearl: result.pearl, width: 200)
                .padding(.top, 24)
            Text(result.pearl?.title ?? "No pearl")
                .font(.system(size: 26, weight: .bold, design: .serif))
                .foregroundStyle(Theme.foam)
            Text(line)
                .font(Theme.voice(19))
                .foregroundStyle(Theme.foam.opacity(0.9))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if !result.items.isEmpty {
                HStack(spacing: 10) {
                    ForEach(result.items) { ItemArtView(item: $0.item, size: 44) }
                }
            }
            Text("Clam Up")
                .font(Theme.ui(13, .semibold))
                .foregroundStyle(Theme.mist)
        }
        .padding(32)
        .frame(width: 360)
        .background(RadialGradient(colors: [Color(red: 0.06, green: 0.13, blue: 0.17), Shell.seabed], center: .top, startRadius: 0, endRadius: 600))
        .environment(\.shellFinish, skin.finish)
    }
}
