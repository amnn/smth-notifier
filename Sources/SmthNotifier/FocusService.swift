// Copyright (c) Ashok Menon
// SPDX-License-Identifier: Apache-2.0

import AppKit
import Foundation

/// Restores the tmux and terminal context associated with a notification.
enum FocusService {
  /// Info.plist keys populated by the Makefile for the selected terminal.
  private enum ConfigurationKey {
    static let terminalBinary = "SmthNotifierTerminalBinary"
    static let terminalBundleIdentifier = "SmthNotifierTerminalBundleIdentifier"
  }

  /// Terminal configuration required from the application bundle.
  private static let terminalBinary =
    Bundle.main.object(forInfoDictionaryKey: ConfigurationKey.terminalBinary) as! String
  private static let terminalBundleIdentifier =
    Bundle.main.object(forInfoDictionaryKey: ConfigurationKey.terminalBundleIdentifier) as! String

  /// Switches the target tmux client to its pane, then activates the terminal.
  ///
  /// If tmux fails, the terminal is not activated. If activation fails, the
  /// tmux client remains switched and the activation error is thrown.
  @MainActor
  static func focus(_ target: FocusTarget) throws {
    try switchTmux(to: target)
    try activateTerminal()
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

  /// Activates the configured running terminal application.
  @MainActor
  private static func activateTerminal() throws {
    let name = URL(fileURLWithPath: terminalBinary).lastPathComponent

    guard let terminal = runningTerminal(binary: name) else {
      throw CommandError(message: "\(name) is not running")
    }

    guard terminal.activate(options: [.activateAllWindows]) else {
      throw CommandError(message: "\(name) refused activation")
    }
  }

  /// Finds the terminal by bundle identifier, falling back to executable name.
  @MainActor
  private static func runningTerminal(binary: String) -> NSRunningApplication? {
    if !terminalBundleIdentifier.isEmpty,
      let terminal = NSRunningApplication
        .runningApplications(withBundleIdentifier: terminalBundleIdentifier)
        .first
    {
      return terminal
    }

    return NSWorkspace.shared.runningApplications.first { application in
      application.executableURL?.lastPathComponent == binary
    }
  }

}
