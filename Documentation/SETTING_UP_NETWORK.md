## Setting up Mesh Network

A newly created mesh network contains a single Provisioner (with address 0x0001) and a randomly generated 128-bit Primary Network Key. Usually, you need to create at least one Application Key and few more Provisioners.

### Network Keys

Network Keys define subnetworks in the network. For example, it is a common practice to create a Guest Network Key, send it to devices in a guest room and share it with your guest, so that your guests can control lighting in their room, but can't send messages to other devices in the house. Or, in a hotel, devices located in each room may have their own Network Keys, which is shared with guests. Devices may known more than one Network Key, so the landlord may send messages to all devices using the secret Primary Network Key. 

Use `network.add(networkKey:withIndex:name)` to create a new Network Key. By definition, the local Node knows all Network Keys in the network, as it's the Provisioner. You don't have to send this message to a local Node.

### Application Keys

In order to send any non-config messages, at least one Application Key must be defined. Each Application Key is bound to a single Network Key. Application Keys should be distributed per application. For example, it may not be a good idea to share the same Application Key that you use in locks with a cheap light bulb, which could be used to open the doors to a house. by separating locks and other sensitive areas from each other you make sure the messages sent encrypted using one key will not be decodable by Nodes that don't know this key.

Use `network.add(applicationKey:withIndex:name)` to create a new Application Key. By definition, the local Node knows all Application Keys in the network, as it's the Provisioner. You don't have to send this message to a local Node.

### Sharing keys

The provisioning process assigns a unique Unicast Address and a primary Network Key to a Node. Such Node may than be configured by a Provisioner that has a Unicast Address, that is that can send and receive messages to the network. Each configuration message is signed using any Network Key known to this device and the Device Key (known only to this device and Provisioners).

The first thing you have to do to after provisioning is reading **Composition Data**. Do this by sending *Config Composition Data Get* message with page 0. Composition data contains the information about the Node, and Elements and Models on the new device. The status message will automatically be applied to the Node when received.

The next step is to send other Network Keys, if needed, and Application Keys that this device needs to know. In theory, a key that has once been added can be deleted, but there is no guarantee that the Node will actually remove the key. The proper way of deleting the keys is by doing [Key Refresh Procedure](https://github.com/NordicSemiconductor/IOS-nRF-Mesh-Library/pull/314), which will distribute a new, updated key with the same index to all nodes except those that we want to remove from the subnetwork, and switch them to use the new key instead. The excluded device(s) will not be able to understand messages anymore even if it hasn't deleted the key, as the key has now been replaced and is no longer is use.

To send a Network Key to a device use `ConfigNetKeyAdd` message and to send an Application Key - `ConfigAppKeyAdd` message.

### Binding Models to Application Keys

When a Node has been given all required keys, its Models may now be configured. The first step to do is usually to bind Application Keys to Models. A Model (except from **Configuration Server** and **Configuration Client**) may only process messages encrypted with keys bound to it.

To bind an App Key to a Model use `ConfigModelAppBind`. This message may also be sent to a local Model. For example, if you want to visualize the state of a light, that can be controlled using a remote switch (**Generic OnOff Client**), you may have **Generic OnOff Server** on the phone, bound to the same Application Key as the set in the switch's Publication and subscribed to the same group address. When a switch is toggled, the message will be received by the local Model and propagated to the user. To bind a Model on a local Node, send the message just as if it was a remote Node. 

> Sending messages locally is asynchronous, just like sending them to a remote Node.

### Setting publication and subscription

A Model may be set to publish a message when its state changes, or to receive messages from other Models. For example, to configure a light switch to turn on a light, one of the **Generic OnOff Client** Models on the switch's Elements must be set to publish a message using one of the bound Application Keys to some address (Unicast, Group or Virtual). A light must be subscribed to the same address (if Group or Virtual address was used) and bound to the same Application Key. A light may also be configured to publish whenever its state changes.

To set a publication, use `ConfigModelPubilcationSet` or `ConfigModelPubilcationVirtualAddressSet`. To add a group address to subscribed addresses, use `ConfigModelSubscriptionAdd`, or `ConfigModelSubscriptionVirtualAddressAdd` for virtual address.

These messages may also be sent to local Models. For example, the Sample App contains 2 Elements, each with **Generic OnOff Client** and **Generic OnOff Server** that can be configured to send messages to each other.

After subscribing a local Model to a group or virtual address you have to add this address to the Proxy Filter.

### Scenes

Scenes may be used to restore a saved state of a device. Scene server models support two operations: storing and recalling a scene. To store a scene, first set the required device state. For example, turn the light on, set desired light color and brightness. Then send `SceneStore` message with a *scene number*. Upon calling `SceneRecall` message with the same *scene number*, the device will restore saved state.

The library natively supports Scene Client model, so it may send `SceneStore`, `SceneRecall` or `SceneDelete` messages. The sample app, additionally, supports Scene Server and Scene Setup Server models, which can be used to test Scene Clients on other devices. Generic OnOff Server and Generic Level Server models on the two Elements on the phone will behave accordingly to received messages. Mind that, on contrary to Configuration Server and Configuration Client, Scene models need to be bound to an App Key (one or more) and will receive only message sent with that App Key.

### Proxy Filter

When using GATT Proxy bearer, the connected mesh node acts as a proxy device and relays messages sent in the mesh network to the phone using proxy protocol. However, it needs to know which messages should it relay and which not. For example, a phone does not need to be informed about a message sent between a switch and a light, but should receive a status message for a message it has sent, or for a message sent to 0xFFFF address (All Nodes).

To let the proxy know to which addresses the phone is subscribed, it needs to configure the Proxy Filter. The Proxy Filter is empty on each connection to a proxy node. To control the filter, use `ProxyFilter` class.

Upon connection, the library will automatically subscribe to all Unicast Addresses of all local Elements, to all Group and Virtual Addresses that at least one local Model is subscribed to, and to All Nodes address. **However, it does not track the messages, so when a Model gets subscribed to another address, you have to add this address on your own.** Otherwise, you will not receive messages sent to this address until you reconnect to this proxy.

```swift
let proxyFilter = meshNetworkManager.proxyFilter
proxyFilter?.add(groups: [newGroup])
```

