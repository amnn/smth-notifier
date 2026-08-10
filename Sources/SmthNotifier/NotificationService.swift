// Copyright (c) Ashok Menon
// SPDX-License-Identifier: Apache-2.0

import Foundation
import UserNotifications

/// Owns notification authorization, delivery, status, and removal operations.
///
/// Actor isolation serializes access to `UNUserNotificationCenter` while command
/// execution awaits framework callbacks.
actor NotificationService {
  /// Notification center associated with the notifier application.
  private let center = UNUserNotificationCenter.current()

  /// Maximum time `send(_:)` keeps the process alive while looking for the
  /// newly delivered notification.
  private static let deliveryTimeout: TimeInterval = 1.5

  /// Delay between delivery checks in nanoseconds.
  private static let deliveryPollInterval: UInt64 = 50_000_000

  /// Creates a service backed by the application's current notification center.
  init() {}

  /// Ensures the application may display alert notifications.
  ///
  /// Existing authorized, provisional, and ephemeral states succeed. An
  /// undetermined state prompts the user. Denied and unknown states throw a
  /// user-facing `CommandError`.
  func authorize() async throws {
    let settings = await center.notificationSettings()

    switch settings.authorizationStatus {
    case .authorized, .provisional, .ephemeral:
      return
    case .notDetermined:
      guard try await center.requestAuthorization(options: [.alert]) else {
        throw CommandError(message: "Notification permission was denied")
      }
    case .denied:
      throw CommandError(message: "Notification permission is denied in System Settings")
    @unknown default:
      throw CommandError(message: "Unknown notification authorization status")
    }
  }

  /// Returns a stable, human-readable name for the current authorization state.
  func status() async -> String {
    let settings = await center.notificationSettings()

    switch settings.authorizationStatus {
    case .notDetermined: return "not determined"
    case .denied: return "denied"
    case .authorized: return "authorized"
    case .provisional: return "provisional"
    case .ephemeral: return "ephemeral"
    @unknown default: return "unknown"
    }
  }

  /// Replaces any notification with the same identifier and schedules a new
  /// banner carrying its tmux focus target.
  ///
  /// The method waits until delivery is observed or the short delivery timeout
  /// elapses, keeping this command process alive long enough for macOS to accept
  /// and present the request.
  func send(_ options: SendOptions) async throws {
    try await authorize()

    center.removePendingNotificationRequests(withIdentifiers: [options.identifier])
    center.removeDeliveredNotifications(withIdentifiers: [options.identifier])

    let content = UNMutableNotificationContent()
    content.title = options.title
    content.body = options.message
    content.userInfo = options.target.notificationUserInfo

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
    let request = UNNotificationRequest(
      identifier: options.identifier,
      content: content,
      trigger: trigger
    )
    try await center.add(request)

    let deadline = Date().addingTimeInterval(Self.deliveryTimeout)
    while Date() < deadline {
      try await Task.sleep(nanoseconds: Self.deliveryPollInterval)
      let delivered = await center.deliveredNotifications()
      if delivered.contains(where: { $0.request.identifier == options.identifier }) {
        center.removePendingNotificationRequests(withIdentifiers: [options.identifier])
        return
      }
    }
  }

  /// Removes pending and delivered notifications.
  ///
  /// When `identifier` is non-`nil`, only that notification is removed. Passing
  /// `nil` clears all notifications owned by this application.
  func clear(identifier: String?) {
    if let identifier {
      center.removePendingNotificationRequests(withIdentifiers: [identifier])
      center.removeDeliveredNotifications(withIdentifiers: [identifier])
    } else {
      center.removeAllPendingNotificationRequests()
      center.removeAllDeliveredNotifications()
    }
  }
}
