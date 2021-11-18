# nRF Mesh for iOS
[![GitHub license](https://img.shields.io/github/license/NordicSemiconductor/IOS-nRF-Mesh-Library)](https://github.com/NordicSemiconductor/IOS-nRF-Mesh-Library/blob/master/LICENSE)
[![Version](http://img.shields.io/cocoapods/v/nRFMeshProvision.svg)](http://cocoapods.org/pods/nRFMeshProvision)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![SwiftPM Compatible](https://img.shields.io/badge/SwiftPM-compatible-brightgreen)](https://swift.org/package-manager/)

The nRF Mesh Provision library allows to provision and exchange messages to Bluetooth mesh devices. 

> Bluetooth mesh specifications may be found [here](https://www.bluetooth.com/specifications/specs/?status=active&show_latest_version=0&show_latest_version=1&keyword=mesh&filter=).

The library is compatible with 
- **Bluetooth Mesh Profile 1.0.1**, 
- **Mesh Model 1.0.1**, 
- **Mesh Device Properties 2**.

The mesh network configuration (JSON) is compatible with 
- **Mesh Configuration Database Profile 1.0**.

All features are tested against *nRF5 SDK for Mesh* and *nRF Connect SDK* based mesh devices.

> The version 1.x and 2.x of this library are no longer maintained. Please migrate to 3.x to get new features and bug fixes. 
For changes and migration details see [#295](https://github.com/NordicSemiconductor/IOS-nRF-Mesh-Library/pull/295).

## Sample app

The sample application demonstrates how to use the library. It may also be used to configure your Mesh network. 
Use `pod try` to install and set up the sample app when using CocoaPods.
The app and the library are released under BSD-3 license. Feel free to modify them as you want.

The app is available on App Store: https://apps.apple.com/us/app/nrf-mesh/id1380726771

## Supported features

The library supports great majority of features from Bluetooth Mesh 1.0.1 specification:

1. Provisioning with all features available in Bluetooth Mesh Profile 1.0.1, including OOB Public Key 
   and all types of OOB, using GATT bearer.
2. Configuration, including managing keys, publications, subscription, and hearbeats (both as client and server).
3. Support for client and server models.
4. Groups, including those with virtual labels.
5. Scenes (both as client and server).
6. Managing proxy filter.
7. IV Index update (handled by Secure Network beacons).
8. [Key Refresh Procedure](https://github.com/NordicSemiconductor/IOS-nRF-Mesh-Library/pull/314) 
   (using *ConfigKeyRefreshPhaseSet* messages, not Secure Network beacon). 
9. Hearbeats (both as client and server).
10. Exporting network state with format compatible to 
    [Configuration Database Profile 1.0](https://www.bluetooth.com/specifications/specs/mesh-configuration-database-profile-1-0/), 
    including partial export.
11. Option to use own transport layer with default GATT Bearer implementation available.

Most of the features are demonstrated in the sample app nRF Mesh:

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
   - Vendor models.
8. Scenes, both as client and server.
9. Automatic connection to nearby nodes and automatic proxy filter management.

## NOT (yet) supported features

The following features are not (yet) supported:

1. The rest of models defined by Bluetooth SIG - PRs are welcome!
2. IV Index update (initiation) - not a top priority, as other nodes may initiate the update.
3. Health server messages - in our TODO list.
4. Remote provisioning - in our TODO list.
5. Device Firmware Update (DFU) - in our TODO list.

## Documentation

The documentation for this library may be found [here](Documentation/README.md).

## Requirements

* Xcode 12 or newer.
* An iOS 10.0 or newer device with BLE capabilities.

## Optional

* nrf5 based Development Kit(s) to test the sample firmwares.

## Feedback

Any feedback is more than welcome. Please, test the app, test the library and check out the API.

## License

BSD 3-Clause License.
