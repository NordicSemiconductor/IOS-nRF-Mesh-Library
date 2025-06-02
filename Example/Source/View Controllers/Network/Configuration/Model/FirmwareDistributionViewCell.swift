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

class FirmwareDistributionViewCell: ModelViewCell {
    // MARK: - Properties
    private var status: FirmwareDistributionStatus?
    
    // MARK: - Outlets and Actions
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var phaseLabel: UILabel!
    @IBOutlet weak var multicastAddress: UILabel!
    @IBOutlet weak var appKeyNameLabel: UILabel!
    @IBOutlet weak var boundNetKeyLabel: UILabel!
    @IBOutlet weak var distributionTtlLabel: UILabel!
    @IBOutlet weak var distributionTimeoutBaseLabel: UILabel!
    @IBOutlet weak var transferMode: UILabel!
    @IBOutlet weak var updatePolicy: UILabel!
    @IBOutlet weak var imageIndexLabel: UILabel!
    
    @IBOutlet weak var getButton: UIButton!
    @IBAction func getStatusTapped(_ sender: UIButton) {
        readDistributionStatus()
    }
    @IBOutlet weak var cancelButton: UIButton!
    @IBAction func cancelTapped(_ sender: UIButton) {
        cancelDistribution()
    }
    @IBOutlet weak var suspendResumeButton: UIButton!
    @IBAction func suspendResumeTapped(_ sender: UIButton) {
        guard let status = status else {
            return
        }
        if status.phase == .transferSuspended {
            resumeDistribution(status)
        } else {
            suspendDistribution()
        }
    }
    @IBOutlet weak var applyButton: UIButton!
    @IBAction func applyTapped(_ sender: UIButton) {
        applyFirmware()
    }
    
    @IBOutlet weak var maxReceiversListSize: UILabel!
    @IBOutlet weak var maxFirmwareImagesListSize: UILabel!
    @IBOutlet weak var maxFirmwareImageSize: UILabel!
    @IBOutlet weak var maxUploadSpace: UILabel!
    @IBOutlet weak var remainingUploadSpace: UILabel!
    @IBOutlet weak var supportedUriSchemes: UILabel!
    
    @IBOutlet weak var readButton: UIButton!
    @IBAction func readTapped(_ sender: UIButton) {
        readCapabilities()
    }
        
    // MARK: - Implementation
    
    override func reload(using model: Model) {
        let localProvisioner = MeshNetworkManager.instance.meshNetwork?.localProvisioner
        let isEnabled = localProvisioner?.hasConfigurationCapabilities ?? false
        
        readButton.isEnabled = isEnabled
        getButton.isEnabled = isEnabled
        cancelButton.isEnabled = isEnabled
        suspendResumeButton.isEnabled = isEnabled && status?.phase.isSuspendable ?? false
        applyButton.isEnabled = isEnabled && status?.phase.canApply ?? false
    }
    
    override func startRefreshing() -> Bool {
        if !model.boundApplicationKeys.isEmpty {
            readDistributionStatus()
            return true
        }
        return false
    }
    
    override func supports(_ messageType: MeshMessage.Type) -> Bool {
        return messageType == FirmwareDistributionCapabilitiesStatus.self
            || messageType == FirmwareDistributionStatus.self
    }
    
