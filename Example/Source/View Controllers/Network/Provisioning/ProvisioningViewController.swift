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
import NordicMesh

class ProvisioningViewController: UITableViewController {
    static let attentionTimer: UInt8 = 5
    
    // MARK: - Outlets
    @IBOutlet weak var provisionButton: UIBarButtonItem!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var unicastAddressLabel: UILabel!
    @IBOutlet weak var networkKeyLabel: UILabel!
    @IBOutlet weak var networkKeyCell: UITableViewCell!
    
    @IBOutlet weak var elementsCountLabel: UILabel!
    @IBOutlet weak var supportedAlgorithmsLabel: UILabel!
    @IBOutlet weak var publicKeyTypeLabel: UILabel!
    @IBOutlet weak var oobTypeLabel: UILabel!
    @IBOutlet weak var outputOobSizeLabel: UILabel!
    @IBOutlet weak var supportedOutputOobActionsLabel: UILabel!
    @IBOutlet weak var inputOobSizeLabel: UILabel!
    @IBOutlet weak var supportedInputOobActionsLabel: UILabel!
    
    // MARK: - Actions
    
    @IBOutlet weak var actionProvision: UIBarButtonItem!
    @IBAction func provisionTapped(_ sender: UIBarButtonItem) {
        guard bearer.isOpen else {
            openBearer()
            return
        }
        startProvisioning()
    }
    
    // MARK: - Properties
    
    weak var delegate: ProvisioningViewDelegate?
    var unprovisionedDevice: UnprovisionedDevice!
    var bearer: ProvisioningBearer!
    var previousNode: Node?
    
    private var publicKey: PublicKey?
    private var authenticationMethod: AuthenticationMethod?
    
    private var provisioningManager: ProvisioningManager!
    private var capabilitiesReceived = false
    
    private var alert: UIAlertController?
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let manager = MeshNetworkManager.instance
        nameLabel.text = unprovisionedDevice.name
        
        // Obtain the Provisioning Manager instance for the Unprovisioned Device.
        do {
            provisioningManager = try manager.provision(unprovisionedDevice: unprovisionedDevice, over: bearer)
        } catch {
            switch error {
            case MeshNetworkError.nodeAlreadyExist:
                presentAlert(title: "Node already exist", message: "A node with the same UUID already exist in the network. Remove it before reprovisioning.") { _ in
                    self.dismiss(animated: true)
                }
            default:
                presentAlert(title: "Error", message: "A error occurred: \(error.localizedDescription)") { _ in
                    self.dismiss(animated: true)
                }
            }
            return
        }
        provisioningManager.delegate = self
        provisioningManager.logger = MeshNetworkManager.instance.logger
        bearer.delegate = self
        
        // Unicast Address initially will be assigned automatically.
        unicastAddressLabel.text = "Automatic"
        networkKeyLabel.text = provisioningManager.networkKey?.name ?? "New Network Key"
        if provisioningManager.networkKey == nil {
            networkKeyCell.selectionStyle = .none
            networkKeyCell.accessoryType = .none
        }
        actionProvision.isEnabled = manager.meshNetwork!.localProvisioner != nil
        
        // We are now connected. Proceed by sending Provisioning Invite request.
        presentStatusDialog(message: "Identifying...", animated: false) {
            do {
                try self.provisioningManager.identify(andAttractFor: ProvisioningViewController.attentionTimer)
            } catch {
                self.abort()
                self.presentAlert(title: "Error", message: error.localizedDescription)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Make sure the bearer is closed when moving out from this screen.
        if isMovingFromParent {
            bearer.delegate = nil
            try? bearer.close()
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "networkKey" {
            return provisioningManager.networkKey != nil
        }
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "networkKey" {
            let destination = segue.destination as! NetworkKeySelectionViewController
            destination.selectedNetworkKey = provisioningManager.networkKey
            destination.delegate = self
        }
    }
    
    // MARK: - Table View Delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.isDeviceName {
            presentNameDialog()
        }
        if indexPath.isUnicastAddress {
            presentUnicastAddressDialog()
        }
    }
    
}

extension ProvisioningViewController: OobSelector {
    
}

private extension ProvisioningViewController {
    
    /// Presents a dialog to edit the Provisioner name.
    func presentNameDialog() {
        presentTextAlert(title: "Device name", message: nil,
                         text: unprovisionedDevice.name, placeHolder: "Name",
                         type: .nameRequired, cancelHandler: nil) { newName in
                            self.unprovisionedDevice.name = newName
                            self.nameLabel.text = newName
        }
    }
    
