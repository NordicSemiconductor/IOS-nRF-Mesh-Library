# Device Firmware Update

Updating the firmware of mesh nodes over-the-air (OTA).

## Overview

The Bluetooth Mesh specification defines DFU starting with 
[**Mesh Device Firmware Update Model v1.0**](https://www.bluetooth.com/specifications/specs/mesh-device-firmware-update-model/).

### Roles

Three roles participate in a firmware update over a Bluetooth mesh network:

- **Initiator**: Initiates the firmware update process.
- **Distributor**: Receives the firmware and distributes it to Target Nodes.
- **Target Node**: Receives and applies the firmware update. 

A node may perform multiple roles simultaneously — for example, a node can act as both an Initiator and a Distributor.

### Firmware Transfer

According to the Mesh DFU specification, there are two methods by which a Distributor can receive the firmware image before distributing it to Target Nodes:

1. **BLOB Transfer** from the Initiator.
2. **Out-of-Band (OOB)** download via HTTPS or other external sources.

While BLOB Transfer is used for distributing firmware from the Distributor to Target Nodes, it is relatively slow and therefore not suitable for transferring firmware to the Distributor itself.

The second method relies on the Distributor's ability to download the firmware from the Internet or other external sources.

#### Simple Management Protocol (SMP)

In **nRF Mesh**, a proprietary method using **Simple Management Protocol (SMP)** is employed to transfer firmware from the Initiator to the Distributor. This method is fast and leverages a direct GATT connection instead of Mesh messages.

On the device side, it uses the [Management subsystem](https://docs.nordicsemi.com/bundle/ncs-latest/page/zephyr/services/device_mgmt/mcumgr.html) with the *Image* and *Shell* groups:

- **Image group**: Transfers the firmware image.
- **Shell group**: Creates image slots for the firmware.

The app uses the [nRF Connect Device Manager](https://github.com/NordicSemiconductor/IOS-nRF-Connect-Device-Manager/) library to manage SMP transfers.

> Note: It is recommended to secure the SMP Service on the Distributor using the
[**LE Pairing Responder**](https://docs.nordicsemi.com/bundle/ncs-latest/page/nrf/libraries/bluetooth/mesh/vnd/le_pair_resp.html)
vendor model by Nordic Semiconductor. This model provides a Passkey over mesh messages to bond the phone with the Distributor node,
ensuring that only clients with the correct Network and Application Keys can access the service.
> 
> See more in the [SMP over Bluetooth authentication](https://docs.nordicsemi.com/bundle/ncs-latest/page/nrf/samples/bluetooth/mesh/dfu/distributor/README.html#smp_over_bluetooth_authentication) documentation.

## Process

#### 1. Bind models to an Application Key

Ensure the following models are bound to a selected Application Key:

- `Firmware Distributor Server` on the Distributor
- `Firmware Update Client` on the Distributor
- `BLOB Transfer Client` on the Distributor
- `LE Pairing Responder` on the Distributor (if applicable)
- `Firmware Update Server` on each Target Node
- `BLOB Transfer Server` on each Target Node

#### 2. Connect to the Distributor as a GATT Proxy

Ensure that the Distributor has the **GATT Proxy** feature enabled.

Currently, the only supported way to transfer firmware to the Distributor is via the **SMP Service**. This service can be verified by scanning available GATT services using `CBCentralManager` and checking for the [SMP Service](https://docs.nordicsemi.com/bundle/ncs-latest/page/zephyr/services/device_mgmt/smp_transport.html).

> Note: If the SMP Service requires authentication, enabling notifications may trigger a bonding process.  
Before enabling notifications, read the value from the LE Pairing Responder model and present the received **Passkey** to the user.

#### 3. Read Distribution Capabilities and Status

Send ``FirmwareDistributionCapabilitiesGet`` and ``FirmwareDistributionGet`` messages to the Distributor to query its capabilities and current state.

This step is optional but recommended to ensure the Distributor is ready and has sufficient storage space.

#### 4. Select Target Nodes and Validate Firmware Metadata

Prepare the firmware image and validate it using the `FirmwareUpdateFirmwareMetadataCheck` message.

This validation ensures the firmware is compatible with the selected Target Nodes. It also returns the
[**effect**](https://docs.nordicsemi.com/bundle/ncs-latest/page/zephyr/connectivity/bluetooth/api/mesh/dfu.html#firmware_effect) 
of the update, including whether a node may be unprovisioned post-update (see ``FirmwareUpdateFirmwareMetadataStatus/additionalInformation``).

#### 5. Add Receivers

Send the ``FirmwareDistributionReceiversAdd`` message to the Distributor with the list of Target Nodes.

If necessary, clear previous receivers first by sending ``FirmwareDistributionReceiversDeleteAll``.

#### 6. Create a Slot for the Firmware Image

Use the Distributor's **Shell group** over SMP to add a firmware slot:

```swift
let transport = McuMgrBleTransport(gattBearer.identifier)
let shellManager = ShellManager(transport: transport)
shellManager.logDelegate = self

shellManager.execute(command: "mesh models dfu slot add \(image.data.count) \(firmwareId) \(metadata)") { response, error in
    if let text = response?.output,
       let match = text.range(of: #"Index:\s*(\d+)"#, options: .regularExpression),
       let number = Int(String(text[match]).components(separatedBy: ":").last?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "") {
        let slot = UInt16(truncatingIfNeeded: number)
        // Use this slot index in the next step.
    }
}
```

> Note: This is the only step requiring the Shell interface. If the image is sent via BLOB Transfer (not SMP), the slot is created automatically.

#### 7. Upload the Firmware Image

Upload the firmware using the Image Manager:

```swift
let imageManager = ImageManager(transport: transport)
imageManager.logDelegate = self
_ = imageManager.upload(images: [image], using: config, delegate: callback)
```

Refer to [`DFUViewController`](https://github.com/NordicSemiconductor/IOS-nRF-Mesh-Library/blob/main/Example/Source/View%20Controllers/Network/DFU/DFUViewController.swift) 
in the sample app for a usage example.

#### 8. Start Firmware Distribution

Initiate distribution by sending the ``FirmwareDistributionStart`` message, including the `slot` index from step 6 and other DFU parameters.

#### 9. Apply the Firmware (if verify-only was set)

If the update policy was set to ``FirmwareUpdatePolicy/verifyOnly``, send ``FirmwareDistributionApply`` to apply the firmware after a successful transfer.
