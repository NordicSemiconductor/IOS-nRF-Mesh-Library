# Setting up Local Node

Defining the behavior of the node.

## Overview

The mobile application using nRF Mesh library is itself a mesh node, called the *local node*.
Being a node means, that it is visible to other nodes as one or more *Elements*, each with 
one or more *Models* which support specific behavior and allow sending and receiving messages.

The library automatically supports the following models: 
- *Configuration Server* (required for all nodes)
- *Configuration Client* (required for configuring nodes)
- *Health Server* (required for all nodes, but not implemented yet)
- *Health Client* (currently not implemented)
- *Private Beacon Client*
- *Remote Provisioning Client*
- *SAR Configuration Client*
- *Scene Client* (for controlling scenes)

and may be extended to support user models: either Bluetooth SIG defined, like *Generic OnOff Client*,
or vendor models.

The elements on the *local node* must be configured using ``MeshNetworkManager/localElements`` property.
Each model declared in this array must have a ``ModelDelegate`` implemented, which maps the
Op Codes of supported messages to their types, and defines the behavior of the model. 
For example, a model delegate can specify that it can handle messages with an Op Code *0x8204*, 
which should be decoded to ``GenericOnOffStatus`` type.

If a received message cannot be mapped to any message type (i.e. no local model 
supports the op code of received message), it will be decoded as ``UnknownMessage``.

```swift
// Mind, that the first Element will contain the models mentioned above.
let primaryElement = Element(name: "Primary Element", location: .first, 
        models: [
            // Generic OnOff Client model:
            Model(sigModelId: .genericOnOffClientModelId, 
                  delegate: GenericOnOffClientDelegate()),
            // A simple vendor model:
            Model(vendorModelId: .simpleOnOffModelId,
                  companyId: .nordicSemiconductorCompanyId,
                  delegate: SimpleOnOffClientDelegate())
        ]
)
meshNetworkManager.localElements = [primaryElement]
```

> Important: Even if your implementation does not add any models to the default set, it is required to
  set the ``MeshNetworkManager/localElements``. It can be set to an empty array.

The model delegate is notified when a message targeting the model is received if, and only if, the model 
is bound to the Application Key used to encrypt the message and is subscribed to its destination 
address.

> Tip: The ``MeshNetworkDelegate``, set in the manager, is notified about every message 
  received. This includes messages targeting models that are not configured to receive messages, 
  i.e. not bound to any key, or not subscribed to the address set as destination address of the 
  message.

> See `Example/nRFMeshProvision/AppDelegate.swift` in "nRF Mesh" sample app for an example.

## What's next

The next step is <doc:CreatingNetwork>.
