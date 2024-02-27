# ``NordicMesh/MeshNetworkManager``

The Mesh Network Manager is the main entry point for interacting with the mesh network.
Use it to create, load or import a Bluetooth mesh network and send messages. 

## Topics

### Local Elements

- ``localElements``
- <doc:LocalNode>

### Mesh Network

- ``meshNetwork``
- ``createNewMeshNetwork(withName:by:)-5b026``
- ``createNewMeshNetwork(withName:by:)-8efb4``
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

- ``send(_:from:to:withTtl:using:)-8i087``
- ``send(_:from:to:withTtl:using:)-49tfj``
- ``send(_:from:to:withTtl:)-91pzj``
- ``send(_:from:to:withTtl:)-4xk1o``
- ``send(_:from:to:withTtl:)-9do0t``
- ``send(_:from:to:withTtl:)-7iwpf``
- ``send(_:to:withTtl:)-j3dt``
- ``send(_:to:withTtl:)-7jr6s``
- ``send(_:to:withTtl:)-9r5wo``
- ``send(_:to:withTtl:)-44cky``
- ``sendToLocalNode(_:)``

### Sending Messages (callbacks)

- ``send(_:from:to:withTtl:using:completion:)-2804g``
- ``send(_:from:to:withTtl:using:completion:)-3suux``
- ``send(_:from:to:withTtl:completion:)-ryms``
- ``send(_:from:to:withTtl:completion:)-1u8lz``
- ``send(_:from:to:withTtl:completion:)-36und``
- ``send(_:from:to:withTtl:completion:)-5t3gz``
- ``send(_:to:withTtl:completion:)-6gowt``
- ``send(_:to:withTtl:completion:)-83jpy``
- ``send(_:to:withTtl:completion:)-3jw0o``
- ``send(_:to:withTtl:completion:)-6l1j2``
- ``sendToLocalNode(_:completion:)``
- ``cancel(_:)``

### Awaiting messages (async)

- ``waitFor(messageWithOpCode:from:to:timeout:)-2qhbz``
- ``waitFor(messageWithOpCode:from:to:timeout:)-2cgvz``
- ``waitFor(messageFrom:to:timeout:)-9lqf1``
- ``waitFor(messageFrom:to:timeout:)-7igrw``
- ``messages(withOpCode:from:to:)-1xznc``
- ``messages(withOpCode:from:to:)-1lme6``
- ``messages(from:to:)-4hwr4``
- ``messages(from:to:)-1zkr2``

### Awaiting messages (callbacks)

- ``waitFor(messageWithOpCode:from:to:timeout:completion:)-219fi``
- ``waitFor(messageWithOpCode:from:to:timeout:completion:)-7qvys``
- ``waitFor(messageFrom:to:timeout:completion:)-18uzm``
- ``waitFor(messageFrom:to:timeout:completion:)-7nntr``
- ``registerCallback(forMessagesWithOpCode:from:to:callback:)-2d464``
- ``registerCallback(forMessagesWithOpCode:from:to:callback:)-wduf``
- ``registerCallback(forMessagesFrom:to:callback:)-8pv8g``
- ``registerCallback(forMessagesFrom:to:callback:)-54noo``
- ``unregisterCallback(forMessagesWithOpCode:from:)-90crs``
- ``unregisterCallback(forMessagesWithOpCode:from:)-3zo7h``
- ``unregisterCallback(forMessagesWithType:from:)-5z37g``
- ``unregisterCallback(forMessagesWithType:from:)-1dxby``

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
