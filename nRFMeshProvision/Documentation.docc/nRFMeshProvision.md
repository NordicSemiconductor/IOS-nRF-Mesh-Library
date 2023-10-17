# ``nRFMeshProvision``

Provision, configure and control Bluetooth mesh devices with nRF Mesh library.

## Overview

The nRF Mesh library allows to provision Bluetooth mesh devices into a mesh network, configure 
them and send and receive messages.

The library is compatible with the following [Bluetooth specifications](https://www.bluetooth.com/specifications/specs/?types=adopted&keyword=mesh):
- **Mesh Protocol 1.1** (backwards compatible with **Mesh Profile 1.0.1**)
- **Mesh Model 1.1**
- **Configuration Database Profile 1.0.1**

and [**Mesh Device Properties**](https://www.bluetooth.com/specifications/device-properties/).

> Important: Implementing ADV Bearer on iOS is not possible due to API limitations. 
  The library is using GATT Proxy protocol, specified in the Bluetooth Mesh Protocol 1.1,
  and requires a Node with GATT Proxy feature to relay messages to the mesh network.

## First steps

To learn how to use the library, start here: <doc:Usage>.

## Topics

### Articles

- <doc:Usage>
- <doc:LocalNode>
- <doc:CreatingNetwork>
- <doc:Provisioning>
- <doc:Connecting>
- <doc:SendingMessages>
- <doc:Configuration>
- <doc:Exporting>

### Mesh Network Manager

Mesh network manager is the main entry point for the mesh network. It manages the network, 
allows sending and processing messages to and from bearers and initializes 
provisioning procedure.

- ``MeshNetworkManager``
- ``MeshNetworkDelegate``
- ``NetworkParameters``
- ``NetworkParametersProvider``
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

### Bearer

Bearers are objects responsible for delivering PDUs to remote nodes. Bluetooth mesh, among others. defines 
ADV Bearer and GATT Bearer. Due to API limitations on iOS the ADV Bearer is not available. An iPhone
can be connected to the mesh network using a GATT connection to a node with GATT Proxy feature. 

- ``Bearer``
- ``BearerError``
- ``BearerDelegate``
- ``BearerDataDelegate``
- ``Transmitter``
- ``MeshBearer``
- ``ProvisioningBearer``
- ``PduType``
- ``PduTypes``

### GATT Bearer

GATT Bearer is used when connecting to a node with GATT Proxy feature. It uses a GATT connection 
instead of Bluetooth advertising. Messages sent over that bearer need to be proxied to the network
using ADV Bearer by the GATT Proxy node.

- ``GattBearer``
- ``PBGattBearer``
- ``GattBearerDelegate``
- ``GattBearerError``
- ``BaseGattProxyBearer``

- ``ProxyProtocolHandler``

- ``MeshService``
- ``MeshProvisioningService``
- ``MeshProxyService``

### Remote Bearer

PB Remote Bearer allows to provision a device which does not support GATT Mesh Provisioning Service
via a node with Remote Provisioning Server model.

- ``PBRemoteBearer``

### Provisioning

Provisioning is the process of adding an unprovisioned device to a mesh network in a secure way. 

- ``UnprovisionedDevice``
- ``ProvisioningManager``
- ``ProvisioningDelegate``
- ``ProvisioningState``
- ``ProvisioningRequest``
- ``ProvisioningResponse``
- ``ProvisioningCapabilities``
- ``ProvisioningError``
- ``RemoteProvisioningError``
- ``AuthAction``
- ``PublicKey``
- ``PublicKeyMethod``
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
- ``OobType``

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

### Beacons

- ``NodeIdentity``
- ``PublicNodeIdentity``
- ``PrivateNodeIdentity``
- ``NetworkIdentity``
- ``PublicNetworkIdentity``
- ``PrivateNetworkIdentity``

### Message Types

- ``BaseMeshMessage``

- ``MeshMessageSecurity``

- ``MeshMessage``
- ``AcknowledgedMeshMessage``
- ``UnacknowledgedMeshMessage``
- ``MeshResponse``
- ``StaticMeshMessage``
- ``StaticAcknowledgedMeshMessage``
- ``StaticUnacknowledgedMeshMessage``
- ``StaticMeshResponse``
- ``StatusMessage``

- ``VendorMessage``
- ``AcknowledgedVendorMessage``
- ``UnacknowledgedVendorMessage``
- ``VendorResponse``
- ``StaticVendorMessage``
- ``StaticAcknowledgedVendorMessage``
- ``StaticUnacknowledgedVendorMessage``
- ``StaticVendorResponse``
- ``VendorStatusMessage``

- ``UnknownMessage``

### Configuration Message Types

- ``ConfigMessage``
- ``AcknowledgedConfigMessage``
- ``UnacknowledgedConfigMessage``
- ``ConfigResponse``
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
- ``NodeIdentityState``

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

### Configuration - Heartbeats

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

### Configuration - Private Beacons

- ``RandomUpdateIntervalSteps``

- ``PrivateBeaconGet``
- ``PrivateBeaconSet``
- ``PrivateBeaconStatus``
- ``PrivateGATTProxyGet``
- ``PrivateGATTProxySet``
- ``PrivateGATTProxyStatus``
- ``PrivateNodeIdentityGet``
- ``PrivateNodeIdentitySet``
- ``PrivateNodeIdentityStatus``

### Configuration - Segmentation and Reassembly

- ``SarReceiverGet``
- ``SarReceiverSet``
- ``SarReceiverStatus``
- ``SarTransmitterGet``
- ``SarTransmitterSet``
- ``SarTransmitterStatus``

### Remote Provisioning Message Types

- ``RemoteProvisioningMessage``
- ``AcknowledgedRemoteProvisioningMessage``
- ``UnacknowledgedRemoteProvisioningMessage``
- ``RemoteProvisioningResponse``
- ``RemoteProvisioningStatusMessage``
- ``RemoteProvisioningMessageStatus``
- ``RemoteProvisioningError``
- ``RemoteProvisioningScanState``
- ``RemoteProvisioningLinkState``
- ``RemoteProvisioningLinkCloseReason``
- ``RemoteProvisioningLinkStateMessage``
- ``AdTypes``
- ``AdStructure``
- ``NodeProvisioningProtocolInterfaceProcedure``

### Remote Provisioning Messages

- ``RemoteProvisioningScanGet``
- ``RemoteProvisioningScanStatus``
- ``RemoteProvisioningScanReport``
- ``RemoteProvisioningScanStart``
- ``RemoteProvisioningScanStop``
- ``RemoteProvisioningExtendedScanStart``
- ``RemoteProvisioningExtendedScanReport``
- ``RemoteProvisioningScanCapabilitiesGet``
- ``RemoteProvisioningScanCapabilitiesStatus``
- ``RemoteProvisioningLinkGet``
- ``RemoteProvisioningLinkStatus``
- ``RemoteProvisioningLinkReport``
- ``RemoteProvisioningLinkOpen``
- ``RemoteProvisioningLinkClose``
- ``RemoteProvisioningPDUSend``
- ``RemoteProvisioningPDUReport``
- ``RemoteProvisioningPDUOutboundReport``

### Generic Message Types

- ``TransactionMessage``
- ``TransitionMessage``
- ``TransitionStatusMessage``
- ``TransitionTime``
- ``StepResolution``
- ``RangeStatusMessage``
- ``RangeMessageStatus``

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

- ``SensorPropertyMessage``
- ``DeviceProperty``
- ``DevicePropertyCharacteristic``
- ``TimeExponential``
- ``ValidDecimal``
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
