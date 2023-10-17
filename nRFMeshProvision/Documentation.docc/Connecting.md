# Connecting to mesh network

How to connect to the network via GATT Proxy node.

## Overview

The ``MeshNetworkManager`` is transport agnostic. In order to send messages, the ``MeshNetworkManager/transmitter`` 
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
```

Before the bearer can be used it needs to be open. For GATT Proxy bearer this means connecting
over to the node over GATT. All mesh messages will be sent to the proxy using a GATT *Mesh Proxy Service*
and will be relayed over ADV bearer to the network.
```swift
// Open the bearer. The GATT Bearer will initiate Bluetooth LE connection.
bearer.open()
```

## What's next

With the bearer open it's finally time to send mesh messages: <doc:SendingMessages>.
