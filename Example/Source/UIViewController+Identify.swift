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

protocol SupportsNodeIdentification {
    
    /// Sends ``HealthAttentionSetUnacknowledged`` message to the Health Server model
    /// of the Node to make it blink for 3 seconds.
    ///
    /// If not ready, this method will also create a new Application Key with Key Index 4095 and bind it
    /// to the Health Server model.
    ///
    /// - parameter node: The Node to identify.
    /// - returns: `true` if the Node is identified and the message was sent.
    func identify(node: Node) async -> Bool
}

extension SupportsNodeIdentification {
    
    func createNodeIdentificationKey(withKeyIndex index: KeyIndex, andBindToNetworkKey networkKey: NetworkKey) -> ApplicationKey? {
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

    func identify(node: Node) async -> Bool {
        let manager = MeshNetworkManager.instance
        guard let meshNetwork = manager.meshNetwork else {
            return false
        }
        
        // Check if the Health Server model exist (it is mandatory)
        // and has at least one bound Application Key.
        guard let healthServerModel = node.models(withSigModelId: .healthServerModelId).first else {
            return false
        }
        
        // If the Health Server model is not bound to any Application Key,
        // we need to bind it to one.
        if healthServerModel.boundApplicationKeys.isEmpty {
            // If the Node does not know any Application Keys, create one and bind it.
            // For security reasons we don't want to send any of the existing keys,
            // instead we will create a new one with Key Index (4095 - networkKey.index).
            if node.applicationKeys.isEmpty {
                // Let's take the Network Key known to the Node.
                let networkKey = node.networkKeys.first!
                let expectedIndex = KeyIndex(4095 - networkKey.index)
                guard let nodeIdentificationKey = meshNetwork.applicationKeys.boundTo(networkKey)[expectedIndex] ??
                        createNodeIdentificationKey(withKeyIndex: expectedIndex, andBindToNetworkKey: networkKey) else {
                    // Abort if another key with this key index already exists, but is bound to a different Network Key.
                    return false
                }
                
                // Send the newly created Application Key to the Node.
                let request = ConfigAppKeyAdd(applicationKey: nodeIdentificationKey)
                let response = try? await manager.send(request, to: node) as? ConfigAppKeyStatus
                guard response?.status == .success else {
                    return false
                }
            }
            
            // At this point, the Node should know at least one Application Key.
            guard let applicationKey = node.applicationKeys.first,
                  let request = ConfigModelAppBind(applicationKey: applicationKey, to: healthServerModel) else {
                return false
            }
            let response = try? await manager.send(request, to: node) as? ConfigModelAppStatus
            guard response?.status == .success else {
                return false
            }
        }
        
        try? await manager.send(HealthAttentionSetUnacknowledged(3.0), to: healthServerModel)
        return true
    }
}
