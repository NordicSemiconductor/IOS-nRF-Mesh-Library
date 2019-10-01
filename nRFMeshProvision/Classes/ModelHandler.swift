//
//  ModelHandler.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 27/09/2019.
//

import Foundation

public protocol ModelHandler {
    
    /// A map of mesh message types supported by this Model.
    ///
    /// The key in the map should be the Op Code and the value
    /// the message type supported by the handler.
    var messageTypes: [UInt32 : MeshMessage.Type] { get }
    
    /// This method should handle the received Acknowledged Message.
    ///
    /// - parameters:
    ///   - request: The Acknowledged Message received.
    ///   - source: The source Unicast Address.
    ///   - model: The local model that received the request.
    /// - returns: The response message to be sent to the sender.
    func handle(acknowledgedMessage request: AcknowledgedMeshMessage,
                sentFrom source: Address, to model: Model) -> MeshMessage
    
    /// This method should handle the received Unacknowledged Message.
    ///
    /// - parameters:
    ///   - message: The Unacknowledged Message received.
    ///   - source: The source Unicast Address.
    ///   - model: The local model that received the message.
    func handle(unacknowledgedMessage message: MeshMessage,
                sentFrom source: Address, to model: Model)
    
    /// This method should handle the received response to the
    /// previously sent request.
    ///
    /// - parameters:
    ///   - response: The response received.
    ///   - request: The Acknowledged Message sent.
    ///   - source: The Unicast Address of the Element that sent the
    ///             response.
    ///   - model: The local model that received the response.
    func handle(response: MeshMessage,
                toAcknowledgedMessage request: AcknowledgedMeshMessage,
                sentFrom source: Address, to model: Model)
    
}

public extension Array where Element == StaticMeshMessage.Type {
    
    /// A helper method that can create a map of message types required
    /// by the `ModelHandler` from a list of `StaticMeshMessage`s.
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
