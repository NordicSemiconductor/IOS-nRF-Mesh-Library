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

import UIKit
import NordicMesh

class FirmwareUpdateViewCell: ModelViewCell {
    // MARK: - Properties
    private var status: FirmwareUpdateStatus?
    
    // MARK: - Outlets and Actions
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var phaseLabel: UILabel!
    @IBOutlet weak var updateTtlLabel: UILabel!
    @IBOutlet weak var additionalInformationLabel: UILabel!
    @IBOutlet weak var updateTimeoutBaseLabel: UILabel!
    @IBOutlet weak var blobIdLabel: UILabel!
    @IBOutlet weak var imageIndexLabel: UILabel!

    @IBOutlet weak var getButton: UIButton!
    @IBAction func getStatusTapped(_ sender: UIButton) {
        readUpdateStatus()
    }
    @IBOutlet weak var cancelButton: UIButton!
    @IBAction func cancelTapped(_ sender: UIButton) {
        cancelUpdate()
    }
    @IBOutlet weak var applyButton: UIButton!
    @IBAction func applyTapped(_ sender: UIButton) {
        applyFirmware()
    }
    
    // MARK: - Implementation
    
    override func reload(using model: Model) {
        let localProvisioner = MeshNetworkManager.instance.meshNetwork?.localProvisioner
        let isEnabled = localProvisioner?.hasConfigurationCapabilities ?? false
        
        getButton.isEnabled = isEnabled
        cancelButton.isEnabled = isEnabled
        applyButton.isEnabled = isEnabled && status?.updatePhase.canApply ?? false
    }
    
    override func startRefreshing() -> Bool {
        if !model.boundApplicationKeys.isEmpty {
            readUpdateStatus()
            return true
        }
        return false
    }
    
    override func supports(_ messageType: MeshMessage.Type) -> Bool {
        return messageType == FirmwareUpdateStatus.self
    }
    
    override func meshNetworkManager(_ manager: MeshNetworkManager,
                                     didReceiveMessage message: MeshMessage,
                                     sentFrom source: Address, to destination: MeshAddress) -> Bool {
        switch message {
        case let status as FirmwareUpdateStatus:
            self.status = status
            statusLabel.text = "\(status.status)"
            phaseLabel.text = "\(status.updatePhase)"
            if let ttl = status.updateTtl,
               let additionalInformation = status.additionalInformation,
               let timeoutBase = status.updateTimeoutBase,
               let blobId = status.blobId,
               let imageIndex = status.imageIndex {
                updateTtlLabel.text = "\(ttl)"
                additionalInformationLabel.text = "\(additionalInformation)"
                updateTimeoutBaseLabel.text = "\(timeoutBase)"
                blobIdLabel.text = "\(blobId)"
                imageIndexLabel.text = "\(imageIndex)"
            } else {
                updateTtlLabel.text = "N/A"
                additionalInformationLabel.text = "N/A"
                updateTimeoutBaseLabel.text = "N/A"
                blobIdLabel.text = "N/A"
                imageIndexLabel.text = "N/A"
            }
            applyButton.isEnabled = status.updatePhase.canApply
            return false
            
        default:
            fatalError()
        }
    }

}

private extension FirmwareUpdateViewCell {
    
    func readUpdateStatus() {
        guard !model.boundApplicationKeys.isEmpty else {
            parentViewController?.presentAlert(
                title: "Bound key required",
                message: "Bind at least one Application Key before sending the message.")
            return
        }
        
        delegate?.send(FirmwareUpdateGet(), description: "Reading status...")
    }
    
    func cancelUpdate() {
        guard !model.boundApplicationKeys.isEmpty else {
            parentViewController?.presentAlert(
                title: "Bound key required",
                message: "Bind at least one Application Key before sending the message.")
            return
        }
        
        delegate?.send(FirmwareUpdateCancel(), description: "Cancelling update...")
    }
    
    func applyFirmware() {
        guard !model.boundApplicationKeys.isEmpty else {
            parentViewController?.presentAlert(
                title: "Bound key required",
                message: "Bind at least one Application Key before sending the message.")
            return
        }
        
        delegate?.send(FirmwareUpdateApply(), description: "Applying update...")
    }
    
}
