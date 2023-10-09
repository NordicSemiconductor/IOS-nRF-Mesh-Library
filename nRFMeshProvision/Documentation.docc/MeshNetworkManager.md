# ``nRFMeshProvision/MeshNetworkManager``

The Mesh Network Manager is the main entry point for interacting with the mesh network.
Use it to create, load or import a Bluetooth mesh network and send messages. 

## Topics

### Local Elements

- ``localElements``
- <doc:LocalNode>

### Mesh Network

- ``meshNetwork``
- ``createNewMeshNetwork(withName:by:)-97wsf``
- ``createNewMeshNetwork(withName:by:)-2fqd1``
- ``isNetworkCreated``
- ``load()``
- ``save()``
- ``clear()``
- ``import(from:)``
- ``export()``
- ``export(_:)``
- <doc:Exporting>

### Delegates

- ``delegate``
- ``transmitter``
- ``logger``

### Provisioning

- ``provision(unprovisionedDevice:over:)``

### Publishing

- ``publish(_:from:)``

### Sending Messages (async)

- ``send(_:from:to:withTtl:using:)-48vjl``
- ``send(_:from:to:withTtl:using:)-8s58h``
- ``send(_:from:to:withTtl:)-69yab``
- ``send(_:from:to:withTtl:)-4meon``
- ``send(_:from:to:withTtl:)-8vfdy``
- ``send(_:from:to:withTtl:)-3piwi``
- ``send(_:to:withTtl:)-1ybmh``
- ``send(_:to:withTtl:)-2bthl``
- ``send(_:to:withTtl:)-5vcbr``
- ``send(_:to:withTtl:)-l73l``
- ``sendToLocalNode(_:)``

### Sending Messages (callbacks)

- ``send(_:from:to:withTtl:using:completion:)-46h4r``
- ``send(_:from:to:withTtl:using:completion:)-1iylo``
- ``send(_:from:to:withTtl:completion:)-4il73``
- ``send(_:from:to:withTtl:completion:)-512i4``
- ``send(_:from:to:withTtl:completion:)-4u387``
- ``send(_:from:to:withTtl:completion:)-713ia``
- ``send(_:to:withTtl:completion:)-55sng``
- ``send(_:to:withTtl:completion:)-9uy76``
- ``send(_:to:withTtl:completion:)-7cqf7``
- ``send(_:to:withTtl:completion:)-1xywq``
- ``sendToLocalNode(_:completion:)``
- ``cancel(_:)``

### Awaiting messages (async)

- ``waitFor(messageWithOpCode:from:to:timeout:)-6673k``
- ``waitFor(messageWithOpCode:from:to:timeout:)-6pbh``
- ``waitFor(messageFrom:to:timeout:)-24q2d``
- ``waitFor(messageFrom:to:timeout:)-22y1``
- ``messages(withOpCode:from:to:)-6y68g``
- ``messages(withOpCode:from:to:)-6pn3j``
- ``messages(from:to:)-564th``
- ``messages(from:to:)-2nxp4``

### Awaiting messages (callbacks)

- ``waitFor(messageWithOpCode:from:to:timeout:completion:)-6i2u4``
- ``waitFor(messageWithOpCode:from:to:timeout:completion:)-7ry4h``
- ``waitFor(messageFrom:to:timeout:completion:)-60mxr``
- ``waitFor(messageFrom:to:timeout:completion:)-4xe02``
- ``registerCallback(forMessagesWithOpCode:from:to:callback:)-otzg``
- ``registerCallback(forMessagesWithOpCode:from:to:callback:)-1i8hu``
- ``registerCallback(forMessagesFrom:to:callback:)-4pyhv``
- ``registerCallback(forMessagesFrom:to:callback:)-7axud``
- ``unregisterCallback(forMessagesWithOpCode:from:)-2pj32``
- ``unregisterCallback(forMessagesWithOpCode:from:)-9rbl0``
- ``unregisterCallback(forMessagesWithType:from:)-15wz4``
- ``unregisterCallback(forMessagesWithType:from:)-1g3i0``

### Bearer Callbacks

- ``bearerDidDeliverData(_:ofType:)``
- ``bearer(_:didDeliverData:ofType:)``

### Proxy Filter

- ``send(_:)``
- ``proxyFilter``

### Mesh Network Parameters

- ``networkParameters``
- ``NetworkParametersProvider``

### Advanced Configuration

- ``setSequenceNumber(_:forLocalElement:)``
- ``getSequenceNumber(ofLocalElement:)``
