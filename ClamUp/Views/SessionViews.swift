import SwiftUI

/// What shows while the phone is shut. Kept dark and calm, since this is usually the cover display or always-on.
struct CoverSessionView: View {
    @Environment(SessionController.self) private var session
    @AppStorage(Prefs.skin) private var skinRaw = OysterSkin.classic.rawValue

    var body: some View {
        ZStack {
            Theme.abyss.ignoresSafeArea()
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let done = session.isDone(at: context.date)
                VStack(spacing: 24) {
                    Spacer(minLength: 0)
                    OysterView(openAmount: 0, mood: done ? .content : .sleepy, skin: OysterSkin(rawValue: skinRaw) ?? .classic)
                        .frame(maxWidth: 220)
                        .opacity(0.9)
                    SessionClock(large: true)
                    Text(done ? session.readyLine : session.coverLine)
                        .font(Theme.voice(19))
                        .foregroundStyle(Theme.mist)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .id(done)
                    if let task = session.active?.taskName, !task.isEmpty {
                        Text(task)
                            .font(Theme.ui(14, .medium))
                            .foregroundStyle(Theme.mist.opacity(0.7))
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Theme.card, in: .capsule)
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
    @AppStorage(Prefs.skin) private var skinRaw = OysterSkin.classic.rawValue

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.25, green: 0.06, blue: 0.08), Theme.abyss], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            TimelineView(.periodic(from: .now, by: 0.25)) { context in
                let left = max(0, (session.pryDeadline ?? context.date).timeIntervalSince(context.date))
                VStack(spacing: 22) {
                    Spacer(minLength: 0)
                    Text(session.pryLine)
                        .font(Theme.voice(26))
                        .foregroundStyle(Theme.foam)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                    OysterView(openAmount: 0.3, mood: .alarmed, skin: OysterSkin(rawValue: skinRaw) ?? .classic, breathing: false)
                        .frame(maxWidth: 240)
                    Text("\(Int(left.rounded(.up)))")
                        .font(.system(size: 88, weight: .bold, design: .rounded))
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
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 24)
            }
        }
    }
}
