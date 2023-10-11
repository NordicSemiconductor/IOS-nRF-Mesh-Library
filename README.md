[![GitHub license](https://img.shields.io/github/license/NordicSemiconductor/IOS-nRF-Mesh-Library)](https://github.com/NordicSemiconductor/IOS-nRF-Mesh-Library/blob/master/LICENSE)
[![Version](http://img.shields.io/cocoapods/v/nRFMeshProvision.svg)](http://cocoapods.org/pods/nRFMeshProvision)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![SwiftPM Compatible](https://img.shields.io/badge/SwiftPM-compatible-brightgreen)](https://swift.org/package-manager/)

# Bluetooth® Mesh library for iOS

The nRF Mesh library allows to provision [Bluetooth® Mesh](https://www.bluetooth.com/learn-about-bluetooth/feature-enhancements/mesh/)
devices into a mesh network, configure them and send and receive messages.

The library is compatible with the following [Bluetooth specifications](https://www.bluetooth.com/specifications/specs/?types=adopted&keyword=mesh):
- Mesh Protocol 1.1 (backwards compatible with **Mesh Profile 1.0.1**)
- Mesh Model 1.1
- Mesh Device Properties 2
- Mesh Configuration Database Profile 1.0.1

See [documentation](https://nordicsemiconductor.github.io/IOS-nRF-Mesh-Library/documentation/nrfmeshprovision) for more information.

> **Note**
>
> Implementing ADV Bearer on iOS is not possible due to API limitations. The library is using *GATT Proxy protocol*, 
  specified in the Bluetooth Mesh Protocol 1.1, and requires a Node with Proxy feature to relay messages to the mesh network.

## Supported features

1. Provisioning with:
   - OOB[^1] Public Key (most secure)
   - Input and Output OOB
   - No OOB (insecure)
   - Enhanced security, added in Mesh Protocol 1.1
   - Remote Provisioning (requires a node with Remote Provisioning Server model to proxy provisioning messages)
2. Configuration, including managing keys, publications, subscription, and heartbeats (both as client and server).
3. Support for client and server models.
4. Groups, including those with virtual labels.
5. Scenes (both as client and server).
6. Managing proxy filter.
7. IV Index update (handled by Secure Network beacons).
8. [Key Refresh Procedure](https://github.com/NordicSemiconductor/IOS-nRF-Mesh-Library/pull/314) 
   (using *ConfigKeyRefreshPhaseSet* messages, not Secure Network beacon). 
9. Heartbeats (both as client and server).
10. Exporting network state with format compatible to 
    [Configuration Database Profile 1.0.1](https://www.bluetooth.com/specifications/specs/mesh-configuration-database-profile-1-0-1/), 
    including partial export.
11. Option to use own transport layer with default GATT Bearer implementation available.

[^1]: OOB - Out Of Band

### NOT (yet) supported features

The following features are not (yet) supported:

1. The rest of models defined by Bluetooth SIG - *PRs are welcome!**
2. IV Index update (initiation) - *not a top priority, as other nodes may initiate the update.*
3. Health server messages - *in our TODO list.*
4. Device Firmware Update (DFU) - *coming next!*

## How to start

The library is available using CocoaPods, SPM and Carthage. For details, check out [Setting up the library](SETTING_UP.md).

## nRF Mesh sample app

Most of the features listed above are demonstrated in nRF Mesh sample application.

Use `pod try` to install and set up the sample app when using CocoaPods.

The app is available on [App Store](https://apps.apple.com/us/app/nrf-mesh/id1380726771).

### Supported features

1. Provisioning with all available features.
2. Configuration of local and remote nodes. 
3. Managing network (provisioners, network and application keys, scenes), resetting and exporting configuration.
4. Managing groups, including those with virtual labels.
5. Sending group messages.
6. UI for local models, which include: 
   - Generic OnOff Client and Server,
   - Generic Level Client and Server,
   - Simple OnOff vendor model by Nordic.
7. Support for some server models:
   - Generic OnOff,
   - Generic Level,
   - Generic Power OnOff,
   - Generic Default Transition Time,
   - Vendor models.
8. Scenes, both as client and server.
9. Automatic connection to nearby nodes and automatic proxy filter management.

## Testing

All features are tested against nRF5 devices running [nRF5 SDK for Mesh](https://www.nordicsemi.com/Products/Development-software/nRF5-SDK-for-Mesh) 
and [nRF Connect SDK](https://www.nordicsemi.com/Products/Development-software/nRF-Connect-SDK) firmware.

## Requirements

* Xcode 13.3 or newer.
* An iOS 13.0 or newer device with BLE capabilities.

### Optional

* [nRF5 Development Kit(s)](https://www.nordicsemi.com/Products/Bluetooth-mesh/Development-hardware) for developing and testing firmware.

## Feedback

Any feedback is more than welcome. Please, test the app, test the library and check out the API.

Use [Issues](https://github.com/NordicSemiconductor/IOS-nRF-Mesh-Library/issues) to report a bug, or ask a question. We also encourage to submit 
[Pull Requests](https://github.com/NordicSemiconductor/IOS-nRF-Mesh-Library/pulls) with new features or bug fixes.

## License

BSD 3-Clause License.

## Acknowledgments

This product depends on [CryptoSwift](https://github.com/krzyzanowskim/CryptoSwift) software developed by "Marcin Krzyzanowski" (http://krzyzanowskim.com/).
