// swift-tools-version: 6.0
// Copyright (c) Ashok Menon
// SPDX-License-Identifier: Apache-2.0

import PackageDescription

let package = Package(
  name: "smth-notifier",
  platforms: [.macOS(.v13)],
  products: [
    .executable(name: "smth-notifier", targets: ["SmthNotifier"])
  ],
  targets: [
    .executableTarget(name: "SmthNotifier")
  ],
  swiftLanguageModes: [.v5]
)
