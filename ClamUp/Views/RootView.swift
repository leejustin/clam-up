import SwiftUI

struct RootView: View {
    @Environment(SessionController.self) private var session
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(Prefs.haptics) private var haptics = true
    @AppStorage(Prefs.skin) private var skinRaw = OysterSkin.classic.rawValue
    @State private var tab = 0

    var body: some View {
        ZStack {
            TabView(selection: $tab) {
                Tab("Oyster", systemImage: "water.waves", value: 0) { HomeView() }
                Tab("Tide pool", systemImage: "fish", value: 1) { TidePoolView() }
                Tab("Log", systemImage: "calendar", value: 2) { LogView() }
                Tab("Settings", systemImage: "gearshape", value: 3) { SettingsView() }
            }
            .tint(Theme.sand)

            if session.phase == .growing, session.usesHinge {
                CoverSessionView()
                    .transition(.opacity)
                    .zIndex(1)
            }
            if session.phase == .prying {
                PryingView()
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .onHinge { session.hingeChanged($0) }
        #if DEBUG
        .task { await DebugTools.runDemo(session) }
        .onAppear {
            let args = ProcessInfo.processInfo.arguments
            if let i = args.firstIndex(of: "-tab"), i + 1 < args.count, let n = Int(args[i + 1]) { tab = n }
        }
        #endif
        .fullScreenCover(item: Binding(get: { session.reveal }, set: { if $0 == nil { session.dismissReveal() } })) { _ in
            RevealView()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { session.refresh() }
        }
        .onChange(of: session.phase) { _, phase in
            if phase == .armed || phase == .growing { tab = 0 }
        }
        .animation(.easeInOut(duration: 0.35), value: session.phase)
        .environment(\.shellFinish, (OysterSkin(rawValue: skinRaw) ?? .classic).finish)
        .sensoryFeedback(trigger: session.phase) { _, new in
            guard haptics else { return nil }
            switch new {
            case .prying: return .warning
            case .growing: return .impact(weight: .medium)
            default: return nil
            }
        }
    }
}
