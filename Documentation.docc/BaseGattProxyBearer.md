#  ``nRFMeshProvision/BaseGattProxyBearer``

It is not required to use this implementation with nRF Mesh Provisioning library.

Bearers are separate from the mesh networking part and it is up to the developer
to provide the transmitter and receiver implementations. However, it is sufficient
for most simple cases.

## Topics

### Bearer

- ``delegate``
- ``dataDelegate``
- ``supportedPduTypes``
- ``isOpen``
- ``open()``
- ``close()``
- ``send(_:ofType:)``

### GATT Bearer

- ``readRSSI()``
