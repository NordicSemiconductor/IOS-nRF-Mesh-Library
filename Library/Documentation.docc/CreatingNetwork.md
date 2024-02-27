# Creating and loading a network configuration

How to load or create a network.

## Overview

The mesh configuration may be loaded from the ``Storage``, provided in the manager's initializer.
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

Each time the network is modified, for example a new key is added, the configuration has to be saved
using ``MeshNetworkManager/save()``. When a Configuration message is received, either a Status message
sent as a response to a request, or a request sent from another node, the configuration is saved 
automatically.

## What's next

Now, with the mesh network manager and network set up we can provision a device: <doc:Provisioning>,
or connect to the network using a GATT Proxy node: <doc:Connecting>.
