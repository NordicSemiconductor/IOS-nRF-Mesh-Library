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

struct RuntimeVendorMessage: VendorMessage {
    let opCode: UInt32
    let parameters: Data?
    
    var isSegmented: Bool = false
    var security: MeshMessageSecurity = .low
    
    init(opCode: UInt8, for model: Model, parameters: Data?) {
        self.opCode = (UInt32(0xC0 | opCode) << 16) | UInt32(model.companyIdentifier!.bigEndian)
        self.parameters = parameters
    }
    
    init?(parameters: Data) {
        // This init will never be used, as it's used for incoming messages.
        return nil
    }
}

extension RuntimeVendorMessage: CustomDebugStringConvertible {

    var debugDescription: String {
        let hexOpCode = String(format: "%2X", opCode)
        return "RuntimeVendorMessage(opCode: \(hexOpCode), parameters: \(parameters!.hex), isSegmented: \(isSegmented), security: \(security))"
    }
    
}

class VendorModelViewCell: ModelViewCell, UITextFieldDelegate {
    
    @IBOutlet weak var opCodeField: UITextField!
    @IBOutlet weak var parametersField: UITextField!
    @IBOutlet weak var responseOpCodeLabel: UILabel!
    @IBOutlet weak var responseParametersLabel: UILabel!
    
    @IBAction func valueDidChange(_ sender: UITextField) {
        if let opCode = UInt8(opCodeField.text!, radix: 16), opCode <= 0x3F,
           !Data(hex: parametersField.text!).isEmpty {
            sendButton.isEnabled = true
        } else {
            sendButton.isEnabled = false
        }
    }
    
    @IBOutlet weak var acknowledgmentSwitch: UISwitch!
    @IBOutlet weak var transMicSwitch: UISwitch!
    @IBAction func transMicDidChange(_ sender: UISwitch) {
        if sender.isOn {
            forceSegmentationSwitch.setOn(true, animated: true)
        }
        forceSegmentationSwitch.isEnabled = !sender.isOn
    }
    @IBOutlet weak var forceSegmentationSwitch: UISwitch!
    
    @IBOutlet weak var sendButton: UIButton!
    @IBAction func sendTapped(_ sender: UIButton) {
        send()
    }
    @IBAction func sendActionTapped(_ sender: UITextField) {
        send()
    }
    
    // MARK: - Implementation
    
    override func reload(using model: Model) {
        let localProvisioner = MeshNetworkManager.instance.meshNetwork?.localProvisioner
        let isEnabled = localProvisioner?.hasConfigurationCapabilities ?? false
        
        acknowledgmentSwitch.isEnabled = isEnabled
        transMicSwitch.isEnabled = isEnabled
        forceSegmentationSwitch.isEnabled = isEnabled
        opCodeField.isEnabled = isEnabled
        parametersField.isEnabled = isEnabled
        sendButton.isEnabled = isEnabled
    }
    
    override func awakeFromNib() {
        opCodeField.delegate = self
        parametersField.delegate = self
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == opCodeField {
            parametersField.becomeFirstResponder()
            return false
        }
        return true
    }
    
    override func supports(_ messageType: MeshMessage.Type) -> Bool {
        return messageType == UnknownMessage.self
    }
    
    override func meshNetworkManager(_ manager: MeshNetworkManager,
                                     didReceiveMessage message: MeshMessage,
                                     sentFrom source: Address, to destination: Address) -> Bool {
        switch message {
        case let message as UnknownMessage where
            (message.opCode & 0xC0FFFF) == (0xC00000 | UInt32(model.companyIdentifier!.bigEndian)):
            responseOpCodeLabel.text = String(format: "0x%02X", (message.opCode >> 16) & 0x3F)
            responseParametersLabel.text = message.parameters != nil && !message.parameters!.isEmpty ?
                "0x\(message.parameters!.hex)" : "Empty"
            return false
            
        default:
            fatalError()
        }
    }
    
    override func meshNetworkManager(_ manager: MeshNetworkManager,
                                     didSendMessage message: MeshMessage,
                                     from localElement: Element, to destination: Address) -> Bool {
        // For acknowledged messages wait for the Acknowledgement Message.
        return acknowledgmentSwitch.isOn
    }
}

private extension VendorModelViewCell {
    
    /// Sends the Vendor Message with the opcode and parameters given
    /// by the user.
    func send() {
        opCodeField.resignFirstResponder()
        parametersField.resignFirstResponder()
        
        guard !model.boundApplicationKeys.isEmpty else {
            parentViewController?.presentAlert(
                title: "Bound key required",
                message: "Bind at least one Application Key before sending the message.")
            return
        }
        
        // Clear the response fields.
        responseOpCodeLabel.text = nil
        responseParametersLabel.text = nil
        
        if let opCode = UInt8(opCodeField.text!, radix: 16) {
            let parameters = Data(hex: parametersField.text!)
            var message = RuntimeVendorMessage(opCode: opCode, for: model, parameters: parameters)
            message.isSegmented = forceSegmentationSwitch.isOn
            message.security = transMicSwitch.isOn ? .high : .low
            delegate?.send(message, description: "Sending message...")
        }
    }
    
}
