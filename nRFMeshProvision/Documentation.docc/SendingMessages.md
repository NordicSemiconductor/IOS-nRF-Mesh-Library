# Sending messages

How to send mesh messages using the manager.

## Overview

Bluetooth mesh is built on publish-subscribe paradigm. Each node can publish messages and receive messages 
sent by other nodes. 

The nRF Mesh library supports sending messages in two ways:
1. From models on the local node, that are configured for publishing.
2. Directly.

The first method closely follows Bluetooth Mesh Protocol specification, but is quite complex.
A model needs to be bound to an Application Key using ``ConfigModelAppBind`` message
and have a publication set using ``ConfigModelPublicationSet`` or 
``ConfigModelPublicationVirtualAddressSet``. With that, calling 
``ModelDelegate/publish(using:)`` or ``ModelDelegate/publish(_:using:)`` will trigger a publication
from the model to a destination specified in the ``Publish`` object. Responses will be delivered
to ``ModelDelegate/model(_:didReceiveResponse:toAcknowledgedMessage:from:)`` of the model delegate.

> Note: The above is demonstrated in the nRF Mesh app on the **Local Node** tab. To set up the components
  configure the models on the Primary and Secondary Element of the *local node* using **Network** tab.

The second method does not require setting up local models. 
Use ``MeshNetworkManager/send(_:from:to:withTtl:using:)-48vjl`` or other variants of this method to send 
a message to the desired destination.

> Note: The second method can be shown using nRF Mesh app either by sending messages directly
  from desired node's models' views in **Network** tab, or from **Groups** tab.

Starting from nRF Mesh library version 4.0 all methods for sending messages come in 2 favors.
One is using `async` functions, which block execution until either the message was sent (for
``UnacknowledgedMeshMessage``), or the response was received (for ``AcknowledgedMeshMessage``).
Those have to be called from a [`Task`](https://developer.apple.com/documentation/swift/task).
The second favor is using completion handers instead, which are called in the same situations.
Both types can be used interchangeably.

## What's next

Knowing basics learn how to configure nodes, including the local one: <doc:Configuration>. 
