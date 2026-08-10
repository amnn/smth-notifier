// Copyright (c) Ashok Menon
// SPDX-License-Identifier: Apache-2.0

/// Process entry point. Application setup and lifecycle live in
/// `SmthNotifierApp`.
@main
private enum SmthNotifierMain {
  @MainActor
  static func main() {
    SmthNotifierApp.run(arguments: Array(CommandLine.arguments.dropFirst()))
  }
}
