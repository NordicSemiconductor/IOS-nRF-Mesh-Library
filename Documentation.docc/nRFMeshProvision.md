# ``nRFMeshProvision``

Provision, configure and control Bluetooth mesh devices with nRF Mesh library.

## Overview

The nRF Mesh library allows to provision Bluetooth mesh devices into a mesh network, configure 
them and send and receive messages.

The library is compatible with the following [Bluetooth specifications](https://www.bluetooth.com/specifications/specs/?status=active&show_latest_version=0&show_latest_version=1&keyword=mesh&filter=):
- Mesh Profile 1.0.1
- Mesh Model 1.0.1
- Mesh Device Properties 2
- Configuration Database Profile 1.0.0

> Important: Implementing ADV Bearer on iOS is not possible due to API limitations. 
  The library is using GATT Proxy protocol, specified in the Bluetooth Mesh Profile 1.0.1,
  and requires a Node with Proxy functionality to relay messages to the mesh network.

## Usage

The ``MeshNetworkManager`` is the main entry point for interacting with the mesh network.
Use it to create, load or import a Bluetooth mesh network and send messages. 

The snippet below demostrates how to start.

```swift
// Create the Mesh Network Manager instance.
meshNetworkManager = MeshNetworkManager()

// Customize manager parameters, or use the default values if you don't know how.
meshNetworkManager.defaultTtl = ...
meshNetworkManager.incompleteMessageTimeout = ...
meshNetworkManager.acknowledgmentTimerInterval = ...
meshNetworkManager.transmissionTimerInterval = ...
meshNetworkManager.retransmissionLimit = ...
meshNetworkManager.acknowledgmentMessageTimeout = ...
meshNetworkManager.acknowledgmentMessageInterval = ...
// If you know what you're doing, customize the advanced parameters.
meshNetworkManager.allowIvIndexRecoveryOver42 = ...
meshNetworkManager.ivUpdateTestMode = ...

// For debugging, set the logger delegate.
meshNetworkManager.logger = ...
```

The mesh configuration may be loaded from the ``Storage``, provided in the manager constructor.
```swift
let loaded = try meshNetworkManager.load()
```
If no configuration exists, this method will return `false`. In that case either create 
a new configuration, as shown below, or import an existing one from a file.
```swift
_ = meshNetworkManager.createNewMeshNetwork(
       withName: "My Network", 
       by: "My Provisioner"
)
// Make sure to save the network in the Storage.
_ = meshNetworkManager.save()
```

The manager is transport agnostic. In order to send messages, the ``MeshNetworkManager/transmitter`` 
property needs to be set to a ``Bearer`` instance. The bearer is responsible for sending the messages
to the mesh network. Messages received from the bearer must be delivered to the manager using 
``MeshNetworkManager/bearerDidDeliverData(_:ofType:)``. 

> Tip: To make the integration with ``Bearer`` easier, the manager instance can be set as Bearer's 
       ``Bearer/dataDelegate``. The nRF Mesh library includes ``GattBearer`` class, which implements 
       the ``Bearer`` protocol.

```swift
let bearer = GattBearer(target: peripheral)
bearer.delegate = ...

// Cross set the delegates.
bearer.dataDelegate = meshNetworkManager
meshNetworkManager.transmitter = bearer

// To get the logs from the bearer, set the logger delegate to the bearer as well.
bearer.logger = ...

// Open the bearer. The GATT Bearer will initiate Bluetooth LE connection.
bearer.open()
```

## Local Node

The mobile application using nRF Mesh library itself is a mesh node, called the local node.
The library automatically supports the following models: 
- *Configuration Server* (required for all nodes)
- *Configuration Client* (for configuring nodes)
- *Health Server* (required for all nodes)
- *Health Client*
- *Scene Client* (for controlling scenes)

and may be extended to support user defined models.

The elements on the local node must be configured using ``MeshNetworkManager/localElements`` property.
Each model declared in this array must have a ``ModelDelegate`` implemented, which maps the
Op Codes of supported messages to their types, and defines the behavior of the model. 
For example, a model delegate can specify that it can handle messages with an Op Code *0x8204*, 
which should be decoded to ``GenericOnOffStatus`` type.

```swift
// Mind, that the first Element will contain the models mentioned above.
let primaryElement = Element(name: "Primary Element", location: .first, 
        models: [
            // Generic OnOff Client model:
            Model(sigModelId: .genericOnOffClientModelId, 
                  delegate: GenericOnOffClientDelegate()),
            // A simple vendor model:
            Model(vendorModelId: .simpleOnOffModelId,
                  companyId: .nordicSemiconductorCompanyId,
                  delegate: SimpleOnOffClientDelegate())
        ]
)
meshNetworkManager.localElements = [primaryElement]
```

> Important: Even if your implementation does not add any models to the default set, it is required to
  set the ``MeshNetworkManager/localElements``. It can be set to an empty array.

The model delegate is notified when a message targetting the model is received if, and only if, the model 
is bound to the Application Key used to encrypt the message and is subscribed to its destination 
address.

> Tip: The ``MeshNetworkDelegate``, set in the manager, is notified about every message 
  received. This includes messages targeting models that are not configured to receive messages, 
  i.e. not bound to any key, or not subscribed to the address set as destination address of the 
  message. If a received message cannot be mapped to any message type (i.e. no local model 
  supports the op code of received message), it will be decoded as ``UnknownMessage``.

> See `Example/nRFMeshProvision/AppDelegate.swift` in "nRF Mesh" sample app for an example.

## Configuration

Use ``MeshNetworkManager/sendToLocalNode(_:)`` to configure the local node. The ``ConfigMessage``s
will be handled by the *Configuration Server* model automaticaly by the library.

To configure the remote nodes, use ``MeshNetworkManager/send(_:to:withTtl:)-77r3r``. 
The bearer needs to be configured in the network manager, like described in the `Usage` section.

Status messages for configuration messages are delivered using
``MeshNetworkDelegate/meshNetworkManager(_:didReceiveMessage:sentFrom:to:)`` to the 
``MeshNetworkManager/delegate``.

The updated state of the mesh network is automaticaly saved in the ``Storage``. 

> Important: As the nRF Mesh library supports *Configuration Server* model, it also allows 
             other provisioners to remotely reconfigure the local node when it is connected to a Proxy node.
             For example, the phone can be remotely removed from network. To avoid it being removed, do not 
             share the Device Key of the local node when exporting network configuration.

## Sending messages

The nRF Mesh library supports sending messages in two ways:
1. From models on the local node, that are configured for publishing.
2. Directly.

The first method closely follows Bluetooth Mesh Profile specification, but is quite complex.
A model needs to be bound to an Application Key using ``ConfigModelAppBind`` message
and have a publication set using ``ConfigModelPublicationSet`` or 
``ConfigModelPublicationVirtualAddressSet``. With that set, calling 
``ModelDelegate/publish(using:)`` or ``ModelDelegate/publish(_:using:)`` will trigger a publication
from the model to a destination specified in the ``Publish`` object. Responses will be delivered
to ``ModelDelegate/model(_:didReceiveResponse:toAcknowledgedMessage:from:)`` of the model delegate.

The second method does not require setting up local models. 
Use ``MeshNetworkManager/send(_:from:to:withTtl:using:)-2qajr`` or other variants of this method to send 
a message to the desired destination.

> All methods used for sending messages in the ``MeshNetworkManager`` are asynchronous.

## Provisioning

Provisioning is the process of adding an unprovisioned device to a mesh network. The provisioner,
in a secure way, assigns a Unicast Address and sends the Network Key to the device.
Knowing the key, the new device, now called a node, can exchange config messages with other nodes.

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

## Exporting network configuration

The mesh network configuration can be exported using ``MeshNetworkManager/export(_:)`` to
a JSON file, complient with 
 [Bluetooth Mesh Configuration Database specification](https://www.bluetooth.com/specifications/specs/mesh-configuration-database-profile-1-0/). 
The ``ExportConfiguration`` allows exporting partial configuration.

For example, in the typical Guest scenario, a house owner may only want to share set of
devices without their Device Keys, preventing them from being reconfigured. In order to do
that, a new Guest Network Key and set of Application Keys bound to it can be created
and exported to the guest. The keys should be sent to the desired nodes.
Before exporting, the owner may create a new ``Provisioner`` object with limited allocated 
ranges, disallowing the guest to provision more devices.
After the guest moves out, the keys can be changed or removed from the devices.

## Topics

### Mesh Network Manager

Mesh network manager is the main entry point for the mesh network. It manages the network, 
allows sending and processing messages to and from bearers and initializes 
provisioning procedure.

- ``MeshNetworkManager``
- ``MeshNetworkDelegate``
- ``Storage``
- ``LocalStorage``
- ``ExportConfiguration``
- ``MessageHandle``

- ``MeshNetworkError``
- ``LowerTransportError``
- ``AccessError``

### Logging

- ``LoggerDelegate``
- ``LogLevel``
- ``LogCategory``

### Bearers

- ``Bearer``
- ``BearerError``
- ``BearerDelegate``
- ``BearerDataDelegate``
- ``Transmitter``
- ``MeshBearer``
- ``ProvisioningBearer``
- ``PduType``
- ``PduTypes``

### GATT Bearers

- ``GattBearer``
- ``PBGattBearer``
- ``GattBearerDelegate``
- ``GattBearerError``
- ``BaseGattProxyBearer``

- ``ProxyProtocolHandler``

- ``MeshService``
- ``MeshProvisioningService``
- ``MeshProxyService``

### Provisioning

- ``UnprovisionedDevice``
- ``ProvisioningManager``
- ``ProvisioningDelegate``
- ``ProvisioningState``
- ``ProvisioningCapabilities``
- ``ProvisioningError``
- ``RemoteProvisioningError``
- ``AuthAction``
- ``PublicKey``
- ``PublicKeyType``
- ``Algorithm``
- ``Algorithms``
- ``OobInformation``
- ``AuthenticationMethod``
- ``OutputAction``
- ``OutputOobActions``
- ``InputAction``
- ``InputActionValueGenerator``
- ``InputOobActions``
- ``StaticOobType``

### Mesh Network

- ``MeshNetwork``
- ``Node``
- ``Element``
- ``MeshElement``
- ``Model``
- ``Location``
- ``Provisioner``
- ``RangeObject``
- ``Publish``

### Models

- ``ModelDelegate``
- ``SceneServerModelDelegate``
- ``StoredWithSceneModelDelegate``
- ``TransactionHelper``
- ``ModelError``

### Keys

- ``NetworkKey``
- ``ApplicationKey``
- ``Security``
- ``Key``
- ``KeyIndex``
- ``KeyRefreshPhase``
- ``KeyRefreshPhaseTransition``

### Addresses

- ``MeshAddress``
- ``Address``
- ``Group``
- ``AddressRange``

### Scenes

- ``SceneNumber``
- ``Scene``
- ``SceneRange``

### Node features

- ``NodeFeature``
- ``NodeFeatureState``
- ``NodeFeatures``
- ``NodeFeaturesState``

### Message Types

- ``BaseMeshMessage``

- ``MeshMessageSecurity``

- ``MeshMessage``
- ``AcknowledgedMeshMessage``
- ``StaticMeshMessage``
- ``StaticAcknowledgedMeshMessage``
- ``StatusMessage``

- ``VendorMessage``
- ``AcknowledgedVendorMessage``
- ``StaticVendorMessage``
- ``AcknowledgedStaticVendorMessage``
- ``VendorStatusMessage``

- ``UnknownMessage``

### Configuration Message Types

- ``ConfigMessage``
- ``AcknowledgedConfigMessage``
- ``ConfigStatusMessage``
- ``ConfigMessageStatus``

- ``ConfigNetKeyMessage``
- ``ConfigAppKeyMessage``
- ``ConfigNetAndAppKeyMessage``
- ``ConfigElementMessage``
- ``ConfigModelMessage``
- ``ConfigAnyModelMessage``
- ``ConfigVendorModelMessage``
- ``ConfigAddressMessage``
- ``ConfigVirtualLabelMessage``
- ``ConfigModelAppList``
- ``ConfigModelSubscriptionList``

### Configuration Messages

- ``ConfigCompositionDataGet``
- ``ConfigCompositionDataStatus``
- ``CompositionDataPage``
- ``Page0``
- ``CompanyIdentifier``

- ``ConfigDefaultTtlGet``
- ``ConfigDefaultTtlSet``
- ``ConfigDefaultTtlStatus``

- ``ConfigBeaconGet``
- ``ConfigBeaconSet``
- ``ConfigBeaconStatus``

- ``ConfigFriendGet``
- ``ConfigFriendSet``
- ``ConfigFriendStatus``

- ``ConfigGATTProxyGet``
- ``ConfigGATTProxySet``
- ``ConfigGATTProxyStatus``

- ``ConfigLowPowerNodePollTimeoutGet``
- ``ConfigLowPowerNodePollTimeoutStatus``

- ``ConfigGATTProxyGet``
- ``ConfigGATTProxySet``
- ``ConfigGATTProxyStatus``

- ``ConfigNetworkTransmitGet``
- ``ConfigNetworkTransmitSet``
- ``ConfigNetworkTransmitStatus``

- ``ConfigNodeIdentityGet``
- ``ConfigNodeIdentitySet``
- ``ConfigNodeIdentityStatus``
- ``NodeIdentity``

- ``ConfigNodeReset``
- ``ConfigNodeResetStatus``

- ``ConfigRelayGet``
- ``ConfigRelaySet``
- ``ConfigRelayStatus``

### Configuration - Key Management Messages

- ``ConfigNetKeyGet``
- ``ConfigNetKeyAdd``
- ``ConfigNetKeyList``
- ``ConfigNetKeyUpdate``
- ``ConfigNetKeyDelete``
- ``ConfigNetKeyStatus``

- ``ConfigAppKeyGet``
- ``ConfigAppKeyAdd``
- ``ConfigAppKeyList``
- ``ConfigAppKeyUpdate``
- ``ConfigAppKeyDelete``
- ``ConfigAppKeyStatus``

- ``ConfigKeyRefreshPhaseGet``
- ``ConfigKeyRefreshPhaseSet``
- ``ConfigKeyRefreshPhaseStatus``

### Configuration - Key Binding Messages

- ``ConfigSIGModelAppGet``
- ``ConfigSIGModelAppList``
- ``ConfigVendorModelAppGet``
- ``ConfigVendorModelAppList``
- ``ConfigModelAppBind``
- ``ConfigModelAppUnbind``
- ``ConfigModelAppStatus``

### Configuration - Publication Messages

- ``ConfigModelPublicationGet``
- ``ConfigModelPublicationSet``
- ``ConfigModelPublicationVirtualAddressSet``
- ``ConfigModelPublicationStatus``

- ``ConfigSIGModelSubscriptionGet``
- ``ConfigSIGModelSubscriptionList``
- ``ConfigVendorModelSubscriptionGet``
- ``ConfigVendorModelSubscriptionList``
- ``ConfigModelSubscriptionAdd``
- ``ConfigModelSubscriptionVirtualAddressAdd``
- ``ConfigModelSubscriptionOverwrite``
- ``ConfigModelSubscriptionVirtualAddressOverwrite``
- ``ConfigModelSubscriptionDelete``
- ``ConfigModelSubscriptionVirtualAddressDelete``
- ``ConfigModelSubscriptionDeleteAll``
- ``ConfigModelSubscriptionStatus``

### Configuration - Heartbearts

- ``HeartbeatPublication``
- ``HeartbeatSubscription``
- ``RemainingHeartbeatPublicationCount``
- ``RemainingHeartbeatSubscriptionPeriod``
- ``HeartbeatSubscriptionCount``
- ``ConfigHeartbeatPublicationGet``
- ``ConfigHeartbeatPublicationSet``
- ``ConfigHeartbeatPublicationStatus``
- ``ConfigHeartbeatSubscriptionGet``
- ``ConfigHeartbeatSubscriptionSet``
- ``ConfigHeartbeatSubscriptionStatus``

### Generic Message Types

- ``GenericMessage``
- ``AcknowledgedGenericMessage``
- ``GenericStatusMessage``
- ``GenericMessageStatus``
- ``TransactionMessage``
- ``TransitionMessage``
- ``TransitionStatusMessage``
- ``TransitionTime``
- ``StepResolution``

### Generic Messages

- ``GenericBatteryGet``
- ``GenericBatteryStatus``
- ``BatteryChargingState``
- ``BatteryIndicator``
- ``BatteryPresence``
- ``BatteryServiceability``
- ``GenericDefaultTransitionTimeGet``
- ``GenericDefaultTransitionTimeSet``
- ``GenericDefaultTransitionTimeSetUnacknowledged``
- ``GenericDefaultTransitionTimeStatus``
- ``GenericDeltaSet``
- ``GenericDeltaSetUnacknowledged``
- ``GenericLevelGet``
- ``GenericLevelSet``
- ``GenericLevelSetUnacknowledged``
- ``GenericLevelStatus``
- ``GenericMoveSet``
- ``GenericMoveSetUnacknowledged``
- ``GenericOnOffGet``
- ``GenericOnOffSet``
- ``GenericOnOffSetUnacknowledged``
- ``GenericOnOffStatus``
- ``GenericOnPowerUpGet``
- ``GenericOnPowerUpSet``
- ``GenericOnPowerUpSetUnacknowledged``
- ``GenericOnPowerUpStatus``
- ``OnPowerUp``
- ``GenericPowerDefaultGet``
- ``GenericPowerDefaultSet``
- ``GenericPowerDefaultSetUnacknowledged``
- ``GenericPowerDefaultStatus``
- ``GenericPowerLastGet``
- ``GenericPowerLastStatus``
- ``GenericPowerLevelGet``
- ``GenericPowerLevelSet``
- ``GenericPowerLevelSetUnacknowledged``
- ``GenericPowerLevelStatus``
- ``GenericPowerRangeGet``
- ``GenericPowerRangeSet``
- ``GenericPowerRangeSetUnacknowledged``
- ``GenericPowerRangeStatus``

### Lighting Messages

- ``LightCTLDefaultSet``
- ``LightCTLDefaultSetUnacknowledged``
- ``LightCTLDefaultStatus``
- ``LightCTLGet``
- ``LightCTLSet``
- ``LightCTLSetUnacknowledged``
- ``LightCTLStatus``
- ``LightCTLTDefaultGet``
- ``LightCTLTemperatureGet``
- ``LightCTLTemperatureRangeGet``
- ``LightCTLTemperatureRangeSet``
- ``LightCTLTemperatureRangeSetUnacknowledged``
- ``LightCTLTemperatureRangeStatus``
- ``LightCTLTemperatureSet``
- ``LightCTLTemperatureSetUnacknowledged``
- ``LightCTLTemperatureStatus``

- ``LightHSLDefaultGet``
- ``LightHSLDefaultSet``
- ``LightHSLDefaultSetUnacknowledged``
- ``LightHSLDefaultStatus``
- ``LightHSLGet``
- ``LightHSLHueGet``
- ``LightHSLHueSet``
- ``LightHSLHueSetUnacknowledged``
- ``LightHSLHueStatus``
- ``LightHSLRangeGet``
- ``LightHSLRangeSet``
- ``LightHSLRangeSetUnacknowledged``
- ``LightHSLRangeStatus``
- ``LightHSLSaturationGet``
- ``LightHSLSaturationSet``
- ``LightHSLSaturationSetUnacknowledged``
- ``LightHSLSaturationStatus``
- ``LightHSLSet``
- ``LightHSLSetUnacknowledged``
- ``LightHSLStatus``
- ``LightHSLTargetGet``
- ``LightHSLTargetStatus``

- ``LightLCLightOnOffGet``
- ``LightLCLightOnOffSet``
- ``LightLCLightOnOffSetUnacknowledged``
- ``LightLCLightOnOffStatus``
- ``LightLCModeGet``
- ``LightLCModeSet``
- ``LightLCModeSetUnacknowledged``
- ``LightLCModeStatus``
- ``LightLCOccupancyModeGet``
- ``LightLCOccupancyModeSet``
- ``LightLCOccupancyModeSetUnacknowledged``
- ``LightLCOccupancyModeStatus``
- ``LightLCPropertyGet``
- ``LightLCPropertySet``
- ``LightLCPropertySetUnacknowledged``
- ``LightLCPropertyStatus``

- ``LightLightnessDefaultGet``
- ``LightLightnessDefaultSet``
- ``LightLightnessDefaultSetUnacknowledged``
- ``LightLightnessDefaultStatus``
- ``LightLightnessGet``
- ``LightLightnessLastGet``
- ``LightLightnessLastStatus``
- ``LightLightnessLinearGet``
- ``LightLightnessLinearSet``
- ``LightLightnessLinearSetUnacknowledged``
- ``LightLightnessLinearStatus``
- ``LightLightnessRangeGet``
- ``LightLightnessRangeSet``
- ``LightLightnessRangeSetUnacknowledged``
- ``LightLightnessRangeStatus``
- ``LightLightnessSet``
- ``LightLightnessSetUnacknowledged``
- ``LightLightnessStatus``

### Scene Message Types

- ``SceneStatusMessage``
- ``SceneMessageStatus``

### Scene Messages

- ``SceneGet``
- ``SceneRecall``
- ``SceneRecallUnacknowledged``
- ``SceneRegisterGet``
- ``SceneRegisterStatus``
- ``SceneStore``
- ``SceneStoreUnacknowledged``
- ``SceneDelete``
- ``SceneDeleteUnacknowledged``
- ``SceneStatus``

### Sensor Types

- ``SensorMessage``
- ``AcknowledgedSensorMessage``
- ``SensorPropertyMessage``
- ``AcknowledgedSensorPropertyMessage``
- ``DeviceProperty``
- ``DevicePropertyCharacteristic``
- ``SensorDescriptor``
- ``SensorSamplingFunction``
- ``SensorCadence``
- ``SensorValue``

### Sensor Messages

- ``SensorCadenceGet``
- ``SensorCadenceSet``
- ``SensorCadenceSetUnacknowledged``
- ``SensorCadenceStatus``
- ``SensorColumnGet``
- ``SensorColumnStatus``
- ``SensorDescriptorGet``
- ``SensorDescriptorStatus``
- ``SensorGet``
- ``SensorSeriesGet``
- ``SensorSeriesStatus``
- ``SensorSettingGet``
- ``SensorSettingSet``
- ``SensorSettingSetUnacknowledged``
- ``SensorSettingStatus``
- ``SensorSettingsGet``
- ``SensorSettingsStatus``
- ``SensorStatus``

### Location Types

- ``Latitude``
- ``Longitude``
- ``Altitude``

- ``LocationMessage``
- ``AcknowledgedLocationMessage``
- ``LocationStatusMessage``

### Location Messages

- ``GenericLocationGlobalGet``
- ``GenericLocationGlobalSet``
- ``GenericLocationGlobalSetUnacknowledged``
- ``GenericLocationGlobalStatus``

### Time Types

- ``TaiTime``
- ``TimeMessage``

### Time Messages

- ``TimeGet``
- ``TimeSet``
- ``TimeStatus``
- ``TimeZoneGet``
- ``TimeZoneSet``
- ``TimeZoneStatus``

### Scheduler Types

- ``SchedulerRegistryEntry``
- ``SchedulerAction``
- ``SchedulerYear``
- ``SchedulerMonth``
- ``SchedulerDay``
- ``SchedulerDayOfWeek``
- ``SchedulerHour``
- ``SchedulerMinute``
- ``SchedulerSecond``
- ``Month``
- ``WeekDay``

### Scheduler Messages

- ``SchedulerGet``
- ``SchedulerStatus``
- ``SchedulerActionGet``
- ``SchedulerActionSet``
- ``SchedulerActionSetUnacknowledged``
- ``SchedulerActionStatus``

### Proxy Filter

In order to reduce the number of Network PDUs exchanged between a Proxy Client and a 
Proxy Server, a proxy filter can be used. 

- ``ProxyFilter``
- ``ProxyFilerType``
- ``ProxyFilterDelegate``
- ``ProxyFilterSetup``

### Proxy Filter Configuration Message Types

- ``ProxyConfigurationMessage``
- ``StaticProxyConfigurationMessage``
- ``AcknowledgedProxyConfigurationMessage``
- ``StaticAcknowledgedProxyConfigurationMessage``

### Proxy Filter Configuration Messages

- ``AddAddressesToFilter``
- ``RemoveAddressesFromFilter``
- ``SetFilterType``
- ``FilterStatus``

### Other

- ``DataConvertible``