    override func meshNetworkManager(_ manager: MeshNetworkManager,
                                     didReceiveMessage message: MeshMessage,
                                     sentFrom source: Address, to destination: MeshAddress) -> Bool {
        switch message {
        case let status as FirmwareDistributionStatus:
            self.status = status
            statusLabel.text = "\(status.status)"
            phaseLabel.text = "\(status.phase)"
            if let groupAddress = status.multicastAddress {
                let meshNetwork = MeshNetworkManager.instance.meshNetwork!
                if groupAddress == .unassignedAddress {
                    multicastAddress.text = "Unicast distribution"
                } else if let group = meshNetwork.group(withAddress: MeshAddress(groupAddress)) {
                    multicastAddress.text = group.name
                } else {
                    multicastAddress.text = "0x\(groupAddress.hex)"
                }
                if let applicationKey = meshNetwork.applicationKeys[status.applicationKeyIndex ?? 0] {
                    appKeyNameLabel.text = applicationKey.name
                    boundNetKeyLabel.text = "Bound to \(applicationKey.boundNetworkKey.name)"
                } else {
                    appKeyNameLabel.text = "Unknown"
                    boundNetKeyLabel.text = "Bound to Unknown Network Key"
                }
                appKeyNameLabel.textColor = .label
                distributionTtlLabel.text = "\(status.ttl!)"
                distributionTimeoutBaseLabel.text = "\(status.timeoutBase!)"
                transferMode.text = "\(status.transferMode!)"
                updatePolicy.text = "\(status.updatePolicy!)"
                imageIndexLabel.text = "\(status.firmwareImageIndex!)"
            } else {
                multicastAddress.text = "N/A"
                appKeyNameLabel.text = "N/A"
                appKeyNameLabel.textColor = .secondaryLabel
                boundNetKeyLabel.text = ""
                distributionTtlLabel.text = "N/A"
                distributionTimeoutBaseLabel.text = "N/A"
                transferMode.text = "N/A"
                updatePolicy.text = "N/A"
                imageIndexLabel.text = "N/A"
            }
            suspendResumeButton.isEnabled = status.phase.isSuspendable
            if status.phase == .transferSuspended {
                suspendResumeButton.setTitle("Resume", for: .normal)
            } else {
                suspendResumeButton.setTitle("Suspend", for: .normal)
            }
            applyButton.isEnabled = status.phase.canApply
            if delegate?.isRefreshing ?? false {
                readCapabilities()
                return true
            }
            return false
            
        case let status as FirmwareDistributionCapabilitiesStatus:
            maxReceiversListSize.text = "\(status.maxReceiversCount)"
            maxFirmwareImagesListSize.text = "\(status.maxFirmwareImagesListSize)"
            maxFirmwareImageSize.text = "\(status.maxFirmwareImageSize) bytes"
            maxUploadSpace.text = "\(status.maxUploadSpace) bytes"
            remainingUploadSpace.text = "\(status.remainingUploadSpace) bytes"
            if status.supportedUriSchemes.isEmpty {
                supportedUriSchemes.text = "None"
            } else {
                supportedUriSchemes.text = status.supportedUriSchemes
                    .map { "\($0)" }
                    .joined(separator: ", ")
            }
            return false
            
        default:
            fatalError()
        }
    }
}

private extension FirmwareDistributionViewCell {
    
    func readDistributionStatus() {
        guard !model.boundApplicationKeys.isEmpty else {
            parentViewController?.presentAlert(
                title: "Bound key required",
                message: "Bind at least one Application Key before sending the message.")
            return
        }
        
        delegate?.send(FirmwareDistributionGet(), description: "Reading status...")
    }
    
    func resumeDistribution(_ status: FirmwareDistributionStatus) {
        guard !model.boundApplicationKeys.isEmpty else {
            parentViewController?.presentAlert(
                title: "Bound key required",
                message: "Bind at least one Application Key before sending the message.")
            return
        }
        
        guard let request = FirmwareDistributionStart(resume: status) else {
            return
        }
        delegate?.send(request, description: "Resuming distribution...")
    }
    
    func suspendDistribution() {
        guard !model.boundApplicationKeys.isEmpty else {
            parentViewController?.presentAlert(
                title: "Bound key required",
                message: "Bind at least one Application Key before sending the message.")
            return
        }
        
        delegate?.send(FirmwareDistributionSuspend(), description: "Suspending distribution...")
    }
    
    func cancelDistribution() {
        guard !model.boundApplicationKeys.isEmpty else {
            parentViewController?.presentAlert(
                title: "Bound key required",
                message: "Bind at least one Application Key before sending the message.")
            return
        }
        
        delegate?.send(FirmwareDistributionCancel(), description: "Cancelling distribution...")
    }
    
    func applyFirmware() {
        guard !model.boundApplicationKeys.isEmpty else {
            parentViewController?.presentAlert(
                title: "Bound key required",
                message: "Bind at least one Application Key before sending the message.")
            return
        }
        
        delegate?.send(FirmwareDistributionApply(), description: "Applying changes...")
    }
        
    func readCapabilities() {
        guard !model.boundApplicationKeys.isEmpty else {
            parentViewController?.presentAlert(
                title: "Bound key required",
                message: "Bind at least one Application Key before sending the message.")
            return
        }
        
        delegate?.send(FirmwareDistributionCapabilitiesGet(), description: "Reading capabilities...")
    }
    
}
