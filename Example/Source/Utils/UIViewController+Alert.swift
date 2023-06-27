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

extension Selector {
    
    static let name = #selector(UIViewController.nameOptional(_:))
    static let nameRequired = #selector(UIViewController.nameRequired(_:))
    static let numberRequired = #selector(UIViewController.numberRequired(_:))
    static let unsignedNumberRequired = #selector(UIViewController.unsignedNumberRequired(_:))
    static let validAddressRequired = #selector(UIViewController.validAddressRequired(_:))
    static let unicastAddress = #selector(UIViewController.unicastAddressOptional(_:))
    static let unicastAddressRequired = #selector(UIViewController.unicastAddressRequired(_:))
    static let groupAddress = #selector(UIViewController.groupAddressOptional(_:))
    static let groupAddressRequired = #selector(UIViewController.groupAddressRequired(_:))
    static let scene = #selector(UIViewController.sceneOptional(_:))
    static let sceneRequired = #selector(UIViewController.sceneRequired(_:))
    static let key16Required = #selector(UIViewController.key16Required(_:))
    static let key32Required = #selector(UIViewController.key32Required(_:))
    static let publicKeyRequired = #selector(UIViewController.publicKeyRequired(_:))
    static let ttlRequired = #selector(UIViewController.ttlRequired(_:))
    
}

extension UIViewController {
    
