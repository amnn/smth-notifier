// Copyright (c) Ashok Menon
// SPDX-License-Identifier: Apache-2.0

/// Validated arguments for the `send` command.
struct SendOptions: Sendable {
  /// Notification title.
  let title: String

  /// Notification body, which may be empty.
  let message: String

  /// Identifier used to replace and later clear the notification.
  let identifier: String

  /// tmux destination restored when the notification is clicked.
  let target: FocusTarget

  /// Parses and validates all options accepted by the `send` command.
  init(arguments: [String]) throws {
    let options = try CommandLineOptions(
      arguments: arguments,
      allowed: ["title", "message", "identifier", "socket", "tty", "pane"]
    )
    title = try options.required("title")
    message = try options.required("message", allowEmpty: true)
    identifier = try options.required("identifier")
    target = try FocusTarget(options: options)
  }
}
