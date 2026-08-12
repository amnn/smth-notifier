// Copyright (c) Ashok Menon
// SPDX-License-Identifier: Apache-2.0

import Testing

@testable import SmthNotifier

@Suite
struct MarkdownPlainTextTests {
  @Test
  func removesSupportedInlineFormatting() {
    let markdown = "plain **bold** *italic* `code` and ***both***"

    #expect(
      MarkdownPlainText.render(markdown) == "plain bold italic code and both"
    )
  }

  @Test
  func resolvesLinksAndEscapedDelimiters() {
    let markdown = #"Read [the docs](https://example.com) and keep \*this\* literal"#

    #expect(
      MarkdownPlainText.render(markdown) == "Read the docs and keep *this* literal"
    )
  }

  @Test
  func preservesWhitespaceAndBlockMarkers() {
    let markdown = "## **Result**\n\n- changed `one`\n- changed *two*"

    #expect(
      MarkdownPlainText.render(markdown) == "## Result\n\n- changed one\n- changed two"
    )
  }

  @Test
  func allowsEmptyMessage() {
    #expect(MarkdownPlainText.render("").isEmpty)
  }
}
