import Foundation
import UserNotifications

final class NotificationManager: NSObject {
    private let notificationCenter = UNUserNotificationCenter.current()
    private var permissionGranted = false

    func requestPermission() {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        notificationCenter.requestAuthorization(options: options) { [weak self] granted, _ in
            self?.permissionGranted = granted
        }
    }

    func postDownloadComplete(taskId: String, fileName: String) {
        guard permissionGranted else { return }
        let content = UNMutableNotificationContent()
        content.title = "Download Complete"
        content.body = "\(fileName) has finished downloading"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "download_\(taskId)",
            content: content,
            trigger: nil
        )
        notificationCenter.add(request)
    }

    func postDownloadFailed(taskId: String, fileName: String) {
        guard permissionGranted else { return }
        let content = UNMutableNotificationContent()
        content.title = "Download Failed"
        content.body = "\(fileName) could not be downloaded"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "download_failed_\(taskId)",
            content: content,
            trigger: nil
        )
        notificationCenter.add(request)
    }

    func removeDownloadNotification(taskId: String) {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: ["download_\(taskId)", "download_failed_\(taskId)"]
        )
        notificationCenter.removeDeliveredNotifications(
            withIdentifiers: ["download_\(taskId)", "download_failed_\(taskId)"]
        )
    }
}
