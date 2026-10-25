import SwiftUI

/// What shows while the phone is shut. Kept dark and calm, since this is usually the cover display or always-on.
struct CoverSessionView: View {
    @Environment(SessionController.self) private var session

    var body: some View {
        ZStack {
            ShellExterior()
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let done = session.isDone(at: context.date)
                VStack(spacing: 24) {
                    Spacer(minLength: 0)
                    OysterEyes(mood: done ? .content : .sleepy, size: 46, lidColor: Color(red: 0.32, green: 0.28, blue: 0.27))
                    SessionClock(large: true)
                    Text(done ? session.readyLine : session.coverLine)
                        .font(Theme.voice(19))
                        .foregroundStyle(Theme.foam.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .id(done)
                    if let task = session.active?.taskName, !task.isEmpty {
                        Text(task)
                            .font(Theme.ui(14, .medium))
                            .foregroundStyle(Theme.foam.opacity(0.75))
                            .pill()
                    }
                    Spacer(minLength: 0)
                    #if DEBUG
                    DebugFoldButton(closed: false)
                    #endif
                }
                .padding(.vertical, 24)
                .animation(.easeInOut, value: done)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Opened too early. Close it again before the countdown runs out, or the crab gets the pearl.
struct PryingView: View {
    @Environment(SessionController.self) private var session

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.25)) { context in
            let left = max(0, (session.pryDeadline ?? context.date).timeIntervalSince(context.date))
            ClamInterior(openDegrees: session.openDegrees, flush: 1) {
                VStack(spacing: 0) {
                    Spacer(minLength: 8)
                    Text(session.pryLine)
                        .font(Theme.voice(26))
                        .foregroundStyle(Theme.foam)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 480)
                    Spacer(minLength: 8)
                    OysterEyes(mood: .alarmed, size: 36, lidColor: Color(red: 0.30, green: 0.12, blue: 0.15))
                        .padding(.bottom, 12)
                }
                .padding(.horizontal, 28)
            } bowl: {
                VStack(spacing: 14) {
                    PearlView(spec: PearlSpec(size: 0.4, color: .white, hueJitter: 0, grade: .round), diameter: 26)
                        .frame(height: 42)
                    Text("\(Int(left.rounded(.up)))")
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Theme.coral)
                        .contentTransition(.numericText(countsDown: true))
                        .animation(.snappy, value: Int(left.rounded(.up)))
                    Text(session.usesHinge ? "Close the shell to keep your pearl." : "Close it back to keep your pearl.")
                        .font(Theme.ui(17, .medium))
                        .foregroundStyle(Theme.foam.opacity(0.85))
                    Spacer(minLength: 0)
                    VStack(spacing: 12) {
                        if !session.usesHinge {
                            Button("Close it back") { session.close() }
                                .buttonStyle(PrimaryButtonStyle())
                        }
                        #if DEBUG
                        if session.usesHinge { DebugFoldButton(closed: true) }
                        #endif
                        Button("Let the crab have it") { session.giveUp() }
                            .buttonStyle(QuietButtonStyle())
                    }
                    .frame(maxWidth: 420)
                    .padding(.bottom, 12)
                }
                .padding(.horizontal, 24)
            }
        }
    }
}
