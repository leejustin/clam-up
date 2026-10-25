import Foundation
import UserNotifications

enum PearlNotifications {
    static let readyID = "pearl-ready"

    @discardableResult
    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return true
        case .denied: return false
        default: return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        }
    }

    static func scheduleReady(at date: Date, body: String) {
        let content = UNMutableNotificationContent()
        content.title = "Clam Up"
        content.body = body
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        let seconds = max(1, date.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: readyID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func cancelReady() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [readyID])
        center.removeDeliveredNotifications(withIdentifiers: [readyID])
    }
}

/// Shows the "pearl ready" banner even while the app is on screen, since the app is usually on the cover display.
final class NotificationPresenter: NSObject, UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
