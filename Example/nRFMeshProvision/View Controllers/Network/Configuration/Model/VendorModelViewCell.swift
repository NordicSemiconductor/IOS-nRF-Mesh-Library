//
//  VendorModelViewCell.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 19/08/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

struct RuntimeVendorMessage: VendorMessage {
    let opCode: UInt32
    let parameters: Data?
    
    init(opCode: UInt8, for model: Model, parameters: Data?) {
        self.opCode = (UInt32(0xC0 | opCode) << 16) | UInt32(model.companyIdentifier!.bigEndian)
        self.parameters = parameters
    }
    
    init?(parameters: Data) {
        // This init will never be used, as it's used for incoming messages.
        return nil
    }
}

class VendorModelViewCell: ModelViewCell, UITextFieldDelegate {
    
    @IBOutlet weak var opCodeField: UITextField!
    @IBOutlet weak var parametersField: UITextField!
    @IBOutlet weak var responseOpCodeLabel: UILabel!
    @IBOutlet weak var responseParametersLabel: UILabel!
    
    @IBAction func valueDidChange(_ sender: UITextField) {
        if let opCode = UInt8(opCodeField.text!, radix: 16), opCode <= 0x3F,
            let _ = Data(hex: parametersField.text!) {
            sendButton.isEnabled = true
        } else {
            sendButton.isEnabled = false
        }
    }
    
    @IBOutlet weak var sendButton: UIButton!
    @IBAction func sendTapped(_ sender: UIButton) {
        send()
    }
    @IBAction func sendActionTapped(_ sender: UITextField) {
        send()
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
        textField.resignFirstResponder()
        return true
    }
    
    override func meshNetwork(_ meshNetwork: MeshNetwork, didDeliverMessage message: MeshMessage, from source: Address) -> Bool {
        switch message {
        case let message as UnknownMessage where
            (message.opCode & 0xC0FFFF) == (0xC00000 | UInt32(model.companyIdentifier!.bigEndian)):
            responseOpCodeLabel.text = String(format: "0x%02X", (message.opCode >> 16) & 0x3F)
            responseParametersLabel.text = message.parameters != nil && !message.parameters!.isEmpty ?
                "0x\(message.parameters!.hex)" : "Empty"
        default:
            break
        }
        return false
    }
}

private extension VendorModelViewCell {
    
    /// Sends the Vendor Message with the opcode and parameters given
    /// by the user.
    func send() {
        guard !model.boundApplicationKeys.isEmpty else {
            parentViewController?.presentAlert(
                title: "Bound key required",
                message: "Bind at least one Application Key before sending the message.")
            return
        }
        if let opCode = UInt8(opCodeField.text!, radix: 16) {
            let parameters = Data(hex: parametersField.text!)
            delegate?.send(RuntimeVendorMessage(opCode: opCode, for: model, parameters: parameters), description: "Sending message...")
        }
    }
    
}
