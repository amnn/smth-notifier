// Copyright (c) Ashok Menon
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// A notifier failure with a message suitable for command-line presentation.
struct CommandError: LocalizedError, Sendable {
  /// Text returned through `LocalizedError`.
  private let message: String

  /// Creates an error that presents `message` without additional formatting.
  init(message: String) {
    self.message = message
  }

  /// User-facing description printed when a command fails.
  var errorDescription: String? { message }
}
