# Provisioning

Provisioning is the process of adding an unprovisioned device to a mesh network in a secure way. 

## Overview

The provisioner, in a secure way, assigns a Unicast Address and sends the Network Key to the device.
Knowing the key, the new device, now called a Node, can exchange mesh messages with other nodes.

> To provision a new device, the provisioner does not need to have an address assigned. Having a
  Unicast Address makes the provisioner a configuration manager node.

A configuration manager may configure nodes after they have been provisioned. 
Configuration messages are sent between *Configuration Client* model on the manager 
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

> Important: nRF Mesh library supports PB GATT Bearer and PB Remote Bearer. 
  PB Adv Bearer is not supported. 

To provision a device which does not support PB GATT Bearer a ``PBRemoteBearer`` must be used.
A node supporting *Remote Provisioning Server* model must be provisioned and in range of the
unprovisioned device. All provisioning messages will be sent via that node.

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
try provisioningManager.provision(usingAlgorithm:       .BTM_ECDH_P256_HMAC_SHA256_AES_CCM,
                                  publicKey:            ...,
                                  authenticationMethod: ...)
```
The ``ProvisioningDelegate`` should be used to provide OOB (Out Of Band) information.
