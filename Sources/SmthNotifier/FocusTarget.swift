// Copyright (c) Ashok Menon
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Identifies the tmux client, pane, and terminal application for a notification.
struct FocusTarget: Sendable {
  /// tmux executable resolved from `PATH` when the target is created.
  let tmuxPath: String

  /// Path to the tmux server socket passed to `tmux -S`.
  let socket: String

  /// Client terminal passed to `tmux switch-client -c`.
  let tty: String

  /// Destination pane passed to `tmux switch-client -t`.
  let pane: String

  /// Bundle identifier of the terminal to activate, or `nil` to disable focus.
  let terminalBundleIdentifier: String?

  /// Key used to store `tmuxPath` in notification metadata.
  private static let tmuxKey = "tmux"

  /// Key used to store `socket` in notification metadata.
  private static let socketKey = "socket"

  /// Key used to store `tty` in notification metadata.
  private static let ttyKey = "tty"

  /// Key used to store `pane` in notification metadata.
  private static let paneKey = "pane"

  /// Key used to store `terminalBundleIdentifier` in notification metadata.
  private static let terminalKey = "terminal"

  /// Creates a target from required `socket`, `tty`, and `pane` options, an
  /// optional `terminal`, and tmux resolved from the current process's `PATH`.
  init(options: CommandLineOptions) throws {
    socket = try options.required(Self.socketKey)
    tty = try options.required(Self.ttyKey)
    pane = try options.required(Self.paneKey)
    terminalBundleIdentifier = try options.optional(Self.terminalKey)
    tmuxPath = try ExecutableLocator.path(named: "tmux")
  }

  /// Reconstructs a target from notification metadata.
  ///
  /// The four tmux values must be nonempty strings. The terminal may be absent
  /// to disable focus, but must be a nonempty string when present.
  init(userInfo: [AnyHashable: Any]) throws {
    guard let tmuxPath = userInfo[Self.tmuxKey] as? String,
      !tmuxPath.isEmpty,
      let socket = userInfo[Self.socketKey] as? String,
      !socket.isEmpty,
      let tty = userInfo[Self.ttyKey] as? String,
      !tty.isEmpty,
      let pane = userInfo[Self.paneKey] as? String,
      !pane.isEmpty
    else {
      throw CommandError(message: "Notification is missing its focus target")
    }

    if let terminal = userInfo[Self.terminalKey] {
      guard let bundleIdentifier = terminal as? String, !bundleIdentifier.isEmpty else {
        throw CommandError(message: "Notification has an invalid terminal bundle identifier")
      }
      terminalBundleIdentifier = bundleIdentifier
    } else {
      terminalBundleIdentifier = nil
    }

    self.tmuxPath = tmuxPath
    self.socket = socket
    self.tty = tty
    self.pane = pane
  }

  /// Metadata embedded in a notification so a later click can reconstruct this
  /// target, including when macOS launches a new notifier process to handle it.
  var notificationUserInfo: [AnyHashable: Any] {
    var userInfo: [AnyHashable: Any] = [
      Self.tmuxKey: tmuxPath,
      Self.socketKey: socket,
      Self.ttyKey: tty,
      Self.paneKey: pane,
    ]
    if let terminalBundleIdentifier {
      userInfo[Self.terminalKey] = terminalBundleIdentifier
    }
    return userInfo
  }
}
