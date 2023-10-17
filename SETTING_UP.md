## Setting up the nRF Mesh library

Using CocoaPods:

#### Swift Package Manager

You can use [Swift Package Manager](https://swift.org/package-manager/) and specify dependency in `Package.swift` by adding this:

```swift
.package(url: "https://github.com/NordicSemiconductor/IOS-nRF-Mesh-Library", .upToNextMinor(from: "4.0.1"))
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

- Import the library to any of your classes by using `import nRFMeshProvision` and begin working on your project


#### Carthage

- Create a new **Cartfile** in your project's root with the following contents

    ```
    github "NordicSemiconductor/IOS-nRF-Mesh-Library" ~> x.y // Replace x.y with your required version
    ```

- Build with carthage

    ```
    carthage update --platform iOS // also OSX platform is available for macOS builds
    ```

- Carthage will build the **nRFMeshProvision.framework** files in **Carthage/Build/**, 
you may now copy all those files to your project and use the library, additionally, carthage also builds **\*.dsym** files 
if you need to resymbolicate crash logs. you may want to keep those files bundled with your builds for future use.

Next: [Getting started >](GETTING_STARTED.md)
