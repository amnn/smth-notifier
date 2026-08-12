// Copyright (c) Ashok Menon
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Converts inline Markdown into the plain text shown by Notification Center.
enum MarkdownPlainText {
  /// Removes inline formatting syntax while preserving the source's whitespace.
  ///
  /// Inline-only parsing retains line breaks that Foundation's full-document
  /// parser represents as non-textual presentation attributes. If parsing ever
  /// fails, the original message remains suitable for a plain notification.
  static func render(_ markdown: String) -> String {
    let options = AttributedString.MarkdownParsingOptions(
      interpretedSyntax: .inlineOnlyPreservingWhitespace
    )

    guard let attributed = try? AttributedString(markdown: markdown, options: options) else {
      return markdown
    }
    return String(attributed.characters)
  }
}
