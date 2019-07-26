# nRFMeshProvision version 2

## About

This is the second version of the nRF Mesh Provision library for iOS. It is still under development and many features are not supported.
However, all implemented features should work and are tested againt nRF Mesh SDK 3.1 and Zephyr based mesh device.

The first version of this library is no longer maintained. The application available on App Store will eventually be replaced with the new sample
application.

## Supported features

1. Provisionig with all features that available in Bluetooth Mesh Profile 1.0.1, including OOB Public Key and all types of OOB.
2. Managing Provisioners, Network Keys, Application Keys, resetting network, etc.
3. All network layers are working.
4. Parsing Secure Network beacons.
5. Adding, removing and refreshing Network and Application Keys to Nodes.
6. Binging and unbinding Application Keys to Models.
7. Setting and clearing publication to a Model.
8. Setting and removing subscriptions to a Model.
9. Groups, including those with Virtual Addresses (without sending messages to them).

## NOT (yet) supported features

1. Vendor models and SIG defined models, except from supported ones.
2. UI for controlling groups.
3. Handling Configuration Server message sent by other Provisioner.
4. Proxy Filter.
5. Key Refresh Procedure.

## Feedback

Any feedback is more than welcome. Please, test the app, test the library and check out the API.

## Requirements

* Xcode 10.2.1 or newer
* An iOS device with BLE capabilities

## Optional

* nrf52832 or nrf52840 based Development Kit(s) to test the sample firmwares on.

## Installation

* Open `Example/nRFMeshProvision.xcworkspace`
* Connect an iOS Device.
* Build and run project.
* To be able to quickly start testing, use the bundled firmwares directory named `ExampleFirmwares` that includes a light server (Light source) and a light client (Switch) firmwares. those firmwares will work on a `nrf52832` DevKit.

## License

BSD 3-Clause License 
