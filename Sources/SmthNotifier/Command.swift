// Copyright (c) Ashok Menon
// SPDX-License-Identifier: Apache-2.0

/// Dispatches the notifier's command-line interface.
enum Command {
  /// Help text printed by the help command and unknown-command errors.
  private static let usage = """
    Usage:
      smth-notifier authorize
      smth-notifier status
      smth-notifier clear [IDENTIFIER]
      smth-notifier focus --socket PATH --tty PATH --pane ID
      smth-notifier send --title TEXT --message TEXT --identifier ID \\
        --socket PATH --tty PATH --pane ID
    """

  /// Executes the command in `arguments`.
  ///
  /// The first argument is the command name and subsequent arguments belong to
  /// that command. An empty array is a no-op. Invalid arguments and command
  /// failures are reported by throwing a localized error.
  @MainActor
  static func run(arguments: [String]) async throws {
    guard let name = arguments.first else { return }
    let rest = Array(arguments.dropFirst())
    let notifications = NotificationService()

    switch name {
    case "authorize":
      guard rest.isEmpty else {
        throw CommandError(message: "authorize takes no arguments")
      }
      try await notifications.authorize()
      print("Notifications authorized")

    case "status":
      guard rest.isEmpty else {
        throw CommandError(message: "status takes no arguments")
      }
      print(await notifications.status())

    case "clear":
      guard rest.count <= 1 else {
        throw CommandError(message: "clear accepts at most one identifier")
      }
      await notifications.clear(identifier: rest.first)

    case "focus":
      let options = try CommandLineOptions(
        arguments: rest,
        allowed: ["socket", "tty", "pane"]
      )
      try FocusService.focus(FocusTarget(options: options))

    case "send":
      try await notifications.send(SendOptions(arguments: rest))

    case "help", "--help", "-h":
      print(usage)

    default:
      throw CommandError(message: "Unknown command: \(name)\n\n\(usage)")
    }
  }
}
