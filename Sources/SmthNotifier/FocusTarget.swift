// Copyright (c) Ashok Menon
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Identifies the tmux client and pane associated with a notification.
struct FocusTarget: Sendable {
  /// tmux executable resolved from `PATH` when the target is created.
  let tmuxPath: String

  /// Path to the tmux server socket passed to `tmux -S`.
  let socket: String

  /// Client terminal passed to `tmux switch-client -c`.
  let tty: String

  /// Destination pane passed to `tmux switch-client -t`.
  let pane: String

  /// Key used to store `tmuxPath` in notification metadata.
  private static let tmuxKey = "tmux"

  /// Key used to store `socket` in notification metadata.
  private static let socketKey = "socket"

  /// Key used to store `tty` in notification metadata.
  private static let ttyKey = "tty"

  /// Key used to store `pane` in notification metadata.
  private static let paneKey = "pane"

  /// Creates a target from required `socket`, `tty`, and `pane` command-line
  /// options and resolves tmux from the current process's `PATH`.
  init(options: CommandLineOptions) throws {
    socket = try options.required(Self.socketKey)
    tty = try options.required(Self.ttyKey)
    pane = try options.required(Self.paneKey)
    tmuxPath = try ExecutableLocator.path(named: "tmux")
  }

  /// Reconstructs a target from notification metadata.
  ///
  /// All four values must be present as nonempty strings. Otherwise the
  /// notification is rejected rather than partially handled.
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
      throw CommandError(message: "Notification is missing its tmux target")
    }

    self.tmuxPath = tmuxPath
    self.socket = socket
    self.tty = tty
    self.pane = pane
  }

  /// Metadata embedded in a notification so a later click can reconstruct this
  /// target, including when macOS launches a new notifier process to handle it.
  var notificationUserInfo: [AnyHashable: Any] {
    [
      Self.tmuxKey: tmuxPath,
      Self.socketKey: socket,
      Self.ttyKey: tty,
      Self.paneKey: pane,
    ]
  }
}
