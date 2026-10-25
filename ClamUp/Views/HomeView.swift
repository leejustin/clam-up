import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(SessionController.self) private var session
    @AppStorage(Prefs.skin) private var skinRaw = OysterSkin.classic.rawValue
    @AppStorage(Prefs.lastDuration) private var duration = 25 * 60
    @Query(sort: \Catch.endDate, order: .reverse) private var catches: [Catch]
    @State private var task = ""
    @FocusState private var taskFocused: Bool

    private var skin: OysterSkin { OysterSkin(rawValue: skinRaw) ?? .classic }
    private var streak: Int { Streak.current(completions: catches.completions) }

    var body: some View {
        GeometryReader { geo in
            // The Duo's inner display is nearly square. Use two columns when there's room.
            let wide = geo.size.width > 600 && geo.size.width > geo.size.height * 0.85
            ZStack {
                OceanBackground()
                if wide {
                    HStack(spacing: 40) {
                        VStack(spacing: 24) {
                            header
                            oyster
                        }
                        .frame(maxWidth: .infinity)
                        controls
                            .frame(maxWidth: 420)
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 24)
                } else {
                    ScrollView {
                        VStack(spacing: 22) {
                            header
                            oyster
                                .frame(maxWidth: 320)
                            controls
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
        }
        .onTapGesture { taskFocused = false }
    }

    // MARK: Pieces

    private var header: some View {
        HStack {
            Text("Clam Up")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(Theme.foam)
            Spacer()
            if streak > 0 {
                Label("\(streak) day\(streak == 1 ? "" : "s")", systemImage: "flame.fill")
                    .font(Theme.ui(14, .semibold))
                    .foregroundStyle(Theme.sand)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Theme.card, in: .capsule)
            }
            Label("\(catches.filter(\.completed).count)", systemImage: "circle.fill")
                .font(Theme.ui(14, .semibold))
                .foregroundStyle(Theme.foam)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Theme.card, in: .capsule)
                .accessibilityLabel("\(catches.filter(\.completed).count) pearls")
        }
    }

    private var bubbleLine: String {
        switch session.phase {
        case .armed: session.armedLine
        case .growing: session.isDone() ? session.readyLine : session.coverLine
        default: session.idleLine
        }
    }

    private var oyster: some View {
        VStack(spacing: 18) {
            Text(bubbleLine)
                .font(Theme.voice(20))
                .foregroundStyle(Theme.foam)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 18).padding(.vertical, 14)
                .card(radius: 22)
                .id(bubbleLine)
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            OysterView(openAmount: 0, mood: session.phase == .idle ? .content : .sleepy, skin: skin)
        }
        .animation(.easeInOut(duration: 0.3), value: bubbleLine)
    }

    @ViewBuilder
    private var controls: some View {
        switch session.phase {
        case .armed: armedControls
        case .growing: growingControls
        default: idleControls
        }
    }

    private var idleControls: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What are you working on?")
                    .font(Theme.ui(15, .medium))
                    .foregroundStyle(Theme.mist)
                TextField("", text: $task, prompt: Text("Optional. The pearl gets named after it.").foregroundStyle(Theme.mist.opacity(0.5)))
                    .font(Theme.ui(18))
                    .foregroundStyle(Theme.foam)
                    .focused($taskFocused)
                    .submitLabel(.done)
                    .padding(14)
                    .card(radius: 14)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("How long?")
                    .font(Theme.ui(15, .medium))
                    .foregroundStyle(Theme.mist)
                DurationPicker(seconds: $duration)
            }
            Button("Get ready") {
                taskFocused = false
                session.arm(task: task, seconds: duration)
                task = ""
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.top, 4)
            Text(rewardHint)
                .font(Theme.ui(13))
                .foregroundStyle(Theme.mist.opacity(0.8))
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
        }
    }

    private var rewardHint: String {
        let minutes = Double(duration) / 60
        let rolls = RewardEngine.rolls(forMinutes: minutes)
        let grade = PearlGrade.forMinutes(minutes).name.lowercased()
        return "A \(grade), plus \(rolls) chance\(rolls == 1 ? "" : "s") at something else."
    }

    private var armedControls: some View {
        VStack(spacing: 18) {
            if session.usesHinge {
                VStack(spacing: 10) {
                    Image(systemName: "arrow.down.and.line.horizontal.and.arrow.up")
                        .font(.system(size: 34, weight: .medium))
                        .foregroundStyle(Theme.sand)
                        .symbolEffect(.pulse)
                    Text("Close the phone to start")
                        .font(Theme.ui(22, .semibold))
                        .foregroundStyle(Theme.foam)
                    Text("The pearl only grows while the shell is shut.")
                        .font(Theme.ui(15))
                        .foregroundStyle(Theme.mist)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .card()
            } else {
                Button("Clam up") { session.close() }
                    .buttonStyle(PrimaryButtonStyle())
                Text("No hinge on this phone. Tap to shut the shell, then leave it alone.")
                    .font(Theme.ui(14))
                    .foregroundStyle(Theme.mist)
                    .multilineTextAlignment(.center)
            }
            if let active = session.active {
                Text(summary(active))
                    .font(Theme.ui(14))
                    .foregroundStyle(Theme.mist)
            }
            Button("Never mind") { session.cancelArm() }
                .buttonStyle(QuietButtonStyle())
            #if DEBUG
            DebugFoldButton(closed: true)
            #endif
        }
    }

    private var growingControls: some View {
        VStack(spacing: 18) {
            SessionClock()
            if session.isDone() {
                Button("Open the shell") { session.open() }
                    .buttonStyle(PrimaryButtonStyle())
            } else {
                Button("Pry it open early") { session.open() }
                    .buttonStyle(QuietButtonStyle())
            }
        }
    }

    private func summary(_ s: ActiveSession) -> String {
        let minutes = DurationPicker.label(s.plannedSeconds)
        return s.taskName.isEmpty ? minutes : "\(minutes) on \"\(s.taskName)\""
    }
}

