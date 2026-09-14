// Copyright (c) Ashok Menon
// SPDX-License-Identifier: Apache-2.0

import Darwin
import Foundation
import Testing

@testable import SmthNotifier

/// Serializes tests that temporarily replace PATH with a stub tmux executable.
@Suite(.serialized)
struct FocusTargetTests {
  private let focusArguments = [
    "--socket", "/tmp/smth-notifier-test.socket",
    "--tty", "/dev/ttys001",
    "--pane", "%1",
  ]

  private let notificationArguments = [
    "--title", "Test",
    "--message", "Ready",
    "--identifier", "smth:%1",
  ]

  private let allowedOptions: Set<String> = ["socket", "tty", "pane", "terminal"]

  @Test(arguments: ["com.apple.Terminal", "com.mitchellh.ghostty"])
  func sendPreservesTerminalForNotificationClick(bundleIdentifier: String) throws {
    try withTmux { tmuxPath in
      let options = try SendOptions(
        arguments: notificationArguments + focusArguments + ["--terminal", bundleIdentifier]
      )
      let target = options.target
      let userInfo = target.notificationUserInfo

      #expect(target.terminalBundleIdentifier == bundleIdentifier)
      #expect(target.tmuxPath == tmuxPath)
      #expect(userInfo["terminal"] as? String == bundleIdentifier)

      let restored = try FocusTarget(userInfo: userInfo)
      #expect(restored.terminalBundleIdentifier == bundleIdentifier)
      #expect(restored.tmuxPath == tmuxPath)
      #expect(restored.socket == "/tmp/smth-notifier-test.socket")
      #expect(restored.tty == "/dev/ttys001")
      #expect(restored.pane == "%1")
    }
  }

  @Test
  func allowsOmittingTerminal() throws {
    try withTmux { _ in
      let options = try CommandLineOptions(arguments: focusArguments, allowed: allowedOptions)
      let target = try FocusTarget(options: options)
      #expect(target.terminalBundleIdentifier == nil)

      let send = try SendOptions(arguments: notificationArguments + focusArguments)
      #expect(send.target.terminalBundleIdentifier == nil)
      #expect(send.target.notificationUserInfo["terminal"] == nil)

      let restored = try FocusTarget(userInfo: send.target.notificationUserInfo)
      #expect(restored.terminalBundleIdentifier == nil)
    }
  }

  @Test
  func rejectsEmptyTerminal() throws {
    let arguments = focusArguments + ["--terminal", ""]
    let options = try CommandLineOptions(arguments: arguments, allowed: allowedOptions)

    #expect {
      try FocusTarget(options: options)
    } throws: { error in
      error.localizedDescription == "Missing --terminal"
    }

    #expect {
      try SendOptions(arguments: notificationArguments + arguments)
    } throws: { error in
      error.localizedDescription == "Missing --terminal"
    }
  }

  @Test
  func rejectsDuplicateTerminal() {
    #expect {
      try SendOptions(
        arguments: notificationArguments + focusArguments + [
          "--terminal", "com.apple.Terminal",
          "--terminal", "com.mitchellh.ghostty",
        ]
      )
    } throws: { error in
      error.localizedDescription == "Duplicate option: --terminal"
    }
  }

  @Test
  func reconstructsTargetWithoutResolvingTmux() throws {
    let target = try FocusTarget(userInfo: notificationUserInfo)

    #expect(target.tmuxPath == "/not-on-path/tmux")
    #expect(target.terminalBundleIdentifier == "com.mitchellh.ghostty")
  }

  @Test
  @MainActor
  func skipsFocusWithoutTerminal() throws {
    var userInfo = notificationUserInfo
    userInfo["terminal"] = nil
    let target = try FocusTarget(userInfo: userInfo)

    #expect(target.terminalBundleIdentifier == nil)
    #expect(target.notificationUserInfo["terminal"] == nil)
    // The stored tmux path does not exist, so attempting to switch would fail.
    try FocusService.focus(target)
  }

  @Test(arguments: ["tmux", "socket", "tty", "pane"])
  func rejectsMissingTmuxTarget(key: String) {
    var userInfo = notificationUserInfo
    userInfo[key] = nil
    #expect(throws: CommandError.self) {
      try FocusTarget(userInfo: userInfo)
    }
  }

  @Test(arguments: ["tmux", "socket", "tty", "pane", "terminal"])
  func rejectsInvalidNotificationTarget(key: String) {
    var userInfo = notificationUserInfo
    userInfo[key] = ""
    #expect(throws: CommandError.self) {
      try FocusTarget(userInfo: userInfo)
    }

    userInfo[key] = 42
    #expect(throws: CommandError.self) {
      try FocusTarget(userInfo: userInfo)
    }
  }

  private var notificationUserInfo: [AnyHashable: Any] {
    [
      "tmux": "/not-on-path/tmux",
      "socket": "/tmp/smth-notifier-test.socket",
      "tty": "/dev/ttys001",
      "pane": "%1",
      "terminal": "com.mitchellh.ghostty",
    ]
  }

  /// Allows PATH resolution without depending on a locally installed tmux.
  private func withTmux(_ body: (String) throws -> Void) throws {
    let files = FileManager.default
    let directory = files.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try files.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? files.removeItem(at: directory) }

    let tmux = directory.appendingPathComponent("tmux")
    try Data("#!/bin/sh\nexit 0\n".utf8).write(to: tmux)
    try files.setAttributes([.posixPermissions: 0o755], ofItemAtPath: tmux.path)

    let originalPath = ProcessInfo.processInfo.environment["PATH"]
    setenv("PATH", directory.path, 1)
    defer {
      if let originalPath {
        setenv("PATH", originalPath, 1)
      } else {
        unsetenv("PATH")
      }
    }

    try body(tmux.path)
  }
}
