import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage(Prefs.improvise) private var improvise = true
    @AppStorage(Prefs.notifications) private var notifications = true
    @AppStorage(Prefs.haptics) private var haptics = true
    @Environment(\.modelContext) private var context
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            ZStack {
                OceanBackground()
                Form {
                    Section {
                        Toggle("Let the oyster improvise", isOn: $improvise)
                        statusRow
                    } header: {
                        Text("The oyster")
                    } footer: {
                        Text("Now and then the oyster writes a line on the spot with Apple Intelligence. It runs on this phone. Nothing leaves it. If the line sounds off, the oyster uses one of its usual ones instead.")
                    }

                    Section("Sessions") {
                        Toggle("Tell me when the pearl is ready", isOn: $notifications)
                        Toggle("Haptics", isOn: $haptics)
                    }

                    Section {
                        LabeledContent("Price", value: "Paid once")
                        LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    } header: {
                        Text("About")
                    } footer: {
                        Text("No subscription. The oyster doesn't need your money every month. It doesn't need money at all. It's an oyster.")
                    }

                    #if DEBUG
                    Section("Debug") {
                        NavigationLink("Oyster lab") { OysterLabView() }
                        Button("Add sample sessions") { DebugTools.seed(context) }
                        Button("Reset line rotation") { ShuffleBagStore.shared.reset() }
                        Button("Erase everything", role: .destructive) { confirmReset = true }
                    }
                    #endif
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .toolbarBackground(.hidden, for: .navigationBar)
            #if DEBUG
            .confirmationDialog("Erase every session and item?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Erase everything", role: .destructive) { DebugTools.erase(context) }
            }
            #endif
        }
    }

    @ViewBuilder
    private var statusRow: some View {
        switch OysterImproviser.status {
        case .available:
            Label("Apple Intelligence is ready", systemImage: "checkmark.circle")
                .foregroundStyle(Theme.kelp)
        case .unavailable(let reason):
            Label(reason, systemImage: "exclamationmark.circle")
                .foregroundStyle(Theme.mist)
        }
    }
}