    /// Shows a confirmation action sheet with given title and message.
    /// The handler will be executed when user selects Confirm action.
    ///
    /// - parameters:
    ///   - title:   The alert title.
    ///   - message: The message below the title.
    ///   - onCancel:The Cancel button handler.   
    ///   - handler: The Confirm button handler.
    func confirm(title: String?, message: String?, onCancel: ((UIAlertAction) -> Void)? = nil, handler: ((UIAlertAction) -> Void)? = nil) {
        // TODO: Should only iPad be handled differently? How about carPlay or Apple TV?
        let ipad = UIDevice.current.userInterfaceIdiom == .pad
        let style: UIAlertController.Style = ipad ? .alert : .actionSheet
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let alert = UIAlertController(title: title, message: message, preferredStyle: style)
            alert.addAction(UIAlertAction(title: "Confirm", style: .destructive, handler: handler))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: onCancel))
            self.present(alert, animated: true)
        }
    }
    
    /// Displays an alert dialog with given title and message.
    /// The alert dialog will contain an OK or Cancel button, depending
    /// on the `cancelable` parameter.
    ///
    /// - parameters:
    ///   - title:      The alert title.
    ///   - message:    The message below the title.
    ///   - cancelable: Should the alert be cancelable with Cancel button (`true`), or not (then "OK" button).
    ///   - action:     An optional second action.
    ///   - handler:    The OK button handler.
    func presentAlert(title: String?, message: String?, cancelable: Bool = false,
                      option action: UIAlertAction? = nil,
                      handler: ((UIAlertAction) -> Void)? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: cancelable ? "Cancel" : "OK", style: .cancel, handler: handler))
            if let action = action {
                alert.addAction(action)
            }
            self.present(alert, animated: true)
        }
    }
    
    /// Displays an alert dialog with given title and message.
    ///
    /// - parameters:
    ///   - title:      The alert title.
    ///   - message:    The message below the title.
    ///   - actions:    Alert actions.
    ///   - preferredStype: The style to use when presenting the alert controller.
    func presentAlert(title: String?, message: String?,
                      options actions: [UIAlertAction],
                      preferredStyle: UIAlertController.Style = .alert) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let alert = UIAlertController(title: title, message: message, preferredStyle: preferredStyle)
            actions.forEach { alert.addAction($0) }
            self.present(alert, animated: true)
        }
    }
    
    /// Displays an alert dialog with given title and message.
    /// The alert dialog will contain two Text Fields allowing to
    /// specify a Range.
    ///
    /// - parameters:
    ///   - title:    The alert title.
    ///   - message:  The message below the title.
    ///   - range:    The initial value for the text fields.
    ///   - selector: An optional validator for the text fields.
    ///   - handler:  The OK button handler.
    func presentRangeAlert(title: String?, message: String?, range: RangeObject? = nil,
                           type selector: Selector? = nil,
                           handler: ((ClosedRange<UInt16>) -> Void)? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            var alert: UIAlertController? = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert!.addTextField { textField in
                textField.text                   = range?.lowerBound.hex
                textField.placeholder            = "Lower bound, e.g. 0001"
                textField.clearButtonMode        = .whileEditing
                textField.returnKeyType          = .next
                textField.keyboardType           = .alphabet
                textField.autocapitalizationType = .allCharacters
                if let selector = selector {
                    textField.addTarget(self, action: selector, for: .editingChanged)
                    textField.addTarget(self, action: selector, for: .editingDidBegin)
                }
            }
            alert!.addTextField { textField in
                textField.text                   = range?.upperBound.hex
                textField.placeholder            = "Upper bound, e.g. AFFF"
                textField.clearButtonMode        = .whileEditing
                textField.returnKeyType          = .next
                textField.keyboardType           = .alphabet
                textField.autocapitalizationType = .allCharacters
                if let selector = selector {
                    textField.addTarget(self, action: selector, for: .editingChanged)
                    textField.addTarget(self, action: selector, for: .editingDidBegin)
                }
            }
            alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                if let alert = alert {
                    let lowerBound = UInt16(alert.textFields![0].text!, radix: 16)
                    let upperBound = UInt16(alert.textFields![1].text!, radix: 16)
                    
                    if let lowerBound = lowerBound, let upperBound = upperBound {
                        handler?(lowerBound...upperBound)
                    }
                }
                alert = nil
            }))
            alert!.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.present(alert!, animated: true)
        }
    }
    
    /// Displays an alert dialog with given title and message and
    /// a text field with initial text and placeholder.
    /// Use type parameter to set the value validator.
    ///
    /// - parameters:
    ///   - title:         The alert title.
    ///   - message:       The message below the title.
    ///   - text:          Initial value of the text field.
    ///   - placeholder:   The placeholder if text is empty.
    ///   - type:          The selector to be used for value validation.
    ///   - action:        An optional additional action.
    ///   - cancelHandler: The Cancel button handler.
    ///   - handler:       The OK button handler.
    func presentTextAlert(title: String?, message: String?, text: String? = "", placeHolder: String? = "",
                          type selector: Selector? = nil, option action: UIAlertAction? = nil,
                          cancelHandler: (() -> Void)? = nil, handler: ((String) -> Void)? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            var alert: UIAlertController? = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert!.addTextField { textField in
                textField.text                   = text
                textField.placeholder            = placeHolder
                textField.clearButtonMode        = .whileEditing
                textField.returnKeyType          = .done
                textField.keyboardType           = .alphabet
                
                if let selector = selector {
                    textField.addTarget(self, action: selector, for: .editingChanged)
                    textField.addTarget(self, action: selector, for: .editingDidBegin)
                    
                    switch selector {
                    case .nameRequired, .name:
                        textField.autocapitalizationType = .words
                        break
                    case .unicastAddress, .groupAddress,
                         .unicastAddressRequired, .groupAddressRequired,
                         .scene, .sceneRequired:
                        textField.autocapitalizationType = .allCharacters
                    case .ttlRequired:
                        textField.keyboardType = .numberPad
                    default:
                        break
                    }
                }
            }
            alert!.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                if let text = alert?.textFields![0].text {
                    handler?(text)
                }
                alert = nil
            })
            if let action = action {
                alert!.addAction(action)
            }
            alert!.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                cancelHandler?()
            })
            self.present(alert!, animated: true)
        }
    }
    
    /// Displays an alert dialog with given title and message and
    /// a text field with initial text and placeholder.
    ///
    /// - parameters:
    ///   - title:       The alert title.
    ///   - message:     The message below the title.
    ///   - key:         Initial value of the text field.
    ///   - handler:     The OK or Generate button handler.
    func presentKeyDialog(title: String?, message: String?, key: Data? = nil,
                          handler: ((Data) -> Void)? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            var alert: UIAlertController? = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert!.addTextField { textField in
                textField.text                   = key?.hex ?? Data.random128BitKey().hex
                textField.placeholder            = "E.g. 001122334455667788990AABBCCDDEEFF"
                textField.clearButtonMode        = .whileEditing
                textField.returnKeyType          = .done
                textField.keyboardType           = .alphabet
                textField.autocapitalizationType = .allCharacters
                
                textField.addTarget(self, action: .key16Required, for: .editingChanged)
                textField.addTarget(self, action: .key16Required, for: .editingDidBegin)
            }
            alert!.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                if let handler = handler,
                   let hex = alert?.textFields![0].text {
                    let data = Data(hex: hex)
                    if !data.isEmpty {
                        handler(data)
                    }
                }
                alert = nil
            })
            alert!.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.present(alert!, animated: true)
        }
    }
    
    // MARK: - Validators
    
    @objc func ttlRequired(_ textField: UITextField) {
        let alert = getAlert(from: textField)
        let ttl = UInt8(textField.text!)
        alert.setValid(ttl != nil && (ttl! == 0 || ttl! >= 2) && ttl! <= 127)
    }
    
    @objc func numberRequired(_ textField: UITextField) {
        let alert = getAlert(from: textField)
        let number = Int(textField.text!)
        alert.setValid(number != nil)
    }
    
    @objc func unsignedNumberRequired(_ textField: UITextField) {
        let alert = getAlert(from: textField)
        let number = UInt(textField.text!)
        alert.setValid(number != nil)
    }
    
    @objc func nameOptional(_ textField: UITextField) {
        // Empty
    }
    
    @objc func nameRequired(_ textField: UITextField) {
        let alert = getAlert(from: textField)
        alert.setValid(textField.text != "")
    }
    
    @objc func unicastAddressOptional(_ textField: UITextField) {
        let alert = getAlert(from: textField)
        
        if let text = textField.text, !text.isEmpty {
            if let address = UInt16(text, radix: 16) {
                alert.setValid(address.isUnicast)
            } else {
                alert.setValid(false)
            }
        } else {
            alert.setValid(true)
        }
    }
    
    @objc func groupAddressOptional(_ textField: UITextField) {
        let alert = getAlert(from: textField)
        
        if let text = textField.text, !text.isEmpty {
            if let address = UInt16(text, radix: 16) {
                alert.setValid(address.isGroup)
            } else {
                alert.setValid(false)
            }
        } else {
            alert.setValid(true)
        }
    }
    
    @objc func sceneOptional(_ textField: UITextField) {
        let alert = getAlert(from: textField)
        
        if let text = textField.text, !text.isEmpty {
            if let scene = UInt16(text, radix: 16) {
                alert.setValid(scene.isValidSceneNumber)
            } else {
                alert.setValid(false)
            }
        } else {
            alert.setValid(true)
        }
    }
    
    @objc func validAddressRequired(_ textField: UITextField) {
        let alert = getAlert(from: textField)
        
        if validateRange(in: alert, validator: { $0.isValidAddress }) {
            return
        }
        if let text = textField.text, let address = UInt16(text, radix: 16) {
            alert.setValid(address.isValidAddress)
        } else {
            alert.setValid(false)
        }
    }
    
    @objc func unicastAddressRequired(_ textField: UITextField) {
        let alert = getAlert(from: textField)
        
        if validateRange(in: alert, validator: { $0.isUnicast }) {
            return
        }
        if let text = textField.text, let address = UInt16(text, radix: 16) {
            alert.setValid(address.isUnicast)
        } else {
            alert.setValid(false)
        }
    }
    
    @objc func groupAddressRequired(_ textField: UITextField) {
        let alert = getAlert(from: textField)
        
        if validateRange(in: alert, validator: { $0.isGroup && $0 <= Address.maxGroupAddress }) {
            return
        }
        if let text = textField.text, let address = UInt16(text, radix: 16) {
            alert.setValid(address.isGroup && address <= Address.maxGroupAddress)
        } else {
            alert.setValid(false)
        }
    }
    
    @objc func sceneRequired(_ textField: UITextField) {
        let alert = getAlert(from: textField)
        
        if validateRange(in: alert, validator: { $0.isValidSceneNumber }) {
            return
        }
        if let text = textField.text, let scene = UInt16(text, radix: 16) {
            alert.setValid(scene.isValidSceneNumber)
        } else {
            alert.setValid(false)
        }
    }
    
    private func validateRange(in alert: UIAlertController, validator: (UInt16) -> Bool) -> Bool {
        if alert.textFields!.count == 2 {
            let lowerBoundField = alert.textFields![0]
            let upperBoundField = alert.textFields![1]
            
            if let lower = lowerBoundField.text, let lowerBound = UInt16(lower, radix: 16),
               let upper = upperBoundField.text, let upperBound = UInt16(upper, radix: 16) {
                alert.setValid(validator(lowerBound) && validator(upperBound) && upperBound >= lowerBound)
            } else {
                alert.setValid(false)
            }
            // Ranges were validated.
            return true
        }
        // Alert does not contained a range.
        return false
    }
    
    @objc func key16Required(_ textField: UITextField) {
        let alert = getAlert(from: textField)
        
        if let text = textField.text {
            // A valid key is 16 bytes long (128-bit).
            alert.setValid(text.count == 32 && Data(hex: text).count == 16)
        } else {
            alert.setValid(false)
        }
    }
    
    @objc func key32Required(_ textField: UITextField) {
        let alert = getAlert(from: textField)
        
        if let text = textField.text {
            // A valid key is 32 bytes long (256-bit).
            alert.setValid(text.count == 64 && Data(hex: text).count == 32)
        } else {
            alert.setValid(false)
        }
    }
    
    @objc func publicKeyRequired(_ textField: UITextField) {
        let alert = getAlert(from: textField)
        
        if let text = textField.text {
            // A valid key is 2 * 32 bytes long.
            alert.setValid(text.count == 128 && Data(hex: text).count == 64)
        } else {
            alert.setValid(false)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Returns the reference to the UIAlertController.
    ///
    /// - parameter responder: The responder used to search for the alert.
    /// - returns: The active UIAlertController instance.
    private func getAlert(from responder: UIResponder) -> UIAlertController {
        // Hold my beer and watch this: how to get a reference to the alert.
        // Inspired by: https://github.com/mattneub/Programming-iOS-Book-Examples/blob/86fa1b2f57916fcf717945d24c2432143b25865b/bk2ch13p620dialogsOniPhone/ch26p888dialogsOniPhone/ViewController.swift#L59
        var resp: UIResponder! = responder
        while !(resp is UIAlertController) { resp = resp.next }
        return resp as! UIAlertController
    }
    
}

private extension UIAlertController {
    
    func setValid(_ valid: Bool) {
        // Assuming OK button as first action!
        actions[0].isEnabled = valid
    }
    
}

extension UIView {
    
    /// First found parent UIViewController.
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
    
}
