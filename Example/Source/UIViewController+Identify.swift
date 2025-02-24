/*
* Copyright (c) 2025, Nordic Semiconductor
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

import NordicMesh

enum NodeIdentificationError: Error {
    case noNetwork
    case noCompositionData
    case healthServerNotFound
    case noProxy
    case noCommonNetworkKey
    case cannotCreateNetworkKey
    case requestFailed(String, ConfigMessageStatus)
}

extension NodeIdentificationError: LocalizedError {
    
    public var errorDescription: String? {
        switch self {
        case .noNetwork: return "No network is selected."
        case .noCompositionData: return "Before identifying, tap the Node to obtain its Composition Data."
        case .healthServerNotFound: return "The Health Server model is not found on the Node."
        case .noProxy: return "No GATT Proxy Node connected."
        case .noCommonNetworkKey: return "There is no common Network Key between the Node and the connected Proxy Node."
        case .cannotCreateNetworkKey: return "Automatic creation of a new Application Key failed. Configure the model manually."
        case .requestFailed(let description, let status): return "\(description) failed: \(status)"
        }
    }
    
}

protocol SupportsNodeIdentification {
    
    /// Returns `true` if the Health Server model of the Node is bound to an App Key that
    /// can be sent through the Proxy Node.
    ///
    /// - parameter node: The Node to check.
    /// - returns: `true` if the Node can be identified, `false` if it needs to and can be configured.
    /// - throws: A ``NodeIdentificationError`` if the Node is not ready and cannot be configured.
    func canIdentify(node: Node) throws -> Bool
    
    /// Sends ``HealthAttentionSetUnacknowledged`` message to the Health Server model
    /// of the Node to make it blink for 3 seconds.
    ///
    /// If not ready, this method will also create a new Application Key with Key Index 4095 and bind it
    /// to the Health Server model.
    ///
    /// - parameter node: The Node to identify.
    /// - throws: A ``NodeIdentificationError`` if the operation failed.
    func identify(node: Node) async throws
}

extension SupportsNodeIdentification {
    
    private func createNodeIdentificationKey(withKeyIndex index: KeyIndex, andBindToNetworkKey networkKey: NetworkKey) -> ApplicationKey? {
        let manager = MeshNetworkManager.instance
        guard let meshNetwork = manager.meshNetwork else {
            return nil
        }
        do {
            let key = try meshNetwork.add(applicationKey: Data.random128BitKey(),
                                          withIndex: index,
                                          name: "Node Identification Key")
            try key.bind(to: networkKey)
            if manager.save() {
                return key
            }
        } catch {
            return nil
        }
        return nil
    }
    
    func canIdentify(node: Node) throws -> Bool {
        let manager = MeshNetworkManager.instance
        guard let _ = manager.meshNetwork else {
            throw NodeIdentificationError.noNetwork
        }
        
        // Check if the Node is a local Node, or a GATT Proxy Node is connected.
        guard node.isLocalProvisioner || manager.proxyFilter.proxy != nil else {
            throw NodeIdentificationError.noProxy
        }
        
        // Check if the Composition Data has been obtained.
        guard let _ = node.companyIdentifier else {
            throw NodeIdentificationError.noCompositionData
        }
        
        // Check if the Health Server model exist (it is mandatory)
        // and has at least one bound Application Key.
        guard let healthServerModel = node.models(withSigModelId: .healthServerModelId).first else {
            throw NodeIdentificationError.healthServerNotFound
        }
        
        // Check if there is an Application Key bound to the Health Server model,
        // that can be sent through the connected GATT Proxy.
        return healthServerModel.boundApplicationKeys.contains {
            // Unless the message is sent locally, take only keys known to the Proxy Node.
            node.isLocalProvisioner || manager.proxyFilter.proxy?.knows(networkKey: $0.boundNetworkKey) == true
        }
    }

    func identify(node: Node) async throws {
        let manager = MeshNetworkManager.instance
        guard let meshNetwork = manager.meshNetwork else {
            throw NodeIdentificationError.noNetwork
        }
        
        // Check if the Health Server model exist (it is mandatory)
        // and has at least one bound Application Key.
        guard let healthServerModel = node.models(withSigModelId: .healthServerModelId).first else {
            throw NodeIdentificationError.healthServerNotFound
        }
        
        // Check if there is an Application Key bound to the Health Server model,
        // that can be sent through the current GATT Proxy Node.
        var applicationKey = healthServerModel.boundApplicationKeys.first {
            // Unless the message is sent locally, take only keys known to the Proxy Node.
            node.isLocalProvisioner || manager.proxyFilter.proxy?.knows(networkKey: $0.boundNetworkKey) == true
        }
        
        // If not, we need to configure the model.
        if applicationKey == nil {
            // Check if the Node knows any Application Keys, that can be sent through the Proxy Node.
            applicationKey = node.applicationKeys.first {
                // Unless the message is sent locally, take only keys known to the Proxy Node.
                node.isLocalProvisioner || manager.proxyFilter.proxy?.knows(networkKey: $0.boundNetworkKey) == true
            }
            
            // If not, create a new Application Key.
            // For security reasons don't send any of the existing keys.
            // Instead create a new key with a fixed Key Index: 4095 - networkKey.index,
            // so it can be reused for other Nodes.
            if applicationKey == nil {
                // As a bound Network Key use the first one known to the target Node,
                // which is known to the Proxy Node.
                let networkKey = node.networkKeys.first {
                    // Unless the message is sent locally, take only keys known to the Proxy Node.
                    node.isLocalProvisioner || manager.proxyFilter.proxy?.knows(networkKey: $0) == true
                }
                guard let networkKey = networkKey else {
                    throw NodeIdentificationError.noCommonNetworkKey
                }
                let expectedIndex = KeyIndex(4095 - networkKey.index)
                guard let nodeIdentificationKey = meshNetwork.applicationKeys.boundTo(networkKey)[expectedIndex] ??
                        createNodeIdentificationKey(withKeyIndex: expectedIndex, andBindToNetworkKey: networkKey) else {
                    // Another key with this key index already exists, but is bound to a different Network Key.
                    throw NodeIdentificationError.cannotCreateNetworkKey
                }
                
                // Send the newly created Application Key to the Node.
                let request = ConfigAppKeyAdd(applicationKey: nodeIdentificationKey)
                let response = try await manager.send(request, to: node) as! ConfigAppKeyStatus
                guard response.status == .success else {
                    throw NodeIdentificationError.requestFailed("Adding App Key", response.status)
                }
                
                // The new Application Key has been successfully added to the Node.
                applicationKey = nodeIdentificationKey
            }
            
            // At this point, the Node should know at least one Application Key.
            let request = ConfigModelAppBind(applicationKey: applicationKey!, to: healthServerModel)!
            let response = try await manager.send(request, to: node) as! ConfigModelAppStatus
            guard response.status == .success else {
                throw NodeIdentificationError.requestFailed("Binding App Key to Health Server model", response.status)
            }
        }
        
        try await manager.send(HealthAttentionSetUnacknowledged(3.0), to: healthServerModel)
    }
}
