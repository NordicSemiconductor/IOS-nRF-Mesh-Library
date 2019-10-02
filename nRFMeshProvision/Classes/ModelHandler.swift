//
//  ModelHandler.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 27/09/2019.
//

import Foundation

public protocol ModelHandler {
    
    /// The Mesh Network Manager.
    var manager: MeshNetworkManager! { get set }
    /// The Model associated with this handler.
    var model: Model! { get set }
    
    /// A map of mesh message types that this Model can receive.
    ///
    /// The key in the map should be the opcode and the value
    /// the message type supported by the handler.
    var messageTypes: [UInt32 : MeshMessage.Type] { get }
    
    /// This method should handle the received Acknowledged Message.
    ///
    /// - parameters:
    ///   - request: The Acknowledged Message received.
    ///   - source: The source Unicast Address.
    /// - returns: The response message to be sent to the sender.
    func handle(acknowledgedMessage request: AcknowledgedMeshMessage,
                sentFrom source: Address) -> MeshMessage
    
    /// This method should handle the received Unacknowledged Message.
    ///
    /// - parameters:
    ///   - message: The Unacknowledged Message received.
    ///   - source: The source Unicast Address.
    func handle(unacknowledgedMessage message: MeshMessage,
                sentFrom source: Address)
    
    /// This method should handle the received response to the
    /// previously sent request.
    ///
    /// - parameters:
    ///   - response: The response received.
    ///   - request: The Acknowledged Message sent.
    ///   - source: The Unicast Address of the Element that sent the
    ///             response.
    func handle(response: MeshMessage,
                toAcknowledgedMessage request: AcknowledgedMeshMessage,
                sentFrom source: Address)
    
}

public extension ModelHandler {
    
    /// Sends the given message to the destination specified in the
    /// publication of the associated model.
    ///
    /// - parameter message: The mesh message to be sent.
    /// - returns: The message handle if the message was send, `nil`
    ///            otherwise.
    func send(_ message: MeshMessage) -> MessageHandle? {
        guard let publish = model.publish,
              let element = model.parentElement,
              let applicationKey = manager.meshNetwork?.applicationKeys[publish.index] else {
            return nil
        }
        return try? manager.send(message, from: element,
                                 to: publish.publicationAddress,
                                 using: applicationKey)
    }
    
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
