// Copyright (c) Ashok Menon
// SPDX-License-Identifier: Apache-2.0

/// Parsed `--name value` arguments for one notifier command.
struct CommandLineOptions {
  /// Values keyed by option name without the leading `--`.
  private let values: [String: String]

  /// Parses `arguments`, accepting only names in `allowed`.
  ///
  /// Every option must use the two-argument `--name value` form and may occur
  /// only once. Values are stored verbatim, including empty strings and strings
  /// that begin with `--`. Unexpected positional arguments, unknown options,
  /// duplicates, and options without values produce `CommandError`.
  init(arguments: [String], allowed: Set<String>) throws {
    var values: [String: String] = [:]
    var index = 0

    while index < arguments.count {
      let argument = arguments[index]
      guard argument.hasPrefix("--") else {
        throw CommandError(message: "Unexpected argument: \(argument)")
      }

      let name = String(argument.dropFirst(2))
      guard allowed.contains(name) else {
        throw CommandError(message: "Unknown option: --\(name)")
      }
      guard values[name] == nil else {
        throw CommandError(message: "Duplicate option: --\(name)")
      }

      index += 1
      guard index < arguments.count else {
        throw CommandError(message: "Missing value for --\(name)")
      }
      values[name] = arguments[index]
      index += 1
    }

    self.values = values
  }

  /// Returns the value for `name`.
  ///
  /// By default an absent or empty value produces `CommandError`. Set
  /// `allowEmpty` when an explicitly supplied empty string is valid.
  func required(_ name: String, allowEmpty: Bool = false) throws -> String {
    guard let value = values[name], allowEmpty || !value.isEmpty else {
      throw CommandError(message: "Missing --\(name)")
    }
    return value
  }
}
