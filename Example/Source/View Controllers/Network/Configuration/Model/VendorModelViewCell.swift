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

protocol RuntimeVendorMessage: VendorMessage {
    var isSegmented: Bool { get set }
    var security: MeshMessageSecurity { get set }
}

struct RuntimeUnacknowledgedVendorMessage: RuntimeVendorMessage, UnacknowledgedVendorMessage {
    let opCode: UInt32
    let parameters: Data?
    
    var isSegmented: Bool = false
    var security: MeshMessageSecurity = .low
    
    init(opCode: UInt8, for model: Model, parameters: Data) {
        self.opCode = (UInt32(0xC0 | opCode) << 16) | UInt32(model.companyIdentifier!.bigEndian)
        self.parameters = parameters
    }
    
    init?(parameters: Data) {
        // This init will never be used, as it's used for incoming messages.
        return nil
    }
}

struct RuntimeAcknowledgedVendorMessage: RuntimeVendorMessage, AcknowledgedVendorMessage {
    let opCode: UInt32
    var responseOpCode: UInt32
    let parameters: Data?
    
    var isSegmented: Bool = false
    var security: MeshMessageSecurity = .low
    
    init(opCode: UInt8, responseOpCode: UInt8, for model: Model, parameters: Data) {
        self.opCode = (UInt32(0xC0 | opCode) << 16) | UInt32(model.companyIdentifier!.bigEndian)
        self.responseOpCode = (UInt32(0xC0 | responseOpCode) << 16) | UInt32(model.companyIdentifier!.bigEndian)
        self.parameters = parameters
    }
    
    init?(parameters: Data) {
        // This init will never be used, as it's used for incoming messages.
        return nil
    }
}

extension RuntimeUnacknowledgedVendorMessage: CustomDebugStringConvertible {

    var debugDescription: String {
        let hexOpCode = String(format: "%2X", opCode)
        return "RuntimeVendorMessage(opCode: \(hexOpCode), parameters: \(parameters!.hex), isSegmented: \(isSegmented), security: \(security))"
    }
    
}

extension RuntimeAcknowledgedVendorMessage: CustomDebugStringConvertible {

    var debugDescription: String {
        let hexOpCode = String(format: "%2X", opCode)
        let hexResponseOpCode = String(format: "%2X", responseOpCode)
        return "RuntimeVendorMessage(opCode: \(hexOpCode), responseOpCode: \(hexResponseOpCode) parameters: \(parameters!.hex), isSegmented: \(isSegmented), security: \(security))"
    }
    
}

class VendorModelViewCell: ModelViewCell, UITextFieldDelegate {
    
    @IBOutlet weak var opCodeField: UITextField!
    @IBOutlet weak var parametersField: UITextField!
    @IBOutlet weak var responseOpCodeLabel: UILabel!
    @IBOutlet weak var responseParametersLabel: UILabel!
    
    @IBAction func valueDidChange(_ sender: UITextField) {
        if acknowledgmentSwitch.isOn {
            guard let responseOpCode = UInt8(responseOpCodeField.text!, radix: 16), responseOpCode <= 0x3F else {
                sendButton.isEnabled = false
                return
            }
        }
        guard let opCode = UInt8(opCodeField.text!, radix: 16), opCode <= 0x3F,
              !Data(hex: parametersField.text!).isEmpty else {
            sendButton.isEnabled = false
            return
        }
        sendButton.isEnabled = true
    }
    
    @IBOutlet weak var acknowledgmentSwitch: UISwitch!
    @IBAction func acknowledgedDidChange(_ sender: UISwitch) {
        responseOpCodeField.isEnabled = sender.isOn
    }
    @IBOutlet weak var responseOpCodeField: UITextField!
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
    
    // MARK: - Private members
    
    private var expectedResponseOpCode: UInt8? = nil
    
    // MARK: - Implementation
    
    override func reload(using model: Model) {
        let localProvisioner = MeshNetworkManager.instance.meshNetwork?.localProvisioner
        let isEnabled = localProvisioner?.hasConfigurationCapabilities ?? false
        
        acknowledgmentSwitch.isEnabled = isEnabled
        responseOpCodeField.isEnabled = isEnabled && acknowledgmentSwitch.isOn
        transMicSwitch.isEnabled = isEnabled
        forceSegmentationSwitch.isEnabled = isEnabled
        opCodeField.isEnabled = isEnabled
        parametersField.isEnabled = isEnabled
        sendButton.isEnabled = isEnabled
        
        load(for: model)
    }
    
    override func awakeFromNib() {
        opCodeField.delegate = self
        responseOpCodeField.delegate = self
        parametersField.delegate = self
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == opCodeField {
            parametersField.becomeFirstResponder()
            return false
        }
        if textField == parametersField && acknowledgmentSwitch.isOn {
            responseOpCodeField.becomeFirstResponder()
            return false
        }
        return true
    }
    
    override func supports(_ messageType: MeshMessage.Type) -> Bool {
        return messageType == UnknownMessage.self
    }
    