    /// Presents a dialog to edit or unbind the Provisioner Unicast Address.
    func presentUnicastAddressDialog() {
        let manager = self.provisioningManager!
        let action = UIAlertAction(title: "Automatic", style: .default) { [weak self] _ in
            guard let self = self else { return }
            manager.unicastAddress = manager.suggestedUnicastAddress
            self.unicastAddressLabel.text = manager.unicastAddress?.asString() ?? "Automatic"
            let deviceSupported = manager.isDeviceSupported == true
            let addressValid = manager.isUnicastAddressValid == true
            self.actionProvision.isEnabled = addressValid && deviceSupported
        }
        presentTextAlert(title: "Unicast address", message: "Hexadecimal value in Provisioner's range.",
                         text: manager.unicastAddress?.hex, placeHolder: "Address", type: .unicastAddressRequired,
                         option: action, cancelHandler: nil) { [weak self] text in
                            guard let self = self else { return }
                            manager.unicastAddress = Address(text, radix: 16)
                            self.unicastAddressLabel.text = manager.unicastAddress!.asString()
                            let deviceSupported = manager.isDeviceSupported == true
                            let addressValid = manager.isUnicastAddressValid == true
                            self.actionProvision.isEnabled = addressValid && deviceSupported
                            if !addressValid {
                                self.presentAlert(title: "Error", message: "Address is not available.")
                            }
        }
    }
    
    func presentStatusDialog(message: String, animated flag: Bool = true, completion: (() -> Void)? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let alert = self.alert {
                alert.message = message
                completion?()
            } else {
                self.alert = UIAlertController(title: "Status", message: message, preferredStyle: .alert)
                self.alert!.addAction(UIAlertAction(title: "Cancel", style: .cancel) { action in
                    action.isEnabled = false
                    self.abort()
                })
                self.present(self.alert!, animated: flag, completion: completion)
            }
        }
    }
    
    func dismissStatusDialog(completion: (() -> Void)? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let alert = self.alert {
                alert.dismiss(animated: true, completion: completion)
            } else {
                completion?()
            }
            self.alert = nil
        }
    }
    
    func abort() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.alert?.title   = "Aborting"
            self.alert?.message = "Cancelling connection..."
            do {
                try self.bearer.close()
            } catch {
                self.dismissStatusDialog() {
                    self.presentAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }
    
}

private extension ProvisioningViewController {    
    
