# Usage

How to start.

## Overview

The ``MeshNetworkManager`` is the main entry point for interacting with the mesh network.
It can be used to create, load or import a Bluetooth mesh network configuration and send 
and receive messages. 

The snippet below demonstrates how to start.

```swift
// Create the Mesh Network Manager instance.
meshNetworkManager = MeshNetworkManager()

// If needed, customize network parameters using basic:
meshNetworkManager.networkParameters = .basic { parameters in
    parameters.setDefaultTtl(...)
    // Configure SAR Receiver properties
    parameters.discardIncompleteSegmentedMessages(after: ...)
    parameters.transmitSegmentAcknowledgmentMessage(
        usingSegmentReceptionInterval: ...,
        multipliedByMinimumDelayIncrement: ...)
    parameters.retransmitSegmentAcknowledgmentMessages(
        exactly: ..., timesWhenNumberOfSegmentsIsGreaterThan: ...)
    // Configure SAR Transmitter properties
    parameters.transmitSegments(withInterval: ...)
    parameters.retransmitUnacknowledgedSegmentsToUnicastAddress(
        atMost: ..., timesAndWithoutProgress: ...,
        timesWithRetransmissionInterval: ..., andIncrement: ...)
    parameters.retransmitAllSegmentsToGroupAddress(exactly: ..., timesWithInterval: ...)
    // Configure message configuration
    parameters.retransmitAcknowledgedMessage(after: ...)
    parameters.discardAcknowledgedMessages(after: ...)
}
// ...or advanced configurator:
meshNetworkManager.networkParameters = .advanced { parameters in
    parameters.defaultTtl = ...
    // Configure SAR Receiver properties
    parameters.sarDiscardTimeout = ...
    parameters.sarAcknowledgmentDelayIncrement = ...
    parameters.sarReceiverSegmentIntervalStep = ...
    parameters.sarSegmentsThreshold = ...
    parameters.sarAcknowledgmentRetransmissionsCount = ...
    // Configure SAR Transmitter properties
    parameters.sarSegmentIntervalStep = ...
    parameters.sarUnicastRetransmissionsCount = ...
    parameters.sarUnicastRetransmissionsWithoutProgressCount = ...
    parameters.sarUnicastRetransmissionsIntervalStep = ...
    parameters.sarUnicastRetransmissionsIntervalIncrement = ...
    parameters.sarMulticastRetransmissionsCount = ...
    parameters.sarMulticastRetransmissionsIntervalStep = ...
    // Configure acknowledged message timeouts
    parameters.acknowledgmentMessageInterval = ...
    parameters.acknowledgmentMessageTimeout = ...
    // And if you really know what you're doing...
    builder.allowIvIndexRecoveryOver42 = ...
    builder.ivUpdateTestMode = ...
}
// You may also modify a parameter using this syntax:
meshNetworkManager.networkParameters.defaultTtl = ...

// For debugging, set the logger delegate.
meshNetworkManager.logger = ...
```

## What's next

The next step is to define the behavior of the manager determined by the set
of models on the local node: <doc:LocalNode>.
