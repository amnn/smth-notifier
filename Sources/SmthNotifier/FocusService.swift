// Copyright (c) Ashok Menon
// SPDX-License-Identifier: Apache-2.0

import AppKit
import Foundation

/// Restores the tmux and terminal context associated with a notification.
enum FocusService {
  /// Switches the target tmux client to its pane, then activates the terminal.
  ///
  /// Does nothing when no terminal is configured. If tmux fails, the terminal
  /// is not activated. If activation fails, the tmux client remains switched
  /// and the activation error is thrown.
  @MainActor
  static func focus(_ target: FocusTarget) throws {
    guard let bundleIdentifier = target.terminalBundleIdentifier else { return }

    try switchTmux(to: target)
    try activateTerminal(bundleIdentifier: bundleIdentifier)
  }

  /// Runs the target's resolved tmux executable and reports nonzero exits.
  private static func switchTmux(to target: FocusTarget) throws {
    let process = Process()
    let errors = Pipe()
    process.executableURL = URL(fileURLWithPath: target.tmuxPath)
    process.arguments = [
      "-S", target.socket,
      "switch-client",
      "-c", target.tty,
      "-t", target.pane,
    ]
    process.standardOutput = FileHandle.nullDevice
    process.standardError = errors

    try process.run()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
      let data = errors.fileHandleForReading.readDataToEndOfFile()
      let detail = String(data: data, encoding: .utf8)?
        .trimmingCharacters(in: .whitespacesAndNewlines)

      if let detail, !detail.isEmpty {
        throw CommandError(message: "tmux failed: \(detail)")
      }

      throw CommandError(message: "tmux failed with status \(process.terminationStatus)")
    }
  }

  /// Activates the first running terminal with the target's bundle identifier.
  @MainActor
  private static func activateTerminal(bundleIdentifier: String) throws {
    guard
      let terminal =
        NSRunningApplication
        .runningApplications(withBundleIdentifier: bundleIdentifier)
        .first
    else {
      throw CommandError(message: "\(bundleIdentifier) is not running")
    }

    guard terminal.activate(options: [.activateAllWindows]) else {
      throw CommandError(message: "\(bundleIdentifier) refused activation")
    }
  }
}
