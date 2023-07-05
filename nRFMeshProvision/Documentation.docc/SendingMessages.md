# Sending messages

Bluetooth mesh is built on publish-subscribe paradigm. Each node can publish messages and receive messages 
sent by other nodes. 

## Overview

The nRF Mesh library supports sending messages in two ways:
1. From models on the local node, that are configured for publishing.
2. Directly.

The first method closely follows Bluetooth Mesh Profile specification, but is quite complex.
A model needs to be bound to an Application Key using ``ConfigModelAppBind`` message
and have a publication set using ``ConfigModelPublicationSet`` or 
``ConfigModelPublicationVirtualAddressSet``. With that set, calling 
``ModelDelegate/publish(using:)`` or ``ModelDelegate/publish(_:using:)`` will trigger a publication
from the model to a destination specified in the ``Publish`` object. Responses will be delivered
to ``ModelDelegate/model(_:didReceiveResponse:toAcknowledgedMessage:from:)`` of the model delegate.

The second method does not require setting up local models. 
Use ``MeshNetworkManager/send(_:from:to:withTtl:using:)-48vjl`` or other variants of this method to send 
a message to the desired destination.

> All methods used for sending messages in the ``MeshNetworkManager`` are asynchronous.
