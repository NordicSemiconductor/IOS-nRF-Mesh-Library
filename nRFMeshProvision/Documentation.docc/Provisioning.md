# Provisioning

Provisioning is the process of adding an unprovisioned device to a mesh network in a secure way. 

## Overview

The provisioner, in a secure way, assigns a Unicast Address and sends the Network Key to the device.
Knowing the key, the new device, now called a Node, can exchange mesh messages with other nodes.

> To provision a new device, the provisioner does not need to have an address assigned. Having a
  Unicast Address makes the provisioner a node.

A provisioner with a Unicast Address assigned may also configure nodes after they have been
provisioned. Configuration messages are sent between *Configuration Client* model on the provisioner 
and *Configuration Server* model on the target device, and, on the Upper Transport layer, are encrypted 
using the node's Device Key, generated during provisioning.

To provision a new device, use ``MeshNetworkManager/provision(unprovisionedDevice:over:)``.
```swift
let provisioningManager = try meshNetworkManager.provision(
    unprovisionedDevice: unprovisionedDevice, 
    over: bearer
)
provisioningManager.delegate = ...
provisioningManager.logger = ...
```

The ``UnprovisionedDevice`` and ``PBGattBearer`` instances may be created from the 
Bluetooth LE scan result. 
```swift
func centralManager(_ central: CBCentralManager, 
                    didDiscover peripheral: CBPeripheral,
                    advertisementData: [String : Any], rssi RSSI: NSNumber) {
    if let unprovisionedDevice = UnprovisionedDevice(advertisementData: advertisementData) {
        let bearer = PBGattBearer(target: peripheral)
        bearer.logger = ...
        bearer.delegate = ...
        bearer.open()
    }
}
```

> Important: Provisioning of new devices using the current version of the nRF Mesh library 
  supports only with the use of GATT PB Bearer, i.e. remote provisioning is not supported. 
  New devices must support GATT PB Bearer in order to be provisioned using a mobile device.
  This also applies to the nRF Mesh library for Android.

Provisioning process is initiated by calling ``ProvisioningManager/identify(andAttractFor:)``
```swift
try provisioningManager.identify(andAttractFor: 2 /* seconds */)
```
followed by ``ProvisioningManager/provision(usingAlgorithm:publicKey:authenticationMethod:)``.
```swift
// Optional:
provisioningManager.address = ...    // Defaults to the next available address.
provisioningManager.networkKey = ... // Defaults to the Primary Network Key.
// Start:
try provisioningManager.provision(usingAlgorithm:       .fipsP256EllipticCurve,
                                  publicKey:            ...,
                                  authenticationMethod: ...)
```
The ``ProvisioningDelegate`` should be used to provide OOB (Out Of Band) information.
