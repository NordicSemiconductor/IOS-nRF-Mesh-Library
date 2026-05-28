# MemfaultCloud iOS Library

## Demo App

The Xcode workspace `Example/MemfaultCloud.xcworkspace` contains a `DemoApp`
target. This is a very basic iOS app that demonstrates the functionality of this
library.

Before building the app, make sure to update the Project Key in
`AppDelegate.swift`. To find your Project Key, log in to
https://app.memfault.com/ and navigate to Settings.

```swift
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Enable debug logs:
        gMFLTLogLevel = .debug

        MemfaultApi.configureSharedApi([
            kMFLTProjectKey: "<YOUR_PROJECT_KEY_HERE>",
        ])
        return true
    }
}
```

## Integration Guide

### Adding MemfaultCloud to your project

#### Swift Package Manager

Add this line to your dependencies list in your Package.swift:

```
.package(name: "MemfaultCloud", url: "https://github.com/memfault/memfault-ios-cloud.git", from: "2.2.1"),
```

#### CocoaPods

In case you are using CocoaPods, you can add `MemfaultCloud` as a dependency to
your `Podfile`:

```
target 'MyApp' do
  pod 'MemfaultCloud'
end
```

It's probably a good idea to specify the version to use. See the [Podfile
documentation] for more information.

After adding the new dependency, run `pod install` inside your terminal, or from
CocoaPods.app.

#### Without dependency manager

To use `MemfaultCloud` without using a dependency manager such as CocoaPods,
just clone this repo and add the `.h` and `.m` files inside `MemfaultCloud`
folder to your project.

### Configuration

The `MemfaultApi` class is the main class of the MemfaultCloud library. It is
recommended to use the `MemfaultApi.sharedApi` property that returns the
singleton instance, instead of "manually" creating an instance. Using the
singleton ensures that requests to our servers are made sequentially, when
required.

Before using `MemfaultApi.sharedApi`, you will need to configure it once and
only once by passing a configuration dictionary to
`MemfaultApi.configureSharedApi([...])`

The Project Key is the only mandatory piece of configuration. To find your
Project Key, log in to https://app.memfault.com/ and navigate to Settings.

```swift
MemfaultApi.configureSharedApi([
    kMFLTProjectKey: "<YOUR_PROJECT_KEY_HERE>",
])
```

### Getting the latest release

The `api.getLatestRelease` can be used to see if a device is up-to-date or
whether there is a new OTA update payload available for it.

The app is expected to be able to communicate with the device and fetch its
serial number, hardware version, current software version and type. Create a
`MemfaultDeviceInfo` object from that information and pass it to
`api.getLatestRelease`:

```swift
let deviceInfo = MemfaultDeviceInfo(
  deviceSerial: "DEMO_SERIAL",
  hardwareVersion: "proto",
  softwareVersion: "1.0.0",
  softwareType: "main")

MemfaultApi.sharedApi.getLatestRelease(for: deviceInfo) { (package, isUpToDate, error) in
  if error != nil {
    print("There was an error, handle it here.")
    return
  }
  if package == nil {
    print("Device is already up to date!")
    return
  }
  print("Update available: \(package!.description)")
}
```

The `MemfaultOtaPackage package` object has a `location` property, which
contains the URL to the OTA payload.

### Uploading Chunks

The Memfault Firmware SDK packetizes data that needs to be sent back to
Memfault's cloud into "chunks". See
[this tutorial for more information on the device/firmware details](https://docs.memfault.com/docs/mcu/data-from-firmware-to-the-cloud).

This iOS library contains a high-level API to submit the chunks to Memfault.

Getting the chunks out of the device and into the iOS app is part of the
integration work. The assumption is that you already have a communication
mechanism between the device and iOS app that can be leveraged.

```swift
// Array with Data objects, each with chunk bytes
// (produced by the Memfault Firmware SDK packetizer and sent
// to the iOS app to be posted to the cloud):
let chunks = [...]

MemfaultApi.shared.chunkSender(withDeviceSerial: "DEMO_SERIAL").postChunks(chunks)
```

### Custom Queue Implementations

The default queue implementation is RAM backed. Therefore, if the host app is
killed or the iOS device is shutdown or rebooted, the contents of the queue are
lost. This can be a reason to override the default queue implementation.

The library provides a "hook" to override the default queue implementation, by
setting the `kMFLTChunkQueueProvider` configuration option to an object that
conforms to `MemfaultChunkQueueProvider`.

When using a disk-backed custom queue, we also recommend setting the
`chunksMaxConsecutiveErrorCount` configuration option to `0` to never drop
chunks when consecutive errors occur.

```swift
class MyQueueProvider: MemfaultChunkQueueProvider {
    func queue(withDeviceSerial deviceSerial: String) -> MemfaultChunkQueue {
        // Get or create a queue for the given deviceSerial.
        // The queue object needs to implement
        // the MemfaultChunkQueue protocol.
        let queue = ...
        return queue
    }
}

func bootMemfault() {
    let queueProvider = MyQueueProvider()

    MemfaultApi.configureSharedApi([
        kMFLTProjectKey: "<YOUR_PROJECT_KEY_HERE>",

        // Pass the custom queue provider in the configuration:
        kMFLTChunkQueueProvider: queueProvider,

        // Never drop chunks on consecutive upload errors:
        kMFLTChunksMaxConsecutiveErrorCount: 0,
    ])

    // If your queue implementation persists the contents of the
    // queues between app restarts, you will need to call postChunks()
    // after restarting the app. This re-registers the queues that were loaded
    // from persistent storage and resumes the upload process again:

    let deviceSerialsToResume = [ ... ]

    for sn in deviceSerialsToResume {
        MemfaultApi.shared.chunkSender(withDeviceSerial: sn).postChunks()
    }
}
```

## API Documentation

`MemfaultCloud.h` contains detailed documentation for each API.

## Unit Tests

The Xcode workspace `Example/MemfaultCloud.xcworkspace` also contains a
`MemfaultCloud_Tests` scheme. To run the tests, select this scheme, then select
Product > Test (cmd + U).

## Changelog

See [CHANGELOG.md] file.

[changelog.md]: CHANGELOG.md
[podfile documentation]: https://guides.cocoapods.org/syntax/podfile.html#pod
