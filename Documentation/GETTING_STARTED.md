## Getting Started

### Mesh Network Manager

`MeshNetworkManager` is the main object, which manages the mesh network. The manager is transport independent, that means it does not handle the Bluetooth Mesh communication on its own. Instead, there is a pair of methods that should be used for this purpose. To pass incoming data to the manager, call the `manager.bearerDidDeliverData(_,ofType)` method. The manager will call `trasmitter.send(_,ofType)` whenever a packet is needed to be sent to the mesh network. When using a Proxy protocol, the transport implementation must segment and reassembly packets.

```swift
let meshNetworkManager = MeshNetworkManager()
```
or
```swift
let meshNetworkManager = MeshNetworkManager(using: MyStorage(), queue: DispatchQueue.someQueue, delegateQueue: DispatchQueue.main)
```

### Manager Properties

After instantiating the `MeshNetworkManager` object, set up its properties.
The default values are set according to Bluetooth Mesh specification, but you may find modifying the values for your need. For example, when using a proxy with a long connection interval, there is no need to wait for a response for a shorted time than the interval. A library would try to repeat sending a packet assuming it hasn't been received. Have a look at `AppDelegate` in the Sample App for an example.

```swift
// Read properties documentation for details.
meshNetworkManager.acknowledgmentTimerInterval = 0.600
meshNetworkManager.transmissionTimerInteral = 0.600
meshNetworkManager.retransmissionLimit = 2
meshNetworkManager.acknowledgmentMessageInterval = 5.0
meshNetworkManager.acknowledgmentMessageTimeout = 40.0

meshNetworkManager.logger = self
```

### Creating, Loading or Importing a Mesh Network

Upon creation, the manager is not ready. One needs to create, load or import the mesh network. Creating a new network will generate an empty network with one `Provisioner` and a primary `NetworkKey`. Call `save()` to store the configuration in `Storage` provided. Calling `load()` will load the last used configuration from the `Storage`. `import(from)` will import a configuration from JSON file that is compatible among different platforms.

```swift
var loaded = false
do {
    loaded = try meshNetworkManager.load()
} catch {
    print(error)
}

// If load failed, create a new MeshNetwork.
if !loaded {
    createNewMeshNetwork() // See AppDelegate in Sample App
} else {
    meshNetworkDidChange() // See AppDelegate in Sample App
}
```

> After importing a mesh network, make sure to set a unique Provisioner as a local one. Each device (also a phone that has a provisioner role) must have a unique Unicast Address. If you have 3 users in your network and one of them has additionally an iPad, you need to have 4 Provisioners: one per each device.

### GATT Bearers

To make the most common use case (working with GATT Proxy Bearer) easier, the library contains a default implementation for the GATT Proxy and GATT Provisioning bearers, which handle the Proxy protocol. Use `GattBearer` and `PBGattBearer` respectivly. Set the manager as bearer's `dataDelegate` and the bearer object as manager's `transmitter`. 

```swift
let bearer = GattBearer(target: scannedPeripheral)
bearer.dataDelegate = meshNetworkManager
meshNetworkManager.transmitter = bearer

bearer.logger = self
bearer.open()
```

The Sample App provides additional logic on top of the bearer, which allows to connect to multiple proxy nodes at the same time, so that if one proxy disconnects, another one can be used immediately. This logic needs to be used with caution, as proxies can often be used only by a single connected client. By default the limit of concurrent connection is set to 1.

### Local Elements and Models