struct DurationPicker: View {
    @Binding var seconds: Int

    static var options: [Int] {
        var base = [10, 25, 45, 60, 90, 120].map { $0 * 60 }
        #if DEBUG
        base.insert(contentsOf: [10, 60], at: 0)
        #endif
        return base
    }

    static func label(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds) sec" }
        let m = seconds / 60
        return m >= 60 && m % 60 == 0 ? "\(m / 60) hr" : "\(m) min"
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 8)], spacing: 8) {
            ForEach(Self.options, id: \.self) { option in
                let selected = option == seconds
                Button {
                    seconds = option
                } label: {
                    Text(Self.label(option))
                        .font(Theme.ui(16, selected ? .semibold : .regular))
                        .foregroundStyle(selected ? Theme.abyss : Theme.foam)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selected ? Theme.sand : Theme.card, in: .capsule)
                        .overlay(Capsule().strokeBorder(selected ? .clear : Theme.cardStroke))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .sensoryFeedback(.selection, trigger: seconds)
    }
}

/// Counts down to the pearl. Shared by the home screen and the cover display.
struct SessionClock: View {
    @Environment(SessionController.self) private var session
    var large = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let planned = Double(session.active?.plannedSeconds ?? 0)
            let remaining = max(0, planned - session.elapsed(at: context.date))
            VStack(spacing: 10) {
                Text(remaining > 0 ? Self.format(remaining) : "Ready")
                    .font(.system(size: large ? 64 : 48, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Theme.foam)
                    .contentTransition(.numericText(countsDown: true))
                ProgressView(value: session.progress(at: context.date))
                    .tint(Theme.sand)
                    .frame(maxWidth: 260)
                Text("of \(DurationPicker.label(Int(planned)))")
                    .font(Theme.ui(14))
                    .foregroundStyle(Theme.mist)
            }
        }
    }

    static func format(_ seconds: Double) -> String {
        let s = Int(seconds.rounded(.up))
        let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, sec) : String(format: "%d:%02d", m, sec)
    }
}

#if DEBUG
/// Simulates folding in the simulator, where there's no hinge to close.
struct DebugFoldButton: View {
    @Environment(SessionController.self) private var session
    var closed: Bool

    var body: some View {
        Button {
            session.debugSetFold(closed: closed)
        } label: {
            Label(closed ? "Debug: close the shell" : "Debug: open the shell", systemImage: "ladybug")
                .font(Theme.ui(13, .medium))
                .foregroundStyle(.orange)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(.orange.opacity(0.12), in: .capsule)
        }
        .buttonStyle(.plain)
    }
}
#endif
