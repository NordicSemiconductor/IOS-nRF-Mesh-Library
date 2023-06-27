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

import UIKit
import nRFMeshProvision

protocol ModelViewCellDelegate: AnyObject {
    /// Encrypts the message with the first Application Key bound to the given
    /// Model and a Network Key bound to it, and sends it to the Node
    /// to which the Model belongs to.
    ///
    /// - parameter message: The message to be sent.
    /// - parameter description: The message to be displayed for the user.
    func send(_ message: MeshMessage, description: String)
    
    /// Sends Configuration Message to the given Node to which the Model belongs to.
    ///
    /// - parameter message: The message to be sent.
    /// - parameter description: The message to be displayed for the user.
    func send(_ message: AcknowledgedConfigMessage, description: String)
    
    /// Whether the view is being refreshed with Pull-to-Refresh or not.
    var isRefreshing: Bool { get }
}

class ModelViewCell: UITableViewCell {
    
    // MARK: - Properties
    
    var model: Model! {
        didSet {
            reload(using: model)
        }
    }
    weak var delegate: ModelViewCellDelegate!
    
    // MARK: - Implementation
    
    func reload(using model: Model) {
        // Empty.
    }
    
    // MARK: - API
    
    /// Initializes reading of all fields in the Model View. This should
    /// send the first request, after which the cell should wait for a response,
    /// call another request, wait, etc.
    ///
    /// - returns: `True`, if any request has been made, `false` if the cell does not
    ///            provide any refreshing mechanism.
    func startRefreshing() -> Bool {
        return false
    }
    
    /// This method should return whether the given type is supported by the model cell
    /// implementation.
    func supports(_ messageType: MeshMessage.Type) -> Bool {
        return false
    }
    
    /// A callback called whenever a Mesh Message has been received
    /// from the mesh network.
    ///
    /// - parameters:
    ///   - manager:     The manager which has received the message.
    ///   - message:     The received message.
    ///   - source:      The Unicast Address of the Element from which
    ///                  the message was sent.
    ///   - destination: The address to which the message was sent.
    /// - returns: `True`, when another request has been made, `false` if
    ///            the request has complete.
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            didReceiveMessage message: MeshMessage,
                            sentFrom source: Address, to destination: MeshAddress) -> Bool {
        return false
    }

}
