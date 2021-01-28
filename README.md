# nRF Mesh for iOS

[![Version](http://img.shields.io/cocoapods/v/nRFMeshProvision.svg)](http://cocoapods.org/pods/nRFMeshProvision)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

## About

The nRF Mesh Provision library allows to provision and send messages to Bluetooth Mesh devices. 

> Bluetooth Mesh specification may be found here: https://www.bluetooth.com/specifications/mesh-specifications/

The library is compatible with version 1.0.1 of the Bluetooth Mesh Profile Specification.

This is the second version of the nRF Mesh Provision library for iOS. All  features are tested againt nRF Mesh SDK and Zephyr based mesh devices.

> The version 1.x and 2.x of this library are no longer maintained. Please migrate to 3.x to get new features and bug fixes. For changes and migration details see [#295](https://github.com/NordicSemiconductor/IOS-nRF-Mesh-Library/pull/295).

## Sample app

The sample application demonstrates how to use the library. It may also be used to configure your Mesh network. Use `pod try` to install and set up the sample app when using CocoaPods.
The app and the library are released under BSD-3 license. Feel free to modify them as you want.

The app is available on App Store: https://apps.apple.com/us/app/nrf-mesh/id1380726771

## Supported features

1. Provisionig with all features that available in Bluetooth Mesh Profile 1.0.1, including OOB Public Key and all types of OOB.
2. Managing Provisioners, Network Keys, Application Keys, resetting network, etc.
3. All network layers are working.
4. Parsing Secure Network beacons.
5. Adding, removing and refreshing Network and Application Keys to Nodes.
6. Binging and unbinding Application Keys to Models.
7. Setting and clearing publication to a Model.
8. Setting and removing subscriptions to a Model.
9. Groups, including those with Virtual Addresses.
10. UI for controlling groups (Generic OnOff and Generic Level (delta) are supported).
12. Handling Configuration Server messages sent by other Provisioner.
13. Generic OnOff and Vendor model have dedicated controls in sample app.
14. Proxy Filter.
15. IV Index update (handling updates received in Secure Network beacons).
16. Heartbeats (both as client and server).
17. Scenes (both as client and server).
18. Partial export (allows to export only part of the network, for example for a Guest).
19. [Key Refresh Procedure](https://github.com/NordicSemiconductor/IOS-nRF-Mesh-Library/pull/314) (using *ConfigKeyRefreshPhaseSet* messages, not Secure Network beacon) 

## NOT (yet) supported features

1. Many SIG defined models, except from supported ones.
2. IV Index update (initiation).
3. Health server messages.
4. Remote Provisioning.

## Documentation

The documentation for this library may be found [here](Documentation/README.md).

## Requirements

* Xcode 12 or newer.
* An iOS 10.0 or newer device with BLE capabilities.

## Optional

* nrf52832 or nrf52840 based Development Kit(s) to test the sample firmwares on.

## Feedback

Any feedback is more than welcome. Please, test the app, test the library and check out the API.

## License

BSD 3-Clause License 
