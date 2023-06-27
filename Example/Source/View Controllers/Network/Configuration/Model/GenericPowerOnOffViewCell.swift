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

class GenericPowerOnOffViewCell: ModelViewCell {
    
    // MARK: - Outlets and Actions
    @IBOutlet weak var currentStatusLabel: UILabel!
    
    @IBOutlet weak var readButton: UIButton!
    @IBAction func readTapped(_ sender: UIButton) {
        readGenericOnPowerUpState()
    }
        
    // MARK: - Implementation
    
    override func reload(using model: Model) {
        let localProvisioner = MeshNetworkManager.instance.meshNetwork?.localProvisioner
        let isEnabled = localProvisioner?.hasConfigurationCapabilities ?? false
        
        readButton.isEnabled = isEnabled
    }
    
    override func startRefreshing() -> Bool {
        if !model.boundApplicationKeys.isEmpty {
            readGenericOnPowerUpState()
            return true
        }
        return false
    }
    
    override func supports(_ messageType: MeshMessage.Type) -> Bool {
        return messageType == GenericOnPowerUpStatus.self
    }
    
    override func meshNetworkManager(_ manager: MeshNetworkManager,
                                     didReceiveMessage message: MeshMessage,
                                     sentFrom source: Address, to destination: MeshAddress) -> Bool {
        switch message {
        case let status as GenericOnPowerUpStatus:
            currentStatusLabel.text = status.state.debugDescription
            return false
            
        default:
            fatalError()
        }
    }
}

private extension GenericPowerOnOffViewCell {
        
    func readGenericOnPowerUpState() {
        guard !model.boundApplicationKeys.isEmpty else {
            parentViewController?.presentAlert(
                title: "Bound key required",
                message: "Bind at least one Application Key before sending the message.")
            return
        }

        
        delegate?.send(GenericOnPowerUpGet(), description: "Reading state...")
    }
}
