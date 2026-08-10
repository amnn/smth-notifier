// Copyright (c) Ashok Menon
// SPDX-License-Identifier: Apache-2.0

import AppKit
import Foundation
import OSLog
import UserNotifications

/// Logger for failures encountered after Notification Center launches the app.
private let notificationLogger = Logger(
  subsystem: "com.amnn.smth-notifier",
  category: "notification"
)

/// Handles foreground presentation and clicks on delivered notifications.
///
/// UserNotifications may call the delegate from arbitrary queues. The handler
/// protects its launch-state flag with a lock and dispatches AppKit work to the
/// main queue; this synchronization is the basis for its unchecked Sendable
/// conformance.
final class NotificationResponseHandler: NSObject,
  UNUserNotificationCenterDelegate,
  @unchecked Sendable
{
  /// Shared delegate retained for the lifetime of the process.
  static let shared = NotificationResponseHandler()

  /// Protects `didHandleResponse` across delegate and main-queue access.
  private let lock = NSLock()

  /// Whether any notification response has reached the delegate.
  private var didHandleResponse = false

  /// Prevents delegates other than `shared` from being created.
  private override init() {}

  /// Whether a notification response has reached this process.
  ///
  /// This property is safe to read from the main queue while a delegate callback
  /// updates it on another queue.
  var handled: Bool {
    lock.withLock { didHandleResponse }
  }

  /// Records that the process was launched for a notification response.
  private func markHandled() {
    lock.withLock { didHandleResponse = true }
  }

  /// Handles a notification action, focusing its tmux target for the default
  /// click action and then terminating the accessory application.
  nonisolated func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    markHandled()

    guard response.actionIdentifier == UNNotificationDefaultActionIdentifier else {
      completionHandler()
      DispatchQueue.main.async {
        NSApplication.shared.terminate(nil)
      }
      return
    }

    let target: FocusTarget?
    do {
      target = try FocusTarget(userInfo: response.notification.request.content.userInfo)
    } catch {
      notificationLogger.error(
        "Invalid notification target: \(error.localizedDescription, privacy: .public)"
      )
      target = nil
    }

    DispatchQueue.main.async {
      if let target {
        do {
          try FocusService.focus(target)
        } catch {
          notificationLogger.error(
            "Could not focus tmux pane: \(error.localizedDescription, privacy: .public)"
          )
        }
      }

      completionHandler()
      NSApplication.shared.terminate(nil)
    }
  }

  /// Requests banner presentation when a notification arrives while this
  /// accessory application is in the foreground.
  nonisolated func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner])
  }
}
