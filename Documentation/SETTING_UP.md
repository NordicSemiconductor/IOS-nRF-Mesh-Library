## Setting up the nRF Mesh library

Using CocoaPods:

**For Cocoapods(Swift):**

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


**For Carthage:**

- Create a new **Cartfile** in your project's root with the following contents

    ```
    github "NordicSemiconductor//IOS-nRF-Mesh-Library" ~> x.y //Replace x.y with your required version
    ```

- Build with carthage

    ```
    carthage update --platform iOS //also OSX platform is available for macOS builds
    ```

- Carthage will build the **nRFMeshProvision.framework** files in **Carthage/Build/**, 
you may now copy all those files to your project and use the library, additionally, carthade also builds **\*.dsym** files 
if you need to resymbolicate crash logs. you may want to keep those files bundled with your builds for future use.

**For Swift Package Manager:**

The nRF Mesh library is not available on SPM as it depends on [OpenSSL](https://github.com/krzyzanowskim/OpenSSL) which is released as binaries. Binary dependencies aren't supported by Swift Package Manager [source](https://developer.apple.com/documentation/xcode/creating_a_swift_package_with_xcode).

Next: [Getting started >](GETTING_STARTED.md)