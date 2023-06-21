/*
* Copyright (c) 2023, Nordic Semiconductor
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

@available(iOS 13.0.0, *)
public extension MeshNetworkManager {
    
    /// Encrypts the message with the Application Key and the Network Key
    /// bound to it, and sends to the given destination address.
    ///
    /// The method completes when the message has been sent or an error occurred.
    ///
    /// An appropriate callback of the ``MeshNetworkDelegate`` will be called when
    /// the message has been sent successfully or a problem occured.
    ///
    /// - parameters:
    ///   - message:        The message to be sent.
    ///   - localElement:   The source Element. If `nil`, the primary
    ///                     Element will be used. The Element must belong
    ///                     to the local Provisioner's Node.
    ///   - destination:    The destination address.
    ///   - initialTtl:     The initial TTL (Time To Live) value of the message.
    ///                     If `nil`, the default Node TTL will be used.
    ///   - applicationKey: The Application Key to sign the message.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the given local Element
    ///           does not belong to the local Node, or the manager failed to
    ///           send the message.
    func send(
        _ message: MeshMessage,
        from localElement: Element? = nil, to destination: MeshAddress,
        withTtl initialTtl: UInt8? = nil,
        using applicationKey: ApplicationKey
    ) async throws {
        try await withCheckedThrowingContinuation { continuation in
            do {
                try send(message, from: localElement, to: destination,
                         withTtl: initialTtl, using: applicationKey) { result in
                    continuation.resume(with: result)
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Encrypts the message with the Application Key and a Network Key
    /// bound to it, and sends to the given ``Group``.
    ///
    /// The method completes when the message has been sent or an error occurred.
    ///
    /// An appropriate callback of the ``MeshNetworkDelegate`` will be called when
    /// the message has been sent successfully or a problem occured.
    ///
    /// - parameters:
    ///   - message:        The message to be sent.
    ///   - localElement:   The source Element. If `nil`, the primary
    ///                     Element will be used. The Element must belong
    ///                     to the local Provisioner's Node.
    ///   - group:          The target Group.
    ///   - initialTtl:     The initial TTL (Time To Live) value of the message.
    ///                     If `nil`, the default Node TTL will be used.
    ///   - applicationKey: The Application Key to sign the message.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the given local Element
    ///           does not belong to the local Node, or the manager failed to
    ///           send the message.
    func send(
        _ message: MeshMessage,
        from localElement: Element? = nil, to group: Group,
        withTtl initialTtl: UInt8? = nil,
        using applicationKey: ApplicationKey
    ) async throws {
        try await withCheckedThrowingContinuation { continuation in
            do {
                try send(message, from: localElement, to: group,
                         withTtl: initialTtl, using: applicationKey) { result in
                    continuation.resume(with: result)
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Encrypts the message with the first Application Key bound to the given
    /// ``Model`` and the Network Key bound to it, and sends it to the Node
    /// to which the Model belongs to.
    ///
    /// The method completes when the message has been sent or an error occurred.
    ///
    /// An appropriate callback of the ``MeshNetworkDelegate`` will be called when
    /// the message has been sent successfully or a problem occured.
    ///
    /// - parameters:
    ///   - message:        The message to be sent.
    ///   - localElement:   The source Element. If `nil`, the primary
    ///                     Element will be used. The Element must belong
    ///                     to the local Provisioner's Node.
    ///   - model:          The destination Model.
    ///   - initialTtl:     The initial TTL (Time To Live) value of the message.
    ///                     If `nil`, the default Node TTL will be used.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the target Model does not belong to any Element, or has
    ///           no Application Key bound to it, or when
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the given local Element
    ///           does not belong to the local Node, or the manager failed to
    ///           send the message.
    func send(
        _ message: UnacknowledgedMeshMessage,
        from localElement: Element? = nil, to model: Model,
        withTtl initialTtl: UInt8? = nil
    ) async throws {
        try await withCheckedThrowingContinuation { continuation in
            do {
                try send(message, from: localElement, to: model, withTtl: initialTtl) { result in
                    continuation.resume(with: result)
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Encrypts the message with the common Application Key bound to both given
    /// ``Model``s and the Network Key bound to it, and sends it to the Node
    /// to which the target Model belongs to.
    ///
    /// The method completes when the message has been sent or an error occurred.
    ///
    /// An appropriate callback of the ``MeshNetworkDelegate`` will be called when
    /// the message has been sent successfully or a problem occured.
    ///
    /// - parameters:
    ///   - message:      The message to be sent.
    ///   - localElement: The source Element. If `nil`, the primary
    ///                   Element will be used. The Element must belong
    ///                   to the local Provisioner's Node.
    ///   - model:        The destination Model.
    ///   - initialTtl:   The initial TTL (Time To Live) value of the message.
    ///                   If `nil`, the default Node TTL will be used.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the local or target Model do not belong to any Element, or have
    ///           no common Application Key bound to them, or when
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the given local Element
    ///           does not belong to the local Node, or the manager failed to
    ///           send the message.
    func send(
        _ message: UnacknowledgedMeshMessage,
        from localModel: Model, to model: Model,
        withTtl initialTtl: UInt8? = nil
    ) async throws {
        try await withCheckedThrowingContinuation { continuation in
            do {
                try send(message, from: localModel, to: model, withTtl: initialTtl) { result in
                    continuation.resume(with: result)
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Encrypts the message with the first Application Key bound to the given
    /// ``Model`` and a Network Key bound to it, and sends it to the Node
    /// to which the Model belongs to and returns the response.
    ///
    /// An appropriate callback of the ``MeshNetworkDelegate`` will be called when
    /// the message has been sent successfully or a problem occured.
    ///
    /// - parameters:
    ///   - message:        The message to be sent.
    ///   - localElement:   The source Element. If `nil`, the primary
    ///                     Element will be used. The Element must belong
    ///                     to the local Provisioner's Node.
    ///   - model:          The destination Model.
    ///   - initialTtl:     The initial TTL (Time To Live) value of the message.
    ///                     If `nil`, the default Node TTL will be used.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the target Model does not belong to any Element, or has
    ///           no Application Key bound to it, or when
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the given local Element
    ///           does not belong to the local Node.
    /// - returns: The response with the expected ``AcknowledgedMeshMessage/responseOpCode``
    ///            received from the target Node.
    func send(
        _ message: AcknowledgedMeshMessage,
        from localElement: Element? = nil, to model: Model,
        withTtl initialTtl: UInt8? = nil
    ) async throws -> MeshResponse {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try send(message, from: localElement, to: model, withTtl: initialTtl) { result in
                    continuation.resume(with: result)
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Encrypts the message with the first Application Key bound to the given
    /// ``Model`` and a Network Key bound to it, and sends it to the Node
    /// to which the Model belongs to.
    ///
    /// An appropriate callback of the ``MeshNetworkDelegate`` will be called when
    /// the message has been sent successfully or a problem occured.
    ///
    /// - parameters:
    ///   - message:        The message to be sent.
    ///   - localElement:   The source Element. If `nil`, the primary
    ///                     Element will be used. The Element must belong
    ///                     to the local Provisioner's Node.
    ///   - model:          The destination Model.
    ///   - initialTtl:     The initial TTL (Time To Live) value of the message.
    ///                     If `nil`, the default Node TTL will be used.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the target Model does not belong to any Element, or has
    ///           no Application Key bound to it, or when
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the given local Element
    ///           does not belong to the local Node.
    /// - returns: The response associated with the message.
    func send<T: StaticAcknowledgedMeshMessage>(
        _ message: T,
        from localElement: Element? = nil, to model: Model,
        withTtl initialTtl: UInt8? = nil
    ) async throws -> T.ResponseType {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try send(message, from: localElement, to: model, withTtl: initialTtl) { result in
                    continuation.resume(with: result)
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Encrypts the message with the common Application Key bound to both given
    /// ``Model``s and a Network Key bound to it, and sends it to the Node
    /// to which the target Model belongs to.
    ///
    /// An appropriate callback of the ``MeshNetworkDelegate`` will be called when
    /// the message has been sent successfully or a problem occured.
    ///
    /// - parameters:
    ///   - message:      The message to be sent.
    ///   - localElement: The source Element. If `nil`, the primary
    ///                   Element will be used. The Element must belong
    ///                   to the local Provisioner's Node.
    ///   - model:        The destination Model.
    ///   - initialTtl:   The initial TTL (Time To Live) value of the message.
    ///                   If `nil`, the default Node TTL will be used.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the local or target Model do not belong to any Element, or have
    ///           no common Application Key bound to them, or when
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the given local Element
    ///           does not belong to the local Node.
    /// - returns: The response with the expected ``AcknowledgedMeshMessage/responseOpCode``
    ///            received from the target Node.
    func send(
        _ message: AcknowledgedMeshMessage,
        from localModel: Model, to model: Model,
        withTtl initialTtl: UInt8? = nil
    ) async throws -> MeshResponse {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try send(message, from: localModel, to: model, withTtl: initialTtl) { result in
                    continuation.resume(with: result)
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Encrypts the message with the common Application Key bound to both given
    /// ``Model``s and a Network Key bound to it, and sends it to the Node
    /// to which the target Model belongs to.
    ///
    /// An appropriate callback of the ``MeshNetworkDelegate`` will be called when
    /// the message has been sent successfully or a problem occured.
    ///
    /// - parameters:
    ///   - message:      The message to be sent.
    ///   - localElement: The source Element. If `nil`, the primary
    ///                   Element will be used. The Element must belong
    ///                   to the local Provisioner's Node.
    ///   - model:        The destination Model.
    ///   - initialTtl:   The initial TTL (Time To Live) value of the message.
    ///                   If `nil`, the default Node TTL will be used.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the local or target Model do not belong to any Element, or have
    ///           no common Application Key bound to them, or when
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the given local Element
    ///           does not belong to the local Node.
    /// - returns: The response associated with the message.
    func send<T: StaticAcknowledgedMeshMessage>(
        _ message: T,
        from localModel: Model, to model: Model,
        withTtl initialTtl: UInt8? = nil
    ) async throws -> T.ResponseType {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try send(message, from: localModel, to: model, withTtl: initialTtl) { result in
                    continuation.resume(with: result)
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Sends a Configuration Message to the Node with given destination address
    /// and returns the received response.
    ///
    /// The `destination` must be a Unicast Address, otherwise the method
    /// throws an ``AccessError/invalidDestination`` error.
    ///
    /// An appropriate callback of the ``MeshNetworkDelegate`` will be called when
    /// the message has been sent successfully or a problem occured.
    ///
    /// - parameters:
    ///   - message:     The message to be sent.
    ///   - destination: The destination Unicast Address.
    ///   - initialTtl:  The initial TTL (Time To Live) value of the message.
    ///                  If `nil`, the default Node TTL will be used.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the destination address
    ///           is not a Unicast Address or it belongs to an unknown Node.
    ///           Error ``AccessError/cannotDelete`` is sent when trying to
    ///           delete the last Network Key on the device.
    /// - returns: The response associated with the message.
    func send<T: AcknowledgedConfigMessage>(
        _ message: T, to destination: Address,
        withTtl initialTtl: UInt8? = nil
    ) async throws -> T.ResponseType {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try send(message, to: destination, withTtl: initialTtl) { result in
                    continuation.resume(with: result)
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Sends a Configuration Message to the primary Element on the given ``Node``
    /// and returns the received response.
    ///
    /// An appropriate callback of the ``MeshNetworkDelegate`` will be called when
    /// the message has been sent successfully or a problem occured.
    ///
    /// - parameters:
    ///   - message:    The message to be sent.
    ///   - node:       The destination Node.
    ///   - initialTtl: The initial TTL (Time To Live) value of the message.
    ///                 If `nil`, the default Node TTL will be used.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the destination address
    ///           is not a Unicast Address or it belongs to an unknown Node.
    ///           Error ``AccessError/cannotDelete`` is sent when trying to
    ///           delete the last Network Key on the device.
    /// - returns: The response associated with the message.
    func send<T: AcknowledgedConfigMessage>(
        _ message: T, to node: Node,
        withTtl initialTtl: UInt8? = nil
    ) async throws -> T.ResponseType {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try send(message, to: node) { result in
                    continuation.resume(with: result)
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Sends the Configuration Message to the primary Element of the local ``Node``
    /// and returns the received response.
    ///
    /// An appropriate callback of the ``MeshNetworkDelegate`` will also be called when
    /// the message has been sent successfully or a problem occured.
    ///
    /// - parameters:
    /// - parameter message: The acknowledged configuration message to be sent.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned) or the local Node returned an error.
    ///           Error ``AccessError/cannotDelete`` is sent when trying to
    ///           delete the last Network Key on the Node.
    /// - returns: The response associated with the message.
    func sendToLocalNode<T: AcknowledgedConfigMessage>(_ message: T) async throws -> T.ResponseType {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try sendToLocalNode(message) { result in
                    continuation.resume(with: result)
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
}
