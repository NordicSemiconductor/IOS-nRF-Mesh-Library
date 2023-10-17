# Configuration

Configuration allows to customize the behavior of the local and remote nodes.

## Overview

Each Node has a unique, random 128-bit secret key, called a *Device Key*, assigned during provisioning.

Configuration messages are secured using this Device Key on the Access Layer. Only the Provisioner
and the configured Node, which know the key, can encrypt and decrypt such messages.

Use ``MeshNetworkManager/sendToLocalNode(_:)`` to configure the *local node*. The ``ConfigMessage``s
will be handled by the *Configuration Server* model automatically by the library.

To configure the remote nodes, use ``MeshNetworkManager/send(_:to:withTtl:)-2bthl``.

Status messages for configuration messages are delivered using
``MeshNetworkDelegate/meshNetworkManager(_:didReceiveMessage:sentFrom:to:)`` to the 
``MeshNetworkManager/delegate``.

The updated state of the mesh network is automatically saved in the ``Storage``. 

> Important: As the nRF Mesh library supports *Configuration Server* model, it also allows 
             other provisioners to remotely reconfigure the *local node* when it is connected to a 
             GATT Proxy node. In example, the phone can be remotely removed from network. 
             To make sure the node never gets remotely removed do not share the Device Key of 
             the local node when exporting network configuration.

## What's next

Having the network set up and ready, it's time to share the configuration: <doc:Exporting>.