    /// This method tries to open the bearer had it been closed when on this screen.
    func openBearer() {
        presentStatusDialog(message: "Connecting...") { [weak self] in
            guard let self = self else { return }
            do {
                try self.bearer.open()
            } catch {
                self.dismissStatusDialog() {
                    self.presentAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }
    
    /// Starts provisioning process of the device.
    func startProvisioning() {
        guard let capabilities = provisioningManager.provisioningCapabilities else {
            return
        }
        
        // If the device's Public Key is available OOB, it should be read.
        let publicKeyNotAvailable = capabilities.publicKeyType.isEmpty
        guard publicKeyNotAvailable || publicKey != nil else {
            presentOobPublicKeyDialog(for: unprovisionedDevice) { [weak self] publicKey in
                guard let self = self else { return }
                self.publicKey = publicKey
                self.startProvisioning()
            }
            return
        }
        publicKey = publicKey ?? .noOobPublicKey
        
        // If any of OOB methods is supported, it should be chosen.
        let staticOobSupported = capabilities.oobType.contains(.staticOobInformationAvailable)
        let outputOobSupported = !capabilities.outputOobActions.isEmpty
        let inputOobSupported  = !capabilities.inputOobActions.isEmpty
        let anyOobSupported = staticOobSupported || outputOobSupported || inputOobSupported
        guard !anyOobSupported || authenticationMethod != nil else {
            presentOobOptionsDialog(for: provisioningManager, from: provisionButton) { [weak self] method in
                guard let self = self else { return }
                self.authenticationMethod = method
                self.startProvisioning()
            }
            return
        }
        // If none of OOB methods are supported, select the only option left.
        if authenticationMethod == nil {
            authenticationMethod = .noOob
        }
        
        if provisioningManager.networkKey == nil {
            let network = MeshNetworkManager.instance.meshNetwork!
            let networkKey = try! network.add(networkKey: Data.random128BitKey(), name: "Primary Network Key")
            provisioningManager.networkKey = networkKey
        }
        
        // Start provisioning.
        presentStatusDialog(message: "Provisioning...") { [weak self] in
            guard let self = self else { return }
            do {
                try self.provisioningManager.provision(usingAlgorithm:       capabilities.algorithms.strongest,
                                                       publicKey:            self.publicKey!,
                                                       authenticationMethod: self.authenticationMethod!)
            } catch {
                self.abort()
                self.presentAlert(title: "Error", message: error.localizedDescription)
            }
        }
    }
    
}

extension ProvisioningViewController: GattBearerDelegate {
    
    func bearerDidConnect(_ bearer: Bearer) {
        presentStatusDialog(message: "Discovering services...")
    }
    
    func bearerDidDiscoverServices(_ bearer: Bearer) {
        presentStatusDialog(message: "Initializing...")
    }
    
    func bearerDidOpen(_ bearer: Bearer) {
        presentStatusDialog(message: "Identifying...") { [weak self] in
            guard let self = self else { return }
            do {
                try self.provisioningManager!.identify(andAttractFor: ProvisioningViewController.attentionTimer)
            } catch {
                self.abort()
                self.presentAlert(title: "Error", message: error.localizedDescription)
            }
        }
    }
    
    func bearer(_ bearer: Bearer, didClose error: Error?) {
        guard case .complete = provisioningManager.state else {
            dismissStatusDialog { [weak self] in
                self?.presentAlert(title: "Status", message: "Device disconnected.")
            }
            return
        }
        dismissStatusDialog { [weak self] in
            guard let self = self else { return }
            let manager = MeshNetworkManager.instance
            if manager.save() {
                let connection = MeshNetworkManager.bearer!
                func done(reconnect: Bool) {
                    if reconnect, let pbGattBearer = self.bearer as? PBGattBearer {
                        connection.disconnect()
                        // The bearer has closed. Attempt to send a message
                        // will fail, but the Proxy Filter will receive .bearerClosed
                        // error, upon which it will clear the filter list and notify
                        // the delegate.
                        manager.proxyFilter.proxyDidDisconnect()
                        manager.proxyFilter.clear()
                        
                        let gattBearer = GattBearer(targetWithIdentifier: pbGattBearer.identifier)
                        connection.use(proxy: gattBearer)
                    }
                    self.dismiss(animated: true) {
                        guard let network = manager.meshNetwork else {
                            return
                        }
                        if let node = network.node(for: self.unprovisionedDevice) {
                            self.delegate?.provisionerDidProvisionNewDevice(node, whichReplaced: self.previousNode)
                        }
                    }
                }
                let reconnectAction = UIAlertAction(title: "Yes", style: .default) { _ in
                    done(reconnect: true)
                }
                let continueAction = UIAlertAction(title: "No", style: .cancel) { _ in
                    done(reconnect: false)
                }
                if connection.isConnected && bearer is PBGattBearer {
                    self.presentAlert(title: "Success",
                                      message: "Provisioning complete.\n\nDo you want to connect to the new Node over GATT bearer?",
                                      options: [reconnectAction, continueAction])
                } else {
                    self.presentAlert(title: "Success",
                                      message: "Provisioning complete.") { _ in
                        done(reconnect: true)
                    }
                }
            } else {
                self.presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
            }
        }
    }
    
}

extension ProvisioningViewController: ProvisioningDelegate {
    
    func provisioningState(of unprovisionedDevice: UnprovisionedDevice, didChangeTo state: ProvisioningState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch state {
                
            case .requestingCapabilities:
                self.presentStatusDialog(message: "Identifying...")
                
            case .capabilitiesReceived(let capabilities):
                self.elementsCountLabel.text = "\(capabilities.numberOfElements)"
                self.supportedAlgorithmsLabel.text = "\(capabilities.algorithms)".toLines
                self.publicKeyTypeLabel.text = "\(capabilities.publicKeyType)"
                self.oobTypeLabel.text = "\(capabilities.oobType)".toLines
                self.outputOobSizeLabel.text = "\(capabilities.outputOobSize)"
                self.supportedOutputOobActionsLabel.text = "\(capabilities.outputOobActions)"
                self.inputOobSizeLabel.text = "\(capabilities.inputOobSize)"
                self.supportedInputOobActionsLabel.text = "\(capabilities.inputOobActions)"
                
                // This is needed to refresh constraints after filling new values.
                self.tableView.reloadData()
    		            
                // If the Unicast Address was set to automatic (nil), it should be
                // set to the correct value by now, as we know the number of elements.
                let addressValid = self.provisioningManager.isUnicastAddressValid == true
                if !addressValid {
                   self.provisioningManager.unicastAddress = nil
                }
                self.unicastAddressLabel.text = self.provisioningManager.unicastAddress?.asString() ?? "No address available"
                self.actionProvision.isEnabled = addressValid
                
                let capabilitiesWereAlreadyReceived = self.capabilitiesReceived
                self.capabilitiesReceived = true
                
                let deviceSupported = self.provisioningManager.isDeviceSupported == true
                
                self.dismissStatusDialog {
                    if deviceSupported && addressValid {
                        // If the device got disconnected after the capabilities were received
                        // the first time, the app had to send invitation again.
                        // This time we can just directly proceed with provisioning.
                        if capabilitiesWereAlreadyReceived {
                            self.startProvisioning()
                        }
                    } else {
                        if !deviceSupported {
                            self.presentAlert(title: "Error", message: "Selected device is not supported.")
                            self.actionProvision.isEnabled = false
                        } else if !addressValid {
                            self.presentAlert(title: "Error", message: "No available Unicast Address in Provisioner's range.")
                        }
                    }
                }
                
            case .complete:
                self.presentStatusDialog(message: "Disconnecting...") {
                    do {
                        try self.bearer.close()
                    } catch {
                        self.dismissStatusDialog() {
                            self.presentAlert(title: "Error", message: error.localizedDescription)
                        }
                    }
                }
                
            case let .failed(error):
                self.dismissStatusDialog {
                    self.presentAlert(title: "Error", message: error.localizedDescription)
                    self.abort()
                }
                
            default:
                break
            }
        }
    }
    
    func authenticationActionRequired(_ action: AuthAction) {
        switch action {
            
        case let .provideStaticKey(callback: callback):
            guard let capabilities = provisioningManager.provisioningCapabilities else {
                return
            }
            let algorithm = capabilities.algorithms.strongest
            
            self.dismissStatusDialog {
                let requiredSize = algorithm == .BTM_ECDH_P256_HMAC_SHA256_AES_CCM ? 32 : 16
                let type: Selector = algorithm == .BTM_ECDH_P256_HMAC_SHA256_AES_CCM ? .key32Required : .key16Required
                
                let message = "Enter \(requiredSize)-character hexadecimal string."
                self.presentTextAlert(title: "Static OOB Key", message: message,
                                      type: type, cancelHandler: nil) { hex in
                    callback(Data(hex: hex))
                }
            }
            
        case let .provideNumeric(maximumNumberOfDigits: _, outputAction: action, callback: callback):
            self.dismissStatusDialog {
                var message: String
                switch action {
                case .blink:
                    message = "Enter number of blinks."
                case .beep:
                    message = "Enter number of beeps."
                case .vibrate:
                    message = "Enter number of vibrations."
                case .outputNumeric:
                    message = "Enter the number displayed on the device."
                default:
                    message = "Action \(action) is not supported."
                }
                self.presentTextAlert(title: "Authentication", message: message,
                                      type: .unsignedNumberRequired, cancelHandler: nil) { text in
                    callback(UInt(text)!)
                }
            }
            
        case let .provideAlphanumeric(maximumNumberOfCharacters: _, callback: callback):
            self.dismissStatusDialog {
                let message = "Enter the text displayed on the device."
                self.presentTextAlert(title: "Authentication", message: message,
                                      type: .nameRequired, cancelHandler: nil) { text in
                    callback(text)
                }
            }
            
        case let .displayAlphanumeric(text):
            self.presentStatusDialog(message: "Enter the following text on your device:\n\n\(text)")
            
        case let .displayNumber(value, inputAction: action):
            self.presentStatusDialog(message: "Perform \(action) \(value) times on your device.")
        }
    }
    
    func inputComplete() {
        self.presentStatusDialog(message: "Provisioning...")
    }
    
}

extension ProvisioningViewController: SelectionDelegate {
    
    func networkKeySelected(_ networkKey: NetworkKey?) {
        self.provisioningManager.networkKey = networkKey
        self.networkKeyLabel.text = networkKey?.name ?? "New Network Key"
    }
    
}

private extension IndexPath {
    
    /// Returns whether the IndexPath points the Device Name.
    var isDeviceName: Bool {
        return section == 0 && row == 0
    }
    
    /// Returns whether the IndexPath point to the Unicast Address settings.
    var isUnicastAddress: Bool {
        return section == 1 && row == 0
    }
    
}

private extension String {
    
    // Replaces ", " to new line.
    //
    // The `debugDescription` in the library returns values separated
    // with commas.
    var toLines: String {
        return replacingOccurrences(of: ", ", with: "\n")
    }
    
}
