import SwiftUI
import SwiftData
import UserNotifications

@main
struct ClamUpApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let container: ModelContainer
    @State private var session: SessionController

    init() {
        let container: ModelContainer
        do {
            container = try ModelContainer(for: Catch.self)
        } catch {
            fatalError("Couldn't open the tide pool: \(error)")
        }
        self.container = container
        #if DEBUG
        DebugTools.handleLaunchArguments(container.mainContext)
        #endif
        _session = State(initialValue: SessionController(context: container.mainContext))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .preferredColorScheme(.dark)
        }
        .modelContainer(container)
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    private let presenter = NotificationPresenter()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = presenter
        return true
    }
}
