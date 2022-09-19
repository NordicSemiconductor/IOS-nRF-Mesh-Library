# ``nRFMeshProvision/MeshNetworkManager``

The Mesh Network Manager is the main entry point for interacting with the mesh network.
Use it to create, load or import a Bluetooth mesh network and send messages. 

## Topics

### Mesh Network

- ``localElements``
- ``createNewMeshNetwork(withName:by:)-97wsf``
- ``createNewMeshNetwork(withName:by:)-2fqd1``
- ``meshNetwork``
- ``isNetworkCreated``
- ``load()``
- ``save()``
- ``import(from:)``
- ``export()``
- ``export(_:)``

### Delegates

- ``delegate``
- ``transmitter``
- ``logger``

### Provisioning

- ``provision(unprovisionedDevice:over:)``

### Sending Messages

- ``publish(_:from:)``
- ``send(_:from:to:withTtl:using:)-2qajr``
- ``send(_:from:to:withTtl:using:)-2o2t9``
- ``send(_:to:withTtl:)-77r3r``
- ``send(_:to:withTtl:)-1xxm0``
- ``send(_:from:to:withTtl:)-36p9o``
- ``send(_:from:to:withTtl:)-2ogrs``
- ``send(_:from:to:withTtl:using:)-2o2t9``
- ``sendToLocalNode(_:)``
- ``send(_:)``
- ``cancel(_:)``

### Bearer Callbacks

- ``bearerDidDeliverData(_:ofType:)``
- ``bearer(_:didDeliverData:ofType:)``

### Proxy Filter

- ``proxyFilter``

### Configuration

- ``defaultTtl``
- ``incompleteMessageTimeout``
- ``acknowledgmentTimerInterval``
- ``transmissionTimerInterval``
- ``retransmissionLimit``
- ``acknowledgmentMessageTimeout``
- ``acknowledgmentMessageInterval``

### Advanced Configuration

- ``allowIvIndexRecoveryOver42``
- ``ivUpdateTestMode``
- ``setSequenceNumber(_:forLocalElement:)``
- ``getSequenceNumber(ofLocalElement:)``
