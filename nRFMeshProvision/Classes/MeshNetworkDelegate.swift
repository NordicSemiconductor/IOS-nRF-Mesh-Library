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
    ///   - manager:     The manager which has received the message.
    ///   - message:     The received message.
    ///   - source:      The Unicast Address of the Element from which
    ///                  the message was sent.
    ///   - destination: The address to which the message was sent.
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            didReceiveMessage message: MeshMessage,
                            sentFrom source: Address, to destination: Address)
    
    /// A callback called when an unsegmented message was sent to the
    /// `transmitter`, or when all segments of a segmented message targetting
    /// a Unicast Address were acknowledged by the target Node.
    ///
    /// - parameters:
    ///   - manager:      The manager used to send the message.
    ///   - message:      The message that has been sent.
    ///   - localElement: The local Element used as a source of this message.
    ///   - destination:  The address to which the message was sent.
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            didSendMessage message: MeshMessage,
                            from localElement: Element, to destination: Address)
    
    /// A callback called when a message failed to be sent to the target
    /// Node, or the respnse for an acknowledged message hasn't been received
    /// before the time run out.
    ///
    /// For unsegmented unacknowledged messages this callback will be invoked when
    /// the `transmitter` was set to `nil`, or has thrown an exception from
    /// `send(data:ofType)`.
    ///
    /// For segmented unacknowledged messages targetting a Unicast Address,
    /// besides that, it may also be called when sending timed out before all of
    /// the segments were acknowledged by the target Node, or when the target
    /// Node is busy and not able to proceed the message at the moment.
    ///
    /// For acknowledged messages the callback will be called when the response
    /// has not been received before the time set by `acknowledgmentMessageTimeout`
    /// run out. The message might have been retransmitted multiple times
    /// and might have been received by the target Node. For acknowledged messages
    /// sent to a Group or Virtual Address this will be called when the response
    /// has not been received from any Node.
    ///
    /// Possible errors are:
    /// - Any error thrown by the `transmitter`.
    /// - `BearerError.bearerClosed` - when the `transmitter` object was net set.
    /// - `LowerTransportError.busy` - when the target Node is busy and can't
    ///   accept the message.
    /// - `LowerTransportError.timeout` - when the segmented message targetting
    ///   a Unicast Address was not acknowledgned before the `retransmissionLimit`
    ///   was reached (for unacknowledged messages only).
    /// - `AccessError.timeout` - when the response for an acknowledged message
    ///   has not been received before the time run out (for acknowledged messages
    ///   only).
    ///
    /// - parameters:
    ///   - manager:      The manager used to send the message.
    ///   - message:      The message that has failed to be delivered.
    ///   - localElement: The local Element used as a source of this message.
    ///   - destination:  The address to which the message was sent.
    ///   - error:        The error that occurred.
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            failedToSendMessage message: MeshMessage,
                            from localElement: Element, to destination: Address,
                            error: Error)
    
}

public extension MeshNetworkDelegate {
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            didSendMessage message: MeshMessage,
                            from localElement: Element, to destination: Address) {
        // Empty.
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            failedToSendMessage message: MeshMessage,
                            from localElement: Element, to destination: Address,
                            error: Error) {
        // Empty.
    }
    
}
