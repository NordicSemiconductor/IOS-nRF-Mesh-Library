# Exporting network configuration

Export and import feature allows to share mesh network configuration between 
devices.

## Overview

The mesh network configuration schema is defined in 
[Bluetooth Mesh Configuration Database specification](https://www.bluetooth.com/specifications/specs/mesh-configuration-database-profile-1-0-1/).
As the schema is standardized by Bluetooth SIG it should be possible to import it on different devices
from different manufacturers.

Exporting network is done by calling ``MeshNetworkManager/export(_:)``.

The ``ExportConfiguration`` allows to export partial configuration, e.g. skip Device Keys, or
share only selected ``NetworkKey``s.

To import a configuration call ``MeshNetworkManager/import(from:)``.

### Example

In the typical Guest User scenario, a house owner may only want to share a set of
devices without their Device Keys, preventing them from being reconfigured. In order to do
that, a new Guest Network Key and set of Application Keys bound to it can be created and sent
to desired nodes. The partial configuration including new keys can be exported to the guest.

Before exporting, the owner may create a new ``Provisioner`` object with limited allocated 
ranges, disallowing the guest to provision more devices.

After the guest moves out, the keys can be changed or removed from the devices.
