/*
* Copyright (c) 2019, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

import Foundation

/// Set of errors that may be thrown for a ``ModelDelegate`` during
/// handing a reveived acknowledged message.
public enum ModelError: Error {
    /// This error can be returned if the received acknowledged message
    /// should be discarded due to being invalid.
    case invalidMessage
}

/// Model delegate defines the functionality of a ``Model`` on the
/// Local Node.
///
/// Model Delegates are assigned to the Models during setting up
/// the ``MeshNetworkManager/localElements``.
///
/// The Model Delegate must declare a map of mesh message type
/// supported by this Model. Whenever a mesh message matching any
/// of the declared Op Codes is received, and the Model instance is bound
/// to the Application Key used to encrypt the message, one of the message
/// handlers will be called:
/// * ``ModelDelegate/model(_:didReceiveUnacknowledgedMessage:from:sentTo:)``
/// * ``ModelDelegate/model(_:didReceiveAcknowledgedMessage:from:sentTo:)``
/// * ``ModelDelegate/model(_:didReceiveResponse:toAcknowledgedMessage:from:)``
///
/// The Model Dlegate also specifies should the Model support subscription
/// and defines publication composer for automatic publications.
public protocol ModelDelegate: AnyObject {
    typealias MessageComposer = () -> MeshMessage
    
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
    /// ``ConfigMessageStatus/notASubscribeModel`` whenever subscription
    /// change was initiated.
    var isSubscriptionSupported: Bool { get }
    
    /// The message composer that will be used to create a Mesh Message.
    ///
    /// The composer will be used whenever model is about to publish its
    /// state using the publish information specified in the Model.
    ///
    /// When set to `nil`, the library will return error
    /// ``ConfigMessageStatus/invalidPublishParameters`` for each Config
    /// Model Publication Set and Config Model Publication Virtual Address Set.
    var publicationMessageComposer: MessageComposer? { get }
    
    /// This method should handle the received Acknowledged Message.
    ///
    /// - parameters:
    ///   - model: The Model associated with this Model Delegate.
    ///   - request: The Acknowledged Message received.
    ///   - source:  The source Unicast Address.
    ///   - destination: The destination address of the request.
    /// - returns: The response message to be sent to the sender.
    /// - throws: The method should throw ``ModelError``
    ///           if the receive message is invalid and no response
    ///           should be replied.
    func model(_ model: Model, didReceiveAcknowledgedMessage request: AcknowledgedMeshMessage,
               from source: Address, sentTo destination: MeshAddress) throws -> MeshResponse
    
    /// This method should handle the received Unacknowledged Message.
    ///
    /// - parameters:
    ///   - model: The Model associated with this Model Delegate.
    ///   - message: The Unacknowledged Message received.
    ///   - source: The source Unicast Address.
    ///   - destination: The destination address of the request.
    func model(_ model: Model, didReceiveUnacknowledgedMessage message: UnacknowledgedMeshMessage,
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
    func model(_ model: Model, didReceiveResponse response: MeshResponse,
               toAcknowledgedMessage request: AcknowledgedMeshMessage,
               from source: Address)
    
}

public extension ModelDelegate {
    
    /// Publishes a single message given as a parameter using the
    /// Publish information set in the underlying Model.
    ///
    /// - parameters:
    ///   - message: The message to be published.
    ///   - manager: The manager to be used for publishing.
    /// - returns: The Message Handler that can be used to cancel sending.
    @discardableResult
    func publish(_ message: MeshMessage, using manager: MeshNetworkManager) -> MessageHandle? {
        return manager.localElements
            .flatMap { element in element.models }
            .first { model in model.delegate === self }
            .map { model in manager.publish(message, from: model) } ?? nil
    }
    
    /// Publishes a single message created by Model's message composer using
    /// the Publish information set in the underlying Model.
    ///
    /// - parameter manager: The manager to be used for publishing.
    /// - returns: The Message Handler that can be used to cancel sending.
    @discardableResult
    func publish(using manager: MeshNetworkManager) -> MessageHandle? {
        guard let composer = publicationMessageComposer else {
            return nil
        }
        return publish(composer(), using: manager)
    }
    
}

/// The Model Delegate which should be used when defining Scene Server
/// model.
///
/// In addition to handling messages, the Scene Server delegate
/// should also clear the Current Scene whenever
/// ``SceneServerModelDelegate/networkDidExitStoredWithSceneState()``
/// call is received.
public protocol SceneServerModelDelegate: ModelDelegate {
    
    /// This method should be called whenever the State of a Model changes
    /// for any reason other than receiving Scene Recall message.
    ///
    /// The call of this method should be consumed by Scene Server model,
    /// which should clear the Current Scene.
    func networkDidExitStoredWithSceneState()
    
}

/// The Model Delegate which should be used for Models that allow storing
/// the state with a Scene.
///
/// In addition to handling messages, the Model Delegate should also
/// store and recall the current state whenever
/// ``StoredWithSceneModelDelegate/store(with:)``
/// and ``StoredWithSceneModelDelegate/recall(_:transitionTime:delay:)``
/// calls are received.
///
/// Whenever the state changes due to any other reason than receiving
/// a Scene Recall message, the delegate should call
/// ``StoredWithSceneModelDelegate/networkDidExitStoredWithSceneState(_:)``
/// to clear the Current State in the Scene Server model.
public protocol StoredWithSceneModelDelegate: ModelDelegate {
    
    /// This method should store the current States of the Model and
    /// associate them with the given Scene number.
    ///
    /// - parameter scene: The Scene number.
    func store(with scene: SceneNumber)
    
    /// This method should recall the States of the Model associated with
    /// the given Scene number.
    ///
    /// - parameters:
    ///   - scene: The Scene number.
    ///   - transitionTime: The Transition Time field identifies the time
    ///                     that an element will take to transition to the
    ///                     target state from the present state.
    ///   - delay: Message execution delay in 5 millisecond steps.
    func recall(_ scene: SceneNumber, transitionTime: TransitionTime?, delay: UInt8?)
    
}

public extension StoredWithSceneModelDelegate {
    
    /// This method should be called whenever the state of a local Model changes
    /// due to a different action than recalling a Scene.
    ///
    /// This method will invalidate the Current Scene state in Scene Server model.
    ///
    /// - parameter network: The mesh network this model belong to.
    func networkDidExitStoredWithSceneState(_ network: MeshNetwork) {
        network.localElements
            .flatMap { element in element.models }
            .compactMap { model in model.delegate as? SceneServerModelDelegate }
            .forEach { delegate in delegate.networkDidExitStoredWithSceneState() }
    }
    
}

/// Transaction helper may be used to deal with Transaction Messages.
///
/// Transaction Messages are sent with a Transaction Identifier (TID).
///
/// If a received TID is the same as TID of the previously received message
/// from the same source and targeting the same destination, and no more
/// than 6 seconds have passed since, the message is assumed to be the
/// transaction continuation. Otherwise it is a new transaction.
public class TransactionHelper {
    
    private var mutex: DispatchQueue = .init(label: "NewTransactionMutex")
    
    private typealias Transaction = (
        source: Address,
        destination: MeshAddress,
        tid: UInt8,
        timestamp: Date
    )
    
    /// The last transaction details.
    private var lastTransactions: [UInt32 : Transaction] = [:]
    
    public init() {
        // No op.
    }
    
    /// Returns whether the given Transaction Message was sent as a new
    /// transaction, or is part of the previously started transaction.
    ///
    /// - parameters:
    ///   - message: The received message.
    ///   - source: The source Unicast Address.
    ///   - destination: The destination address.
    /// - returns: True, if the message starts a new transaction; false otherwise.
    public func isNewTransaction(_ message: TransactionMessage,
                                 from source: Address, to destination: MeshAddress) -> Bool {
        return mutex.sync {
            let lastTransaction = self.lastTransactions[message.opCode]
            let isNew = lastTransaction == nil ||
            lastTransaction!.source != source ||
            lastTransaction!.destination != destination ||
            message.isNewTransaction(previousTid: lastTransaction!.tid,
                                     timestamp: lastTransaction!.timestamp)
            
            self.lastTransactions[message.opCode] = (
                source: source, destination: destination,
                tid: message.tid, timestamp: Date()
            )
            return isNew
        }
    }
    
    /// Returns whether the given Transaction Message was sent as a continuation
    /// of the last transaction.
    ///
    /// - parameters:
    ///   - message: The received message.
    ///   - source: The source Unicast Address.
    ///   - destination: The destination address.
    /// - returns: True, if the message continues the last transaction; false otherwise.
    public func isTransactionContinuation(_ message: TransactionMessage,
                                          from source: Address, to destination: MeshAddress) -> Bool {
        return !isNewTransaction(message, from: source, to: destination)
    }
    
}

public extension Array where Element == StaticMeshMessage.Type {
    
    /// A helper method that can create a map of message types required
    /// by the ``ModelDelegate`` from a list of ``StaticMeshMessage``s.
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
