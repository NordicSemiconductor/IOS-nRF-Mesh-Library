// swift-tools-version:5.9
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
      .upToNextMinor(from: "1.8.0")
    ),
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
  ],
  targets: [
    .target(
      name: "nRFMeshProvision",
      dependencies: ["CryptoSwift"],
      path: "nRFMeshProvision/",
      resources: [
          .copy("Resources/PrivacyInfo.xcprivacy")
      ]
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
