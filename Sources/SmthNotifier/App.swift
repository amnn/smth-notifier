// Copyright (c) Ashok Menon
// SPDX-License-Identifier: Apache-2.0

import AppKit
import Darwin
import Foundation
import UserNotifications

/// Configures AppKit and runs the notifier in command or response mode.
///
/// Supplying command-line arguments executes one command and exits. With no
/// arguments, the process waits briefly for a notification response delivered
/// by macOS and exits after handling it or reaching the idle timeout.
enum SmthNotifierApp {
  /// Time an argument-free launch waits for Notification Center to deliver a
  /// response before treating the launch as spurious.
  private static let responseTimeout: TimeInterval = 2

  /// Runs the application for `arguments`.
  ///
  /// Command mode keeps the AppKit run loop alive while asynchronous notification
  /// work completes. Response mode installs the notification delegate and waits
  /// for a click on a previously delivered notification.
  @MainActor
  static func run(arguments: [String]) {
    let handler = NotificationResponseHandler.shared
    UNUserNotificationCenter.current().delegate = handler

    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)

    if arguments.isEmpty {
      scheduleIdleTermination(of: app, unlessHandledBy: handler)
    } else {
      executeCommand(arguments)
    }

    app.run()
  }

  /// Schedules termination for an argument-free launch that does not receive a
  /// notification response before `responseTimeout` elapses.
  @MainActor
  private static func scheduleIdleTermination(
    of app: NSApplication,
    unlessHandledBy handler: NotificationResponseHandler
  ) {
    DispatchQueue.main.asyncAfter(deadline: .now() + responseTimeout) {
      if !handler.handled {
        app.terminate(nil)
      }
    }
  }

  /// Executes one command on the main actor, prints user-facing failures to
  /// standard error, and exits with the corresponding process status.
  @MainActor
  private static func executeCommand(_ arguments: [String]) {
    Task { @MainActor in
      do {
        try await Command.run(arguments: arguments)
        Darwin.exit(EXIT_SUCCESS)
      } catch {
        fputs("smth-notifier: \(error.localizedDescription)\n", stderr)
        Darwin.exit(EXIT_FAILURE)
      }
    }
  }
}
