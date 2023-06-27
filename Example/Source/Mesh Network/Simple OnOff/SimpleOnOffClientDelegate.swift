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

/// This is an implementation of a simple Vendor Model defined in nRF Mesh SDK from
/// Nordic Semiconductor.
///
/// The Simple OnOff Client model can send 3 types of messages:
/// - 0x01 - Simple OnOff Set
/// - 0x02 - Simple OnOff Get
/// - 0x03 - Simple OnOff Set Unacknowledged
///
/// and it can receive one status message for Get and Set:
/// - 0x04 - Simple OnOff Status
///
/// Messages in this library are sent using the `MeshNetworkManager`, not
/// from the Model delegate.
///
/// - seeAlso: https://infocenter.nordicsemi.com/topic/com.nordic.infocenter.meshsdk.v3.2.0/md_models_vendor_simple_on_off_README.html?cp=5_2_2_3_1
class SimpleOnOffClientDelegate: ModelDelegate {
    let messageTypes: [UInt32 : MeshMessage.Type]
    let isSubscriptionSupported: Bool = false
    
    lazy var publicationMessageComposer: MessageComposer? = { [unowned self] in
        return SimpleOnOffSetUnacknowledged(self.state)
    }
    
    /// The current state of the Simple On Off Client model.
    var state: Bool = false {
        didSet {
            publish(using: MeshNetworkManager.instance)
        }
    }
    
    private var logger: LoggerDelegate? {
        return MeshNetworkManager.instance.logger
    }
    
    init() {
        // This Model Delegate is able to receive SimpleOnOffStatus messages.
        // It needs to declare the op code and the type in the `messageTypes`
        // so the library know to what type a message with such op code should
        // be instantiated.
        let types: [StaticVendorMessage.Type] = [
            SimpleOnOffStatus.self
        ]
        messageTypes = types.toMap()
    }
    
    func model(_ model: Model,
               didReceiveAcknowledgedMessage request: AcknowledgedMeshMessage,
               from source: Address, sentTo destination: MeshAddress) -> MeshResponse {
        // This method will never be called for this Model, as the single message
        // type it supports (defines in `messageTypes`) is unacknowledged.
        fatalError("What has just happened?")
    }
    
    func model(_ model: Model,
               didReceiveUnacknowledgedMessage message: UnacknowledgedMeshMessage,
               from source: Address, sentTo destination: MeshAddress) {
        // A Simple OnOff Server may send status messages that do not reply
        // to any acknowledged messages, for example may publish the state
        // periodically. Such message will be delivered here if it was configured
        // to be sent to this Element's Unicast Address.
        
        switch message {
        case let status as SimpleOnOffStatus:
            let manager = MeshNetworkManager.instance
            let node = manager.meshNetwork?.node(withAddress: source)
            let element = node?.element(withAddress: source)
            let nodeName = node?.name ?? "Unknown Device"
            let elementName = element != nil ? element?.name ?? "Element \(element!.index + 1)" : "Unknown Element"
            logger?.log(message: "The Simple OnOff State on \(elementName) on \(nodeName) is now: \(status.isOn)",
                        ofCategory: .model, withLevel: .application)
        default:
            // Other message types will not be delivered here, as the `messageTypes`
            // map declares only the above one.
            break
        }
    }
    
    func model(_ model: Model,
               didReceiveResponse response: MeshResponse,
               toAcknowledgedMessage request: AcknowledgedMeshMessage, from source: Address) {
        // This message for sure did not change the state.
        let stateNotChanged = request is SimpleOnOffGet
        
        // This is where the status for the requests is delivered.
        switch response {
        case let status as SimpleOnOffStatus:
            let manager = MeshNetworkManager.instance
            let node = manager.meshNetwork?.node(withAddress: source)
            let element = node?.element(withAddress: source)
            let nodeName = node?.name ?? "Unknown Device"
            let verb = stateNotChanged ? "is" : "changed to"
            let elementName = element != nil ? element?.name ?? "Element \(element!.index + 1)" : "Unknown Element"
            logger?.log(message: "State of Simple OnOff on \(elementName) on \(nodeName) \(verb): \(status.isOn)",
                        ofCategory: .model, withLevel: .application)
        default:
            // Other message types will not be delivered here, as the `messageTypes`
            // map declares only the above one.
            break
        }
    }
    
    
}