    override func meshNetworkManager(_ manager: MeshNetworkManager,
                                     didReceiveMessage message: MeshMessage,
                                     sentFrom source: Address, to destination: MeshAddress) -> Bool {
        switch message {
        case let message as UnknownMessage where
            (message.opCode & 0xC0FFFF) == (0xC00000 | UInt32(model.companyIdentifier!.bigEndian)):
            let responseOpCode = (message.opCode >> 16) & 0x3F
            guard expectedResponseOpCode == nil || responseOpCode == expectedResponseOpCode! else {
                return true
            }
            expectedResponseOpCode = nil
            responseOpCodeLabel.text = String(format: "0x%02X", (message.opCode >> 16) & 0x3F)
            responseParametersLabel.text = message.parameters != nil && !message.parameters!.isEmpty ?
                "0x\(message.parameters!.hex)" : "Empty"
            return false
            
        default:
            fatalError()
        }
    }
}

private extension VendorModelViewCell {
    
    /// Sends the Vendor Message with the opcode and parameters given
    /// by the user.
    func send() {
        opCodeField.resignFirstResponder()
        parametersField.resignFirstResponder()
        responseOpCodeField.resignFirstResponder()
        
        guard !model.boundApplicationKeys.isEmpty else {
            parentViewController?.presentAlert(
                title: "Bound key required",
                message: "Bind at least one Application Key before sending the message.")
            return
        }
        
        // Clear the response fields.
        expectedResponseOpCode = nil
        responseOpCodeLabel.text = nil
        responseParametersLabel.text = nil
        
        var opCode: UInt8 = 0
        guard let value = UInt8(opCodeField.text!, radix: 16) else {
            parentViewController?.presentAlert(
                title: "Error",
                message: "Op Code is not valid.\n\nValid values are in range 0x00 - 0x3F.")
            return
        }
        opCode = value
        
        var responseOpCode: UInt8 = 0
        if acknowledgmentSwitch.isOn {
            guard let value = UInt8(responseOpCodeField.text!, radix: 16) else {
                parentViewController?.presentAlert(
                    title: "Error",
                    message: "Response Op Code is not valid.\n\nValid values are in range 0x00 - 0x3F.")
                return
            }
            responseOpCode = value
        }
        
        let parameters = Data(hex: parametersField.text!)
        store(for: model)
        
        var message: RuntimeVendorMessage
        if acknowledgmentSwitch.isOn {
            expectedResponseOpCode = responseOpCode
            message = RuntimeAcknowledgedVendorMessage(opCode: opCode, responseOpCode: responseOpCode,
                                                       for: model, parameters: parameters)
        } else {
            message = RuntimeUnacknowledgedVendorMessage(opCode: opCode,
                                                         for: model, parameters: parameters)
        }
        message.isSegmented = forceSegmentationSwitch.isOn
        message.security = transMicSwitch.isOn ? .high : .low
        delegate?.send(message, description: "Sending message...")
    }
    
    /// Stores the values of all fields in User Default.
    ///
    /// This only stores the most recent value. If a model supports multiple messages
    /// those need to be entered manually anyway.
    ///
    /// - parameter model: The current Model.
    private func store(for model: Model) {
        UserDefaults.standard.set(opCodeField.text!, forKey: "vendor-op-code-\(model.modelIdentifier)")
        UserDefaults.standard.set(parametersField.text!, forKey: "vendor-params-\(model.modelIdentifier)")
        UserDefaults.standard.set(responseOpCodeField.text!, forKey: "vendor-response-op-code-\(model.modelIdentifier)")
        UserDefaults.standard.set(acknowledgmentSwitch.isOn, forKey: "vendor-ack-\(model.modelIdentifier)")
        UserDefaults.standard.set(forceSegmentationSwitch.isOn, forKey: "vendor-seg-\(model.modelIdentifier)")
        UserDefaults.standard.set(transMicSwitch.isOn, forKey: "vendor-trans-mic-\(model.modelIdentifier)")
    }
    
    /// Loads the values user recently for the given model.
    ///
    /// - parameter model: The Model to load values for.
    private func load(for model: Model) {
        opCodeField.text = UserDefaults.standard.string(forKey: "vendor-op-code-\(model.modelIdentifier)")
        parametersField.text = UserDefaults.standard.string(forKey: "vendor-params-\(model.modelIdentifier)")
        responseOpCodeField.text = UserDefaults.standard.string(forKey: "vendor-response-op-code-\(model.modelIdentifier)")
        acknowledgmentSwitch.isOn = UserDefaults.standard.bool(forKey: "vendor-ack-\(model.modelIdentifier)")
        forceSegmentationSwitch.isOn = UserDefaults.standard.bool(forKey: "vendor-seg-\(model.modelIdentifier)")
        transMicSwitch.isOn = UserDefaults.standard.bool(forKey: "vendor-trans-mic-\(model.modelIdentifier)")
    }
    
}
