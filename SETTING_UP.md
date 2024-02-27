## Setting up the nRF Mesh library

Using CocoaPods:

#### Swift Package Manager

You can use [Swift Package Manager](https://swift.org/package-manager/) and specify dependency in `Package.swift` by adding this:

```swift
.package(url: "https://github.com/NordicSemiconductor/IOS-nRF-Mesh-Library", .upToNextMinor(from: "x.y")) // Replace x.y with your required version
```

Also, have a look at [Swift Package Manager @ CryptoSwift](https://github.com/krzyzanowskim/CryptoSwift/blob/master/README.md#swift-package-manager).

#### Cocoapods

- Create/Update your **Podfile** with the following contents

    ```
    target 'YourAppTargetName' do
        pod 'nRFMeshProvision'
    end
    ```

- Install dependencies

    ```
    pod install
    ```

- Open the newly created `.xcworkspace`

#### Carthage

- Create a new **Cartfile** in your project's root with the following contents

    ```
    github "NordicSemiconductor/IOS-nRF-Mesh-Library" ~> x.y // Replace x.y with your required version
    ```

- Build with carthage

    ```
    carthage update [--platform iOS] --use-xcframeworks // also OSX platform is available for macOS builds
    ```

- Carthage will build the **NordicMesh.xcframework** and **CryptoSwift.xcframework** files in **Carthage/Build/**.
  Copy frameworks for required platforms into your Xcode project like described [here](https://github.com/Carthage/Carthage?tab=readme-ov-file#quick-start).

## Importing NordicMesh framework

Import the library to any of your classes by using `import NordicMesh` and begin working on your project!