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
import UIKit
import nRFMeshProvision

protocol OobSelector {
    // Empty
}

extension OobSelector where Self: UIViewController {
    
    func presentOobPublicKeyDialog(for unprovisionedDevice: UnprovisionedDevice,
                                   callback: @escaping (PublicKey) -> Void) {
        let oobLocation = unprovisionedDevice.oobInformation
        let location = oobLocation.isEmpty ? "" : "\nLocation: \(oobLocation)"
        let message = "Enter the 128-character hexadecimal Public Key of the device.\(location)"
        let skipAction = UIAlertAction(title: "Skip", style: .destructive) { _ in
            callback(.noOobPublicKey)
        }
        presentTextAlert(title: "Public Key", message: message,
                         type: .publicKeyRequired, option: skipAction, cancelHandler: nil) { hex in
            callback(.oobPublicKey(key: Data(hex: hex)))
        }
    }
    
    func presentOobOptionsDialog(for provisioningManager: ProvisioningManager,
                                 from item: UIBarButtonItem,
                                 callback: @escaping (AuthenticationMethod) -> Void) {
        guard let capabilities = provisioningManager.provisioningCapabilities else {
            return
        }
        
        let alert = UIAlertController(title: "Select OOB Type", message: nil, preferredStyle: .actionSheet)
        if !capabilities.oobType.contains(.onlyOobAuthenticatedProvisioningSupported) {
            alert.addAction(UIAlertAction(title: "No OOB", style: .destructive) { _ in
                callback(.noOob)
            })
        }
        if capabilities.oobType.contains(.staticOobInformationAvailable) {
            alert.addAction(UIAlertAction(title: "Static OOB", style: .default) { _ in
                callback(.staticOob)
            })
        }
        if !capabilities.outputOobActions.isEmpty {
            alert.addAction(UIAlertAction(title: "Output OOB", style: .default) { _ in
                self.presentOutputOobOptionsDialog(for: provisioningManager, from: item, callback: callback)
            })
        }
        if !capabilities.inputOobActions.isEmpty {
            alert.addAction(UIAlertAction(title: "Input OOB", style: .default) { _ in
                self.presentInputOobOptionsDialog(for: provisioningManager, from: item, callback: callback)
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.popoverPresentationController?.barButtonItem = item
        present(alert, animated: true)
    }
    
    func presentOutputOobOptionsDialog(for provisioningManager: ProvisioningManager,
                                       from item: UIBarButtonItem,
                                       callback: @escaping (AuthenticationMethod) -> Void) {
        guard let capabilities = provisioningManager.provisioningCapabilities else {
            return
        }
        let actions = capabilities.outputOobActions
        let size = capabilities.outputOobSize
        
        let alert = UIAlertController(title: "Select Output OOB Type", message: nil, preferredStyle: .actionSheet)
        if actions.contains(.blink) { alert.addAction(action(for: .blink, size: size, callback: callback)) }
        if actions.contains(.beep) { alert.addAction(action(for: .beep, size: size, callback: callback)) }
        if actions.contains(.vibrate) { alert.addAction(action(for: .vibrate, size: size, callback: callback)) }
        if actions.contains(.outputNumeric) { alert.addAction(action(for: .outputNumeric, size: size, callback: callback)) }
        if actions.contains(.outputAlphanumeric) { alert.addAction(action(for: .outputAlphanumeric, size: size, callback: callback)) }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.popoverPresentationController?.barButtonItem = item
        present(alert, animated: true)
    }
    
    func presentInputOobOptionsDialog(for provisioningManager: ProvisioningManager,
                                      from item: UIBarButtonItem,
                                      callback: @escaping (AuthenticationMethod) -> Void) {
        guard let capabilities = provisioningManager.provisioningCapabilities else {
            return
        }
        let actions = capabilities.inputOobActions
        let size = capabilities.inputOobSize
        
        let alert = UIAlertController(title: "Select Input OOB Type", message: nil, preferredStyle: .actionSheet)
        if actions.contains(.push) { alert.addAction(action(for: .push, size: 1, callback: callback)) }
        if actions.contains(.twist) { alert.addAction(action(for: .twist, size: 1, callback: callback)) }
        if actions.contains(.inputNumeric) { alert.addAction(action(for: .inputNumeric, size: size, callback: callback)) }
        if actions.contains(.inputAlphanumeric) { alert.addAction(action(for: .inputAlphanumeric, size: size, callback: callback)) }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.popoverPresentationController?.barButtonItem = item
        present(alert, animated: true)
    }
    
    /// Creates an UIAlertAction for given Output Action for user to select.
    ///
    /// - parameters:
    ///   - action: The Output Action.
    ///   - size:   The number of digits or alphanumerics to display on the device.
    ///             For other actions, the device will pick a random number in range from
    ///             1..<10^size and will perform the action this number of times.
    /// - returns: The UIAlertAction for given action.
    private func action(for action: OutputAction, size: UInt8,
                        callback: @escaping (AuthenticationMethod) -> Void) -> UIAlertAction {
        return UIAlertAction(title: "\(action)", style: .default) { _ in
            callback(.outputOob(action: action, size: size))
        }
    }
    
    /// Creates an UIAlertAction for given Input Action for user to select.
    ///
    /// - parameters:
    ///   - action: The Input Action.
    ///   - size:   The number of digits or alphanumerics to display on the phone.
    ///             For other actions, the Provisioner will pick a random number
    ///             in range from 1..<10^size and display it for the user to perform
    ///             the action this many times on the device that is being provisioned.
    /// - returns: The UIAlertAction for given action.
    private func action(for action: InputAction, size: UInt8,
                        callback: @escaping (AuthenticationMethod) -> Void) -> UIAlertAction {
        return UIAlertAction(title: "\(action)", style: .default) { _ in
            callback(.inputOob(action: action, size: size))
        }
    }
    
}
