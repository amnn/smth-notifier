// Copyright (c) Ashok Menon
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Resolves command names using the process environment.
enum ExecutableLocator {
  /// Returns the first executable named `name` in `PATH`.
  static func path(named name: String) throws -> String {
    guard let path = ProcessInfo.processInfo.environment["PATH"] else {
      throw CommandError(message: "\(name) was not found because PATH is not set")
    }

    let files = FileManager.default
    for component in path.split(separator: ":", omittingEmptySubsequences: false) {
      let directory = component.isEmpty ? files.currentDirectoryPath : String(component)
      let candidate = URL(fileURLWithPath: directory, isDirectory: true)
        .appendingPathComponent(name, isDirectory: false)
      var isDirectory: ObjCBool = false

      if files.fileExists(atPath: candidate.path, isDirectory: &isDirectory),
        !isDirectory.boolValue,
        files.isExecutableFile(atPath: candidate.path)
      {
        return candidate.path
      }
    }

    throw CommandError(message: "\(name) was not found in PATH")
  }
}
