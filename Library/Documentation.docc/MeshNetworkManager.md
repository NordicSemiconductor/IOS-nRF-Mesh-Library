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
- ``attentionTimerDelegate``

### Provisioning

- ``provision(unprovisionedDevice:over:)``

### Publishing

- ``publish(_:from:)``

### Sending Messages (async)

- ``send(_:from:to:withTtl:using:)-8i087``
- ``send(_:from:to:withTtl:using:)-49tfj``
- ``send(_:from:to:withTtl:using:)-4mctq``
- ``send(_:from:to:withTtl:using:)-65l1j``
- ``send(_:from:to:withTtl:using:)-82q0x``
- ``send(_:from:to:withTtl:using:)-49dnw``
- ``send(_:to:withTtl:using:)-3e4v4``
- ``send(_:to:withTtl:using:)-9mtag``
- ``send(_:to:withTtl:using:)-9j4y6``
- ``send(_:to:withTtl:using:)-41rs``
- ``sendToLocalNode(_:)``

### Sending Messages (callbacks)

- ``send(_:from:to:withTtl:using:completion:)-2804g``
- ``send(_:from:to:withTtl:using:completion:)-3suux``
- ``send(_:from:to:withTtl:using:completion:)-6mp7w``
- ``send(_:from:to:withTtl:using:completion:)-3sgzf``
- ``send(_:from:to:withTtl:using:completion:)-8ochy``
- ``send(_:from:to:withTtl:using:completion:)-2jkzb``
- ``send(_:to:withTtl:using:completion:)-9r4ob``
- ``send(_:to:withTtl:using:completion:)-49f44``
- ``send(_:to:withTtl:using:completion:)-5t28f``
- ``send(_:to:withTtl:using:completion:)-5434x``
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