By default, the local Node (that is the Provisioner's Node) will have one Element with 4 Models:
* **Configuration Server**
* **Configuration Client**
* **Health Server**
* **Health Client**

If you want to send and receive any other messages beside Configuration Messages, you need to define a Model. For example, if you want to allow user to control switching ON and OFF lights in their homes using *Generic OnOff Set* messages, you need to have **Generic OnOff Client** model.

To set local elements, call `manager.localElements = [...]`. The 4 Models mentioned above will be added automatically to the first Element. Each local model must have a `ModelDelegate` that will handle incoming messages and provide mapping for opcodes of messages that such Model supports (receives).

For example, the **Generic OnOff Client** mentioned above may send *Generic OnOff Get*, *Generic OnOff Set*, *Generic OnOff Set Unacknowledged* and will receive *Generic OnOff Status*. The last, status message must be added to `messageTypes` map of the Model's delegate, so that when a message with its opcode is received, the library knows which message type to instantiate. If you support any Server model, your `ModelDelegate` must also reply to all acknowledged messages it can receive.

Without setting the local Model and specifying the message types, each message would be reported to the manager's delegate as `UnknownMessage`. 

```swift
let nordicCompanyId: UInt16 = 0x0059
let element = Element(name: "Primary Element", location: .unknown, models: [
    Model(sigModelId: 0x1001, delegate: GenericOnOffClientDelegate()),
    Model(vendorModelId: 0x0001, companyId: nordicCompanyId, delegate: SimpleOnOffDelegate())
])
meshNetworkManager.localElements = [element]
```

**Important:** Even if you don't have any Models (for example only want to allow Configuration Messages in the app) you have to set the `localElements` property. In that case the Configuration Server and Client Models will not be properly initialized and you will be getting `UnknownMessage` instead of proper Status message.

### Provisioning 

Provisioning is a process of sending a Network Key to a new Unprovisioned Device in a more or less secure way. During provisioning, a Provisioner and the new provisioned Node will generate a common secret that will work as Device Key. Using this key the Provisioner may send and data to the Node privately, so that only this device will be able to decode the message. The first data sent to Node are its unique Unicase Address and the Network Key.

To provision a device, scan for nearby Unprovisioned Devices (devices advertising with [Service UUID: 0x1827](https://www.bluetooth.com/specifications/gatt/services/)). When a device is found and selected by the user, create `UnprovisionedDevice(advertisingData:)` object and a `ProvisioningBearer` (currently only PB GATT bearer is supported by the library). For default bearer you may use `PBGattBearer` which implements `ProvisioningBearer` protocol. To start provisioning, call `manager.provision(unprovisionedDevice:over)`. This method returns a `ProvisioningManager`, an object that will help you provision the device.

First, call `identify(andAttractFor)` on the new manager to make the device blink or make noise. This will also request device capabilities. Set the Network Key and Unicast Address (the next available address is selected automatically) and, when the right device has been chosen, call `provision(usingAlgorithm:publicKey:authenticationMethod)` to start the provisioning process. A delegate will be informed when provisioning is complete to has failed.

```swift
guard let bearer = PBGattBearer(target: peripheral),
      let unprovisionedDevice = UnprovisionedDevice(advertisementData: advertisementData),
      let provisioningManager = try? manager.provision(unprovisionedDevice: unprovisionedDevice, over: bearer) else {
    return
}
provisioningManager.delegate = self
provisioningManager.networkKey = primaryNetworkKey
bearer.delegate = self
bearer.open()
```
Identification:
``` swift
do {
    try provisioningManager.identify(andAttractFor: 5) // Blink for 5 seconds
} catch {
    bearer.close()
}
```
Provisioning:
``` swift
do {
    try provisioningManager.provision(usingAlgorithm: .fipsP256EllipticCurve,
                                      publicKey: publicKey,
                                      authenticationMethod: authenticationMethod)
} catch {
    bearer.close()
}
```

See `ScannerTableViewController` and `ProvisioniongViewController` in the Sample App.

### Sending messages

The manager's API contains number of methods for sending mesh messages, which can be divided into 3 groups. First group allows to send `ConfigMessages` to a **Configuration Server** on a remote or local Node. Configuration messages are always signed using the device key and must be sent to a Unicase Address of the Primary Element of a Node. Second group allows to send other messages from any local Element to any remote or local Element, or a group or virtual address. These messages are signed using Application Key and will be delivered to all models on the Element with target Unicast Address or subscribed to the target group or virtual address, that have this Application Key bound. You may not send `ConfigMessages` using this set of methods. The third group, which contains just a single method `publish(_:fromModel:withTtl)` can be used to send publication from the local model.

Remember, that only the Nodes that know the Network Key with which a message is sent may relay the message. It is for example not possible to send a message over a Proxy connection signed with a Network Key not known to this Proxy Node.

```swift
meshNetworkManager.delegate = self
meshNetworkManager.send(message, to: targetModel)
```

Next: [Setting up mesh network >](SETTING_UP_NETWORK.md)