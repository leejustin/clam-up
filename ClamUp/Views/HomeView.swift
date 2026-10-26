import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(SessionController.self) private var session
    @AppStorage(Prefs.lastDuration) private var duration = 25 * 60
    @Query(sort: \Catch.endDate, order: .reverse) private var catches: [Catch]
    @State private var task = ""
    @FocusState private var taskFocused: Bool

    private var streak: Int { Streak.current(completions: catches.completions) }

    var body: some View {
        ClamInterior(openDegrees: session.openDegrees) {
            lid
        } bowl: {
            bowl
        }
        .ignoresSafeArea(.keyboard)
        .onTapGesture { taskFocused = false }
    }

    // MARK: Lid

    /// The underside of the lid: the oyster talks from here.
    private var lid: some View {
        VStack(spacing: 0) {
            header
            Spacer(minLength: 8)
            Text(bubbleLine)
                .font(Theme.voice(23))
                .foregroundStyle(Theme.foam)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 480)
                .id(bubbleLine)
                .transition(.opacity.combined(with: .scale(scale: 0.97)))
            if session.phase == .idle {
                taskField
                    .frame(maxWidth: 440)
                    .padding(.top, 18)
            } else if let active = session.active {
                Text(summary(active))
                    .font(Theme.ui(14, .medium))
                    .foregroundStyle(Theme.mist)
                    .padding(.top, 10)
            }
            Spacer(minLength: 8)
        }
        .padding(.horizontal, 24)
        .padding(.top, 4)
        .animation(.easeInOut(duration: 0.3), value: bubbleLine)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("Clam Up")
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundStyle(Theme.foam)
                .lineLimit(1)
                .fixedSize()
            Spacer(minLength: 12)
            if streak > 0 {
                Label("\(streak)", systemImage: "flame.fill")
                    .foregroundStyle(Theme.sand)
                    .pill()
                    .accessibilityLabel("\(streak) day streak")
            }
            HStack(spacing: 6) {
                PearlView(spec: PearlSpec(size: 0.5, color: .white, hueJitter: 0, grade: .round), diameter: 14)
                Text("\(catches.filter(\.completed).count)")
            }
            .foregroundStyle(Theme.foam)
            .pill()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(catches.filter(\.completed).count) pearls")
        }
    }

    private var taskField: some View {
        TextField("", text: $task, prompt: Text("What are you working on?").foregroundStyle(Theme.mist.opacity(0.6)))
            .font(Theme.ui(18))
            .foregroundStyle(Theme.foam)
            .multilineTextAlignment(.center)
            .focused($taskFocused)
            .submitLabel(.done)
            .padding(.horizontal, 16).padding(.vertical, 13)
            .background(Color.black.opacity(0.28), in: .capsule)
            .overlay(Capsule().strokeBorder(Theme.cardStroke))
            .accessibilityLabel("What are you working on? Optional. The pearl gets named after it.")
    }

    private var bubbleLine: String {
        switch session.phase {
        case .armed: session.armedLine
        case .growing: session.isDone() ? session.readyLine : session.coverLine
        default: session.idleLine
        }
    }

    // MARK: Bowl

    /// The bowl: where the pearl grows, right below the hinge, and the controls for growing it.
    private var bowl: some View {
        VStack(spacing: 14) {
            pearlSpot
            Group {
                switch session.phase {
                case .armed: armedControls
                case .growing: growingControls
                default: idleControls
                }
            }
            .frame(maxWidth: 520)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var pearlSpot: some View {
        switch session.phase {
        case .growing:
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let p = session.progress(at: context.date)
                PearlView(spec: PearlSpec(size: p, color: .white, hueJitter: 0, grade: .round), diameter: 14 + 40 * p)
                    .frame(height: 58)
                    .animation(.easeInOut(duration: 1), value: p)
            }
        case .armed:
            SandGrain(size: 14, glow: 1).frame(height: 42)
        default:
            SandGrain(size: 12, glow: 0.35).frame(height: 42)
        }
    }

    private var idleControls: some View {
        VStack(spacing: 14) {
            DurationPicker(seconds: $duration)
                .mask(LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.06),
                                             .init(color: .black, location: 0.94), .init(color: .clear, location: 1)],
                                     startPoint: .leading, endPoint: .trailing))
            Button("Get ready") {
                taskFocused = false
                session.arm(task: task, seconds: duration)
                task = ""
            }
            .buttonStyle(PrimaryButtonStyle())
            Text(rewardHint)
                .font(Theme.ui(13))
                .foregroundStyle(Theme.mist.opacity(0.8))
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
        VStack(spacing: 14) {
            if session.usesHinge {
                VStack(spacing: 6) {
                    Text("Now close the phone")
                        .font(Theme.ui(22, .semibold))
                        .foregroundStyle(Theme.foam)
                    Text("The pearl only grows while the shell is shut.")
                        .font(Theme.ui(15))
                        .foregroundStyle(Theme.mist)
                }
                .multilineTextAlignment(.center)
            } else {
                Button("Clam up") { session.close() }
                    .buttonStyle(PrimaryButtonStyle())
                Text("No hinge on this phone. Tap to shut the shell, then leave it alone.")
                    .font(Theme.ui(14))
                    .foregroundStyle(Theme.mist)
                    .multilineTextAlignment(.center)
            }
            Button("Never mind") { session.cancelArm() }
                .buttonStyle(QuietButtonStyle())
            #if DEBUG
            DebugFoldButton(closed: true)
            #endif
        }
    }

    private var growingControls: some View {
        VStack(spacing: 14) {
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
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(Self.options, id: \.self) { option in
                let selected = option == seconds
                Button {
                    seconds = option
                } label: {
                    Text(Self.label(option))
                        .font(Theme.ui(16, selected ? .semibold : .regular))
                        .foregroundStyle(selected ? Theme.abyss : Theme.foam)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(selected ? Theme.sand : Color.black.opacity(0.28), in: .capsule)
                        .overlay(Capsule().strokeBorder(selected ? .clear : Theme.cardStroke))
                        .animation(.snappy(duration: 0.2), value: selected)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
          }
          .padding(.horizontal, 2)
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
                PearlTrack(progress: session.progress(at: context.date))
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

/// A thin track with a small pearl riding along the front edge.
struct PearlTrack: View {
    var progress: Double

    var body: some View {
        GeometryReader { geo in
            let p = min(1, max(0, progress))
            let pearl: CGFloat = 16
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.08))
                Capsule()
                    .fill(LinearGradient(colors: [Theme.sand.opacity(0.25), Theme.sand], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(pearl / 2, geo.size.width * p))
                PearlView(spec: PearlSpec(size: 0.5, color: .cream, hueJitter: 0, grade: .round), diameter: pearl)
                    .offset(x: (geo.size.width - pearl) * p)
            }
            .frame(height: 5)
            .frame(maxHeight: .infinity)
        }
        .frame(height: 18)
        .animation(.linear(duration: 1), value: progress)
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(progress * 100)) percent")
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
