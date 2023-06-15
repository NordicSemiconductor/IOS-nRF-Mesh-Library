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
import nRFMeshProvision

class GenericDefaultTransitionTimeServerDelegate: ModelDelegate {
    let messageTypes: [UInt32 : MeshMessage.Type]
    let isSubscriptionSupported: Bool = true
    let publicationMessageComposer: MessageComposer? = nil
    
    var defaultTransitionTime: TransitionTime {
        didSet {
            guard defaultTransitionTime.isKnown else {
                defaultTransitionTime = TransitionTime(0)
                return
            }
        }
    }
    
    private let defaults: UserDefaults
    
    init(_ meshNetwork: MeshNetwork) {
        let types: [StaticMeshMessage.Type] = [
            GenericDefaultTransitionTimeGet.self,
            GenericDefaultTransitionTimeSet.self,
            GenericDefaultTransitionTimeSetUnacknowledged.self
        ]
        messageTypes = types.toMap()
        
        defaults = UserDefaults(suiteName: meshNetwork.uuid.uuidString)!
        let interval = defaults.double(forKey: "defaultTransitionTime")
        defaultTransitionTime = TransitionTime(interval)
    }
    
    // MARK: - Message handlers
    
    func model(_ model: Model, didReceiveAcknowledgedMessage request: AcknowledgedMeshMessage,
               from source: Address, sentTo destination: MeshAddress) throws -> MeshResponse {
        switch request {
            
        case let request as GenericDefaultTransitionTimeSet:
            // The state cannot be set to Unknown (0x3F) value.
            guard request.transitionTime.isKnown else {
                throw ModelError.invalidMessage
            }
            defaultTransitionTime = request.transitionTime
            defaults.set(defaultTransitionTime.interval, forKey: "defaultTransitionTime")
            
        case is GenericDefaultTransitionTimeGet:
            break
            
        default:
            fatalError("Not possible")
        }
        
        // Reply with GenericDefaultTransitionTimeStatus.
        return GenericDefaultTransitionTimeStatus(transitionTime: defaultTransitionTime)
    }
    
    func model(_ model: Model, didReceiveUnacknowledgedMessage message: UnacknowledgedMeshMessage,
               from source: Address, sentTo destination: MeshAddress) {
        switch message {
            
        case let request as GenericDefaultTransitionTimeSetUnacknowledged:
            // The state cannot be set to Unknown (0x3F) value.
            guard request.transitionTime.isKnown else {
                return
            }
            defaultTransitionTime = request.transitionTime
            defaults.set(defaultTransitionTime.interval, forKey: "defaultTransitionTime")
            
        default:
            // Not possible.
            break
        }
    }
    
    func model(_ model: Model, didReceiveResponse response: MeshResponse,
               toAcknowledgedMessage request: AcknowledgedMeshMessage,
               from source: Address) {
        // Not possible.
    }
    
}
