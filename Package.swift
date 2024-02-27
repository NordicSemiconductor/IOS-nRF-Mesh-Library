// swift-tools-version:5.9
import PackageDescription

let package = Package(
  name: "NordicMesh",
  platforms: [
    .macOS(.v10_15),
    .iOS(.v13)
  ],
  products: [
    .library(name: "NordicMesh", targets: ["NordicMesh"])
  ],
  dependencies: [
    .package(
      url: "https://github.com/krzyzanowskim/CryptoSwift", 
      .upToNextMinor(from: "1.8.1")
    ),
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.3.0"),
  ],
  targets: [
    .target(
      name: "NordicMesh",
      dependencies: ["CryptoSwift"],
      path: "Library/",
      resources: [
          .copy("Resources/PrivacyInfo.xcprivacy")
      ]
    ),
    .testTarget(
      name: "NordicMeshTests",
      dependencies: ["NordicMesh"],
      path: "Example/Tests",
      exclude: ["Info.plist"]
    )
  ],
  swiftLanguageVersions: [.v5]
)
