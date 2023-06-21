// swift-tools-version:5.8
//
// The `swift-tools-version` declares the minimum version of Swift required to
// build this package. Do not remove it.

import PackageDescription

let package = Package(
  name: "NordicMesh",
  platforms: [
    .macOS(.v10_15),
    .iOS(.v13)
  ],
  products: [
    .library(name: "NordicMesh", targets: ["nRFMeshProvision"])
  ],
  dependencies: [
    .package(
      url: "https://github.com/krzyzanowskim/CryptoSwift", 
      .upToNextMinor(from: "1.7.0")
    ),
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
  ],
  targets: [
    .target(
      name: "nRFMeshProvision",
      dependencies: ["CryptoSwift"],
      path: "nRFMeshProvision/"
    ),
    .testTarget(
      name: "NordicMeshTests",
      dependencies: ["nRFMeshProvision"],
      path: "Example/Tests",
      exclude: ["Info.plist"]
    )
  ],
  swiftLanguageVersions: [.v5]
)
