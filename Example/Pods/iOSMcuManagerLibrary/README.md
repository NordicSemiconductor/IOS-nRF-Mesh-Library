> [!NOTE]  
> This repository is a fork of the [McuManager iOS Library](https://github.com/JuulLabs-OSS/mcumgr-ios), which is no longer being supported by its original maintainer. As of 2021, we have taken ownership of the library, so all new features and bug fixes will be added here. Please, migrate your projects to point to this Git repsository in order to get future updates. See [migration guide](https://github.com/NordicSemiconductor/Android-nRF-Connect-Device-Manager#migration-from-the-original-repo).

# nRF Connect Device Manager

![Swift](https://img.shields.io/badge/Swift-5.10-f05237.svg)
![Platforms](https://img.shields.io/badge/Platforms-iOS%20|%20iPadOS%20|%20macOS-333333.svg)
[![License](https://img.shields.io/github/license/NordicSemiconductor/IOS-nRF-Connect-Device-Manager)](https://github.com/NordicSemiconductor/IOS-nRF-Connect-Device-Manager/blob/master/LICENSE)
[![Release](https://img.shields.io/github/release/NordicSemiconductor/IOS-nRF-Connect-Device-Manager.svg)](https://github.com/NordicSemiconductor/IOS-nRF-Connect-Device-Manager/releases)
[![Swift Package Manager](https://img.shields.io/badge/SwiftPM-Compatible-brightgreen)](https://swift.org/package-manager/)
[![CocoaPods](https://img.shields.io/badge/CocoaPods-Compatible-brightgreen)](https://cocoapods.org/)

nRF Connect Device Manager library is compatible with [McuManager (or McuMgr for short)](https://docs.zephyrproject.org/3.2.0/services/device_mgmt/mcumgr.html#overview) and [SUIT (shorthand for Software Update for the Internet of Things)](). McuManager is a management subsystem supported by [nRF Connect SDK](https://developer.nordicsemi.com/nRF_Connect_SDK/doc/latest/nrf/index.html), [Zephyr](https://docs.zephyrproject.org/3.2.0/introduction/index.html) and Apache Mynewt. McuManager relies on its own [MCUboot](https://docs.mcuboot.com/) bootloader for secure bootstrapping after a firmware update and, uses the [Simple Management Protocol, or SMP](https://docs.zephyrproject.org/3.2.0/services/device_mgmt/smp_protocol.html), for communication over Bluetooth LE. The SMP Transport definition for Bluetooth Low Energy, which this library implements, [can be found here](https://docs.zephyrproject.org/latest/services/device_mgmt/smp_transport.html).

SUIT and McuManager are related, but not interchangeable. SUIT relies on its own bootloader, but communicates over the SMP Service. Additionally, SUIT supports some functionalities from McuManager, but is not guaranteed to do so. It's best to always check if a McuManager feature is supported by sending the request, rather than assuming it is.

The library provides a transport agnostic implementation of the McuManager protocol. It contains a default implementation for BLE transport.

> Minimum required iOS version is 12.0, originally released in Fall of 2018.

> [!Warning]  
> This library, the default & main API for Device Firmware Update by Nordic Semiconductor, **should not be confused with the previous protocol, NordicDFU**, serviced by the [Old DFU Library](https://github.com/NordicSemiconductor/IOS-DFU-Library).

## Compatible Devices

| nRF52 Series | nRF53 Series | nRF54 Series | nRF91 Series |
| :---: | :----: | :---: | :---: |
| ![](nRF52-Series-small.png) | ![](nRF53-Series-small.png) | ![](nRF54-Series-small.png) | ![](nRF91-Series-small.png) |

This library is designed to work with the SMP Transport over BLE. It is implemented and maintained by Nordic Semiconductor, but it should work any devices communicating via SMP Protocol. **If you encounter an issue communicating with a device using any chip, not just Nordic, please file an Issue**.

## Library Adoption into an Existing Project (Install)

### SPM or Swift Package Manager (Recommended)

In Xcode, open your root Project file. Then, switch to the *Package Dependencies* Tab, and hit the *+* button underneath your list of added Packages. A new modal window will pop-up. On the upper-right corner of this new window, there's a search box. Paste the URL for this GitHub project `https://github.com/NordicSemiconductor/IOS-nRF-Connect-Device-Manager` and the *Add Package* button should enable.

![](xcode-add-package.png)

After Xcode fetches your new project dependency, you should now be able to add `import iOSMcuManagerLibrary` to the Swift files from where you'd like to call upon this library. And you're good to go.

### CocoaPods

```
pod 'iOSMcuManagerLibrary'
```

## Building the Example Project (Requires Xcode & CocoaPods)

### "Cocoapods?"

Not to worry, we have you covered. Just [follow the instructions here](https://guides.cocoapods.org/using/getting-started.html).

### Instructions

First, clone the project:

```shell
git clone https://github.com/NordicSemiconductor/IOS-nRF-Connect-Device-Manager.git
```

Then, open the project's directory, navigate to the *Example* folder, and run `pod install`:

```shell
cd IOS-nRF-Connect-Device-Manager/
cd Example/
pod install
```

The output should look similar to this:

```shell
Analyzing dependencies
Downloading dependencies
Installing SwiftCBOR (0.4.4)
Installing ZIPFoundation (0.9.11)
Installing iOSMcuManagerLibrary (1.3.1)
Generating Pods project
Integrating client project
Pod installation complete! There are 2 dependencies from the Podfile and 3 total pods installed.
```

You should now be able to open, build & run the Example project by opening the *nRF Connect Device Manager.xcworkspace* file:

```shell
open nRF\ Connect\ Device\ Manager.xcworkspace
```

# Introduction

McuManager is an application layer protocol used to manage and monitor microcontrollers running Apache Mynewt and Zephyr. More specifically, McuManager implements over-the-air (OTA) firmware upgrades, logs, stats, file-system and configuration management. Devices running SUIT as their bootloader might respond to McuManager commands, but it is not guaranteed.

## Command Groups

McuManager is organized by functionality into command groups. In _mcumgr-ios_, command groups are called managers and extend the `McuManager` class. The managers (groups) implemented in _mcumgr-ios_ are:

* **`DefaultManager`**: Contains commands relevant to the OS. This includes task and memory pool statistics, device time read & write, and device reset.
* **`ImageManager`**: Manage image state on the device and perform image uploads.
* **`StatsManager`**: Read stats from the device.
* **`SettingsManager`**: Read/Write config values on the device.
* **`LogManager`**: Collect logs from the device.
* **`CrashManager`**: Run crash tests on the device.
* **`RunTestManager`**: Runs tests on the device.
* **`FileSystemManager`**: Download/upload files from the device file system.
* **`BasicManager`**: Send 'Erase App Settings' command to the device.
* **`ShellManager`**: Send McuMgr Shell commands to the device.
* **`SuitManager`**: Send SUIT (Software Update for Internet of Things)-specific commands to the device. This applies to devices running SUIT as their bootloader.

> [!CAUTION]
> **Always make your API calls from the Main Thread**. For DFU, FileSystem, etc. Unless calls from background threads are explicitly mentioned as allowed. This requirement has its roots in programming invariants written into the library since its *Inception*.
> 
> **We will crash if we catch you to alert you of the issue as soon as possible.**

# Firmware Upgrade

Firmware upgrade is generally a four step process performed using commands from the `image` and `default` commands groups: `upload`, `test`, `reset`, and `confirm`.

This library provides `FirmwareUpgradeManager` as a convenience for upgrading the image running on a device. `FirmwareUpgradeManager` will forward McuMgr/McuBoot-specific commands to `ImageManager`, or redirect them to `SuitManager` if a SUIT upgrade procedure (such as the upload being a SUIT Envelope) is detected.

## FirmwareUpgradeManager

`FirmwareUpgradeManager` provides an easy way to perform firmware upgrades on a device. A `FirmwareUpgradeManager` must be initialized with an `McuMgrTransport` which defines the transport scheme and device. Once initialized, `FirmwareUpgradeManager` can perform one firmware upgrade at a time. Firmware upgrades are started using the `start(package: McuMgrPackage)` function and can be paused, resumed, and canceled using `pause()`, `resume()`, and `cancel()` respectively.

> [!TIP]
> You may reuse a `FirmwareUpgradeManager` / `McuMgrTransport` combo for multiple operations. But it is recommended to make a new pair for each operation. For example, for each DFU attempt. Nevertheless, we will provide support (and fixes) for issues stemming from keeping the same pair for multiple operations.

### McuMgrPackage API

```swift
import iOSMcuManagerLibrary

do {
    // Initialize the BLE transport using a scanned peripheral
    let bleTransport = McuMgrBleTransport(cbPeripheral)

    // Initialize the FirmwareUpgradeManager using the transport and a delegate
    let dfuManager = FirmwareUpgradeManager(bleTransport, delegate)

    let packageURL = /* Obtain URL to the file user wants to Upload */
    let package = try McuMgrPackage(from: packageURL)

    // Start the firmware upgrade with the given package
    dfuManager.start(package: package)
} catch {
    // Package initialisation errors here.
}
```

This is our new, improved, all-conquering API. You create a `McuMgrPackage`, and you give it to the `FirmwareUpgradeManager`. [There's no Step Three](https://www.youtube.com/watch?v=A0QK0JfHzhg&pp). This API supports:

- [x] .bin file(s)
  - [x] (Single-Core nRF52xxx) MCUboot Application Update
  - [x] (Bare Metal nRF54xx) MCUboot Update
- [x] .suit file(s) (~~Canonical nRF54xx)~~ SUIT Update
- [x] .zip file(s)
  - [x] DirectXIP (nRF52840) MCUboot Upgrade
  - [x] Multi-Image (Application Core, Network Core nRF5340) MCUboot Update
  - [x] Multi-Image (Polling - Resources Required nRF54xx) SUIT Update
- [ ] Custom Uploads

This is the API you should be using 99% of the time, unless you want to do something specific. For example, you want to unpack your own package, and upload only certain images / resources for specific cores, which is very rare.

Have a look at `FirmwareUpgradeViewController.swift` from the Example project for a more detailed usage sample.

### Custom Multi-Image Upload Example

```swift
public class ImageManager: McuManager {
    
    public struct Image {
        public let name: String?
        public let image: Int
        public let slot: Int
        public let content: McuMgrManifest.File.ContentType
        public let hash: Data
        public let data: Data

        /* ... */
    }
}
```

The above is the input type for Image-based API call, where a value of `0` for the `image` parameter means **App Core**, and an input of `1` means **Net Core**. These representations were originally intended for McuMgr/MCUboot based products, and not SUIT. In SUIT, there's no concept of 'image' or 'slot', so they're ignored. But to keep the same API reusable for McuMgr/MCUboot and SUIT devices, but we keep them for backwards compatibility. 

For McuMgr/MCUboot, you will typically want to set it the `slot` parameter to `1`, which is the alternate slot that is currently not in use for that specific core. Then, after upload, the firmware device will reset to swap over its slots, making the contents previously uploaded to slot `1` (now in slot `0` after the swap) as active, and vice-versa.

With the Image struct at hand, it's straightforward to make a call to start DFU for either or both cores:

```swift
import iOSMcuManagerLibrary

try {
    // Initialize the BLE transport using a scanned peripheral
    let bleTransport = McuMgrBleTransport(cbPeripheral)

    // Initialize the FirmwareUpgradeManager using the transport and a delegate
    let dfuManager = FirmwareUpgradeManager(bleTransport, delegate)

    // Build Multi-Image DFU parameters
    let appCoreData = try Data(contentsOf: appCoreFileURL)
    let appCoreDataHash = try McuMgrImage(data: appCoreData).hash
    let netCoreData = try Data(contentsOf: netCoreFileURL)
    let netCoreDataHash = try McuMgrImage(data: netCoreData).hash
    
    let images: [ImageManager.Image] = [
        (image: 0, slot: 1, hash: appCoreDataHash, data: appCoreData),
        (image: 1, slot: 1, hash: netCoreDataHash, data: netCoreData)
    ]

    // Start Multi-Image DFU firmware upgrade
    dfuManager.start(images: images)
} catch {
    // Errors here.
}
```

### DirectXIP Provision

Whereas non-DirectXIP packages target the secondary / non-active slot, also known as slot `1` for each `ImageManager.Image`, special attention must be given to DirectXIP packages. Since they provide multiple hashes for the same `ImageManager.Image`, one for each available slot. This is because firmware supporting DirectXIP can boot from either slot, not requiring a swap. So, for DirectXIP the `[ImageManager.Image]` array might look closer to:

```swift
import iOSMcuManagerLibrary

try {
    /*
    Initialise transport & manager as above.
    */

    // Build DirectXIP parameters
    let appCoreSlotZeroData = try Data(contentsOf: appCoreSlotZeroURL)
    let appCoreSlotZeroHash = try McuMgrImage(data: appCoreSlotZeroData).hash
    let appCoreSlotOneData = try Data(contentsOf: appCoreSlotOneURL)
    let appCoreSlotOneHash = try McuMgrImage(data: appCoreSlotOneData).hash
    
    let directXIP: [ImageManager.Image] = [
        (image: 0, slot: 0, hash: appCoreSlotZeroHash, data: appCoreSlotZeroData),
        (image: 0, slot: 1, hash: appCoreSlotOneHash, data: appCoreSlotOneData)
    ]
    
    // Start DirectXIP Firmware Upgrade
    dfuManager.start(images: directXIP)
} catch {
    // Errors here.
}
```

### Multi-Image DFU Format

Usually, when performing Multi-Image DFU, and even SUIT updates, the delivery format of the attached images for each core will be in a `.zip` file. This is because the `.zip` file allows us to bundle the necessary information, including the images for each core and which image should be uploaded to each core. This association between the image files, usually in `.bin` format, and which core they should be uploaded to, is written in a mandatory JSON format called the Manifest. This `manifest.json` is generated by our nRF Connect SDK as part of our Zephyr build system, [as documented here](https://developer.nordicsemi.com/nRF_Connect_SDK/doc/latest/nrf/app_dev/build_and_config_system/index.html). You can look at the `McuMgrManifest` struct definition within the library for an insight into the information contained within the manifest.

To bridge the gap between the Custom Image Upload API and the output from our Zephyr build system, we wrote `McuMgrPackage`, which takes a `URL` in its `init()` function. Because of the JSON Manifest Parsing nature of the `McuMgrPackage` method, you might encounter corner cases / crashes. If you find these, please report them back to us. But regardless, the McuMgrPackage shortcut is a wrapper that initialises the aforementioned `[ImageManager.Image]` array API. So you can always fallback to that.

### Tell me about SUIT

SUIT, unlike McuManager, places a lot of the logic (read: blame) for firmware update onto the target device rather than the sender (aka 'you', the API user). This simplifies the internal process, but also makes parsing the raw Data and its contents much more complicated. For example, we can't ascertain the proper Hash signature of every component (file) sent to the firmware because rather than a fixed binary for each Slot or Core, SUIT is designed to represent a sequence of instructions for the bootloader to execute. This means the hashes for the final binaries to be flashed change on-the-fly during the firmware update on the target device's end.

From the sender's perspective, we only need to send "the Data" in full, and allow the target to figure things out. This pack of bytes represents what we call the SUIT Envelope, which is the sequence of instructions for the firmware to run, akin to the code we write before feeding it into a compiler. These instructions might require other files outside the Envelope itself, known as resources, which will be requested via API Callback. These resources are usually part of a `.zip` package that includes the SUIT Envelope and a Manifest file derivative from McuManager's. 

> [!NOTE]  
> **Resources don't need to have a valid Hash attached to them** since, as explained above, only the target device knows the proper Hash. **But the Envelope's Hash is required**, and it supports different Modes, also known as Types or Algorithms. The list of SUIT Algorithms includes SHA256, SHAKE128, SHA384, SHA512 and SHAKE256. Of these, the **only currently supported mode is SHA256**.

Here's sample code in case you'd like to set up a SUIT upgrade using the `ImageManager.Image` API:

```swift
import iOSMcuManagerLibrary

do {
    // Initialize the BLE transport using a scanned peripheral
    let bleTransport = McuMgrBleTransport(cbPeripheral)

    // Initialize the FirmwareUpgradeManager using the transport and a delegate
    let dfuManager = FirmwareUpgradeManager(bleTransport, delegate)

    // Parse McuMgrSuitEnvelope from File URL
    let envelope = try McuMgrSuitEnvelope(from: dfuSuitEnvelopeUrl)

    // Look for valid Algorithm Hash 
    guard let sha256Hash = envelope.digest.hash(for: .sha256) else {
        throw McuMgrSuitParseError.supportedAlgorithmNotFound
    }

    let suitImage = ImageManager.Image(image: 0, hash: sha256Hash, data: envelope.data)
    try dfuManager.start(images: [suitImage])
} catch {
    // Handle errors from McuMgrSuitEnvelope init, start() API call, etc.
}
```

#### SuitFirmwareUpgradeDelegate

The delegate type you usually give `FirmwareUpgradeManager` is `FirmwareUpgradeDelegate`. This will cover any needs for McuMgr/McuBoot upgrades, as well as the 'Canonical' variant of SUIT, meaning only the Envelope needs to be sent. However, when the upgrade file is a `.zip` file, there might be additional resources, such as files, that the target firmware might request. When this happens, a `SuitFirmwareUpgradeDelegate`, an extension of `FirmwareUpgradeDelegate`, is required. `SuitFirmwareUpgradeDelegate` adds a new function to inform you of when a resource is needed. Most of the time, the requested resource will be part of the `.zip` package, so it'll be a very simple implementation. Here's an example:

```swift

func uploadRequestsResource(_ resource: FirmwareUpgradeResource) {
    let image: ImageManager.Image! = package?.image(forResource: resource)
    firmwareUpgradeManager.uploadResource(resource, data: image.data)
}
```

### Firmware Upgrade Mode

McuManager firmware upgrades can be performed following slightly different procedures. These different upgrade modes determine the commands sent after the `upload` step. `FirmwareUpgradeManager` can be configured to perform these upgrade variations by setting the `upgradeMode` in `FirmwareUpgradeManager`'s `configuration` property, explained below. (NOTE: this was previously set with `mode` property of `FirmwareUpgradeManager`, now removed) The different firmware upgrade modes are as follows:

* **`.confirmOnly`**: This mode is **the default mode**, due to its support for almost any type of DFU variant (Single Image, Multi-Image, Direct XIP, SUIT, etc.). It is in fact, the only supported mode for any form of Multi-Image DFU. However, there is one big caveat to keep in mind: this mode does not support any form of automatic error recovery. So, **if the device fails to boot into the new image, it will not be able to recover and will need to be re-flashed**. The process for this mode is `upload`, `confirm`, `reset`.

* **`.testAndConfirm`**: This mode is the **recommended, but not default mode** for performing upgrades due to it's ability to recover from a bad firmware upgrade. **It is no longer set as the default, due to it only being fully supported in Single Image DFU Mode**. The process for this mode is `upload`, `test`, `reset`, `confirm`.

* **`.testOnly`**: This mode is useful if you want to run tests on the new image running before confirming it manually as the primary boot image. The process for this mode is `upload`, `test`, `reset`.

* **`.uploadOnly`**: This is a very particular mode. It does not listen or acknowledge Bootloader Info, and plows through the upgrade process with just `upload` followed by `reset`. That's it. **It is up to the user, since this is not a default, to decide this is the right mode to use**.

### Firmware Upgrade State

`FirmwareUpgradeManager` acts as a simple, mostly linear state machine which is determined by the `mode`. As the manager moves through the firmware upgrade process, state changes are provided through the `FirmwareUpgradeDelegate`'s `upgradeStateDidChange` method.

`FirmwareUpgradeManager` contains an additional state, `validate`, which precedes the upload. The `validate` state checks the current image state of the device in an attempt to bypass certain states of the firmware upgrade. For example, if the image to upgrade to already exists in slot 1 on the device, `FirmwareUpgradeManager` will skip `upload` and move directly to `test` (or `confirm` if `.confirmOnly` mode has been set) from `validate`. If the uploaded image is already active, and confirmed in slot 0, the upgrade will succeed immediately. In short, the `validate` state makes it easy to reattempt an upgrade without needing to re-upload the image or manually determine where to start.

### Firmware Upgrade Configuration

In version 1.2, new features were introduced to speed-up the Upload speeds, mirroring the work first done on the Android side, and they're all available through the new `FirmwareUpgradeConfiguration` struct.

* **`pipelineDepth`**: (Represented as 'Number of Buffers' in the Example App UI.) For values larger than 1, this enables the **SMP Pipelining** feature. It means multiple write packets are sent concurrently, thereby providing a large speed increase the higher the number of buffers the receiving device is configured with. Set to `1` (Number of Buffers = Disabled) by default.

* **`byteAlignment`**: This was required for firmware built using nRF Connect SDK version 1.7 or older for SMP Pipelining. By fixing the size of each chunk of Data sent for the Firmware Upgrade, we can predict the receiving device's offset jumps and therefore smoothly send multiple Data packets at the same time. When SMP Pipelining is not being used (`pipelineDepth` set to `1`), the library still performs Byte Alignment if set, but it is not required for updates to work. Set to `ImageUploadAlignment.disabled` by default. [nRF Connect SDK 1.7](https://docs.nordicsemi.com/bundle/ncs-3.0.0/page/nrf/releases_and_maturity/releases/release-notes-1.7.0.html) dates back to [September 2021](https://github.com/nrfconnect/sdk-nrf/releases/tag/v1.7.0), so if your firmware is newer, there's no need to change the default.

* **reassemblyBufferSize**: SMP Reassembly is another speed-improving feature. It works on devices running NCS 2.0 firmware or later, and is self-adjusting. Before the Upload starts, a request is sent via `DefaultManager` asking for MCU Manager Paremeters. If received, it means the firmware can accept data in chunks larger than the MTU Size, therefore also increasing speed. This property will reflect the size of the buffer on the receiving device, and the `McuMgrBleTransport` will be set to chunk the data down within the same Sequence Number, keeping each packet transmission within the MTU boundaries. **There is no work required for SMP Reassembly to work** - on devices not supporting it, the MCU Manager Paremeters request will fail, and the Upload will proceed assuming no reassembly capabilities. **Must not be larger than UInt16.max (65535)**

* **`eraseAppSettings`**: This is not a speed-related feature. Instead, setting this to `true` means all app data on the device, including Bond Information, Number of Steps, Login or anything else are all erased. If there are any major data changes to the new firmware after the update, like a complete change of functionality or a new update with different save structures, this is recommended. Set to `false` by default.

* **`upgradeMode`**: Firmware Upgrade Mode. See Section above for an in-depth explanation of all possible Upgrade Modes.

* **`bootloaderMode`**: The Bootloader Mode is not necessarily intended to be a setting. It behaves as a setting if the target firmware does not offer a valid response to Bootloader Info request, for example, if it's not supported. What it does is inform iOSMcuMgrLibrary of the supported operations by the Bootloader. For example, if `upgradeMode` is set to `confirmOnly` but the Bootloader is in DirectXIP with no Revert mode, sending a Confirm command will be returned with an error. Which means, no Confirm command will be sent, despite the `upgradeMode` being set so. So yes, it's yet another layer of complexity from SMP / McuManager we have to deal with.

#### Configuration Example

[This is the way](https://www.youtube.com/watch?v=uelA7KRLINA) to start DFU with your own custom `FirmwareUpgradeConfiguration`:

```swift
import iOSMcuManagerLibrary

// Setup
let bleTransport = McuMgrBleTransport(cbPeripheral)
let dfuManager = FirmwareUpgradeManager(bleTransport, delegate)

// Non-Pipelined Example
let nonPipelinedConfiguration = FirmwareUpgradeConfiguration(
    estimatedSwapTime: 10.0, eraseAppSettings: false, pipelineDepth: 2,
)
dfuManager.start(package: package, using: nonPipelinedConfiguration)

// Pipelined Example
let pipelinedConfiguration = FirmwareUpgradeConfiguration(
    estimatedSwapTime: 10.0, eraseAppSettings: true, pipelineDepth: 4,
    byteAlignment: .fourByte
)
dfuManager.start(package: package, using: pipelinedConfiguration)
```

# SMP Server

SMP stands for Simple Management Protocol, or SMP, Server. SMP Server supports multiple command groups, of while file system / management is one of. More information is available in the [Zephyr SMP Server Sample Application documentation](https://docs.zephyrproject.org/latest/samples/subsys/mgmt/mcumgr/smp_svr/README.html).

## FileSystemManager

`FileSystemManager` provides an interface for the file management command group of Zephyr's SMP Server. That is, mainly, to provide file upload and file download capabilities. 

The easiest way to begin working with FileSystemManager, is to create a [smp_svr sample application](https://github.com/nrfconnect/sdk-zephyr/tree/v4.0.99-ncs1/samples/subsys/mgmt/mcumgr/smp_svr/), for example, using the [nRF Connect for VS Code Extension](https://www.nordicsemi.com/Products/Development-tools/nRF-Connect-for-VS-Code). You can then create a new Build Configuration for the development platform of your convenience.

### Upload Example

```swift
import iOSMcuManagerLibrary

// Setup
let bleTransport = McuMgrBleTransport(cbPeripheral)
bleTransport.logDelegate = UIApplication.shared.delegate as? McuMgrLogDelegate
let fsManager = FileSystemManager(transport: bleTransport)

// Parameters
let fileData: Data = // File Contents
let mountingPoint: String = "/lfs1" // Default. May vary depending on your specific setup.
let fileName: String = mountingPoint + "/" + "example.txt"
let uploadDelegate: FileUploadDelegate = // FileUploadDelegate

// Non-Pipelined (Default Configuration) Example
let didUploadStart = fsManager.upload(name: fileName, data: fileData, delegate: uploadDelegate)

// Pipelined Example
var pipelinedConfiguration = FirmwareUpgradeConfiguration()
pipelinedConfiguration.pipelineDepth = 4 // Equivalent to CONFIG_MCUMGR_TRANSPORT_NETBUF_COUNT=4 in firmware KConfig files.
let didUploadStart = fsManager.upload(name: fileName, data: fileData, using: pipelinedConfiguration, delegate: uploadDelegate)
```

### Download Example

> [!NOTE]
> Reassembly works automagically for downloads, since SMP Server supports it since its original release. As long as the sender (SMP Server Device) does the right thing in its packet header, the same logic in `McuMgrBleTransport` that handles Reassembly for DFU and File Uploads will work.

```swift
import iOSMcuManagerLibrary

// Setup
let bleTransport = McuMgrBleTransport(cbPeripheral)
bleTransport.logDelegate = UIApplication.shared.delegate as? McuMgrLogDelegate
let fsManager = FileSystemManager(transport: bleTransport)

// Parameters
let fileData: Data = // File Contents
let mountingPoint: String = "/lfs1" // Default. May vary depending on your specific setup.
let fileName: String = mountingPoint + "/" + "example.txt"
let downloadDelegate: FileDownloadDelegate = // FileDownloadDelegate
let downloadStarted = fsManager.download(name: destination, delegate: downloadDelegate)

// FileDownloadDelegate {
    
    func download(of name: String, didFinish data: Data) {
        // Downloaded file's contents are in @data parameter
    }
    
    func downloadProgressDidChange(bytesDownloaded: Int, fileSize: Int, timestamp: Date) {
        /* ... */
    }
    
    func downloadDidFail(with error: Error) {
        /* ... */
    }
    
    func downloadDidCancel() {
        /* ... */
    }
}
 
```

# Logging

Setting `logDelegate` property in a manager gives access to low level logs, that can help debugging both the app and your device. Messages are logged on 6 log levels, from `.debug` to `.error`, and additionally contain a `McuMgrLogCategory`, which identifies the originating component. Additionally, the `logDelegate` property of `McuMgrBleTransport` provides access to the BLE Transport logs.

### Example

```swift
import iOSMcuManagerLibrary

// Initialize the BLE transport using a scanned peripheral
let bleTransport = McuMgrBleTransport(cbPeripheral)
bleTransport.logDelegate = UIApplication.shared.delegate as? McuMgrLogDelegate

// Initialize the DeviceManager using the transport and a delegate
let deviceManager = DeviceManager(bleTransport, delegate)
deviceManager.logDelegate = UIApplication.shared.delegate as? McuMgrLogDelegate

// Send echo
deviceManger.echo("Hello World!", callback)
```

### OSLog integration

`McuMgrLogDelegate` can be easily integrated with the [Unified Logging System](https://developer.apple.com/documentation/os/logging). An example is provided in the example app in the `AppDelegate.swift`. A `McuMgrLogLevel` extension that can be found in that file translates the log level to one of `OSLogType` levels. Similarly, `McuMgrLogCategory` extension converts the category to `OSLog` type.

# Related Projects

We've heard demand from developers for a single McuMgr DFU library to target multiple platforms. So we've made available [a Flutter library](https://pub.dev/packages/mcumgr_flutter) that acts as a wrapper for both Android and iOS.
