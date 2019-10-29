//
//  ModelHandler.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 27/09/2019.
//

import Foundation

public protocol ModelDelegate {
    
    /// A map of mesh message types that the associated Model may receive
    /// and handle. It should not contain types of messages that this
    /// Model only sends. Items of this map are used to instantiate a
    /// message when an Access PDU with given opcode is received.
    ///
    /// The key in the map should be the opcode and the value
    /// the message type supported by the handler.
    var messageTypes: [UInt32 : MeshMessage.Type] { get }
    
    /// A flag whether this Model supports subscription mechanism.
    /// When set to `false`, the library will return error
    /// `ConfigMessageStatus.notASubscribeModel` whenever subscription
    /// change was initiated.
    var isSubscriptionSupported: Bool { get }
    
    /// This method should handle the received Acknowledged Message.
    ///
    /// - parameters:
    ///   - model: The Model associated with this Model Delegate.
    ///   - request: The Acknowledged Message received.
    ///   - source:  The source Unicast Address.
    ///   - destination: The destination address of the request.
    /// - returns: The response message to be sent to the sender.
    func model(_ model: Model, didReceiveAcknowledgedMessage request: AcknowledgedMeshMessage,
               from source: Address, sentTo destination: MeshAddress) -> MeshMessage
    
    /// This method should handle the received Unacknowledged Message.
    ///
    /// - parameters:
    ///   - model: The Model associated with this Model Delegate.
    ///   - message: The Unacknowledged Message received.
    ///   - source: The source Unicast Address.
    ///   - destination: The destination address of the request.
    func model(_ model: Model, didReceiveUnacknowledgedMessage message: MeshMessage,
               from source: Address, sentTo destination: MeshAddress)
    
    /// This method should handle the received response to the
    /// previously sent request.
    ///
    /// - parameters:
    ///   - model: The Model associated with this Model Delegate.
    ///   - response: The response received.
    ///   - request: The Acknowledged Message sent.
    ///   - source: The Unicast Address of the Element that sent the
    ///             response.
    func model(_ model: Model, didReceiveResponse response: MeshMessage,
               toAcknowledgedMessage request: AcknowledgedMeshMessage,
               from source: Address)
    
}

public extension Array where Element == StaticMeshMessage.Type {
    
    /// A helper method that can create a map of message types required
    /// by the `ModelDelegate` from a list of `StaticMeshMessage`s.
    ///
    /// - returns: A map of message types.
    func toMap() -> [UInt32 : MeshMessage.Type] {
        var map: [UInt32 : MeshMessage.Type] = [:]
        forEach {
            map[$0.opCode] = $0
        }
        return map
    }
    
}
