//
//  MeshNetworkDelegate.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 12/08/2019.
//

import Foundation

public protocol MeshNetworkDelegate: class {
    
    /// A callback called whenever a Mesh Message has been received
    /// from the mesh network.
    ///
    /// The `source` is given as an Address, instead of an Element, as
    /// the message may be sent by an unknown Node, or a Node which
    /// Elements are unknown.
    ///
    /// The `destination` address may be a Unicast Address of a local
    /// Element, a Group or Virtual Address, but also any other address
    /// if it was added to the Proxy Filter, e.g. a Unicast Address of
    /// an Element on a remote Node.
    ///
    /// - parameters:
    ///   - meshNetwork: The mesh network from which the message has
    ///                  been received.
    ///   - message:     The received message.
    ///   - source:      The Unicast Address of the Element from which
    ///                  the message was sent.
    ///   - destination: The address to which the message was sent.
    func meshNetwork(_ meshNetwork: MeshNetwork,
                     didDeliverMessage message: MeshMessage,
                     sentFrom source: Address, to destination: Address)
    
    /// A callback called when an unsegmented message was sent to the
    /// `transmitter`, or when all segments of a segmented message targetting
    /// a Unicast Address were acknowledged by the target Node.
    ///
    /// - parameters:
    ///   - meshNetwork:  The mesh network to which the message has
    ///                   been sent.
    ///   - message:      The message that has been sent.
    ///   - localElement: The local Element used as a source of this message.
    ///   - destination:  The address to which the message was sent.
    func meshNetwork(_ meshNetwork: MeshNetwork,
                     didDeliverMessage message: MeshMessage,
                     sentFrom localElement: Element, to destination: Address)
    
    /// A callback called when a message failed to be sent to the target
    /// Node. For unsegmented messages this may happen when the `transmitter`
    /// was `nil`, or has thrown an exception from `send(data:ofType)`.
    /// For segmented messages targetting a Unicast Address this may also be
    /// called when sending timeouted before all of the segments were
    /// acknowledged by the target Node, or when the target Node is busy and
    /// not able to proceed the message at the moment.
    ///
    /// Possible errors are:
    /// - Any error thrown by the `transmitter`.
    /// - `BearerError.bearerClosed` - when the `transmitter` object was net set.
    /// - `LowerTransportError.busy` - when the target Node is busy and can't
    ///   accept the message.
    /// - `LowerTransportError.timeout` - when the segmented message targetting
    ///   a Unicast Address was not acknowledgned before the `retransmissionLimit`
    ///   was reached.
    ///
    /// - parameters:
    ///   - meshNetwork:  The mesh network to which the message has
    ///                   been sent.
    ///   - message:      The message that has failed to be delivered.
    ///   - localElement: The local Element used as a source of this message.
    ///   - destination:  The address to which the message was sent.
    ///   - error:        The error that occurred.
    func meshNetwork(_ meshNetwork: MeshNetwork,
                     failedToDeliverMessage message: MeshMessage,
                     from localElement: Element, to destination: Address,
                     error: Error)
    
}

public extension MeshNetworkDelegate {
    
    func meshNetwork(_ meshNetwork: MeshNetwork,
                     didDeliverMessage message: MeshMessage,
                     sentFrom localElement: Element, to destination: Address) {
        // Empty.
    }
    
    func meshNetwork(_ meshNetwork: MeshNetwork,
                     failedToDeliverMessage message: MeshMessage,
                     from localElement: Element, to destination: Address,
                     error: Error) {
        // Empty.
    }
    
}
