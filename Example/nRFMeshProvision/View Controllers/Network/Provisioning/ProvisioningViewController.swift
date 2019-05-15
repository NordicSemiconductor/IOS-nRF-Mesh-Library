//
//  ProvisioningViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 06/05/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class ProvisioningViewController: UITableViewController {
    static let attentionTimer: UInt8 = 5
    
    // MARK: - Outlets

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var unicastAddressLabel: UILabel!
    @IBOutlet weak var networkKeyLabel: UILabel!
    
    @IBOutlet weak var elementsCountLabel: UILabel!
    @IBOutlet weak var supportedAlgorithmsLabel: UILabel!
    @IBOutlet weak var publicKeyTypeLabel: UILabel!
    @IBOutlet weak var staticOobTypeLabel: UILabel!
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
    
    var unprovisionedDevice: UnprovisionedDevice!
    var bearer: ProvisioningBearer!
    
    private var publicKey: PublicKey?
    private var authenticationMethod: AuthenticationMethod?
    
    private var provisioningManager: ProvisioningManager!
    private var capabilitiesReceived = false
    
    private var alert: UIAlertController?
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let network = MeshNetworkManager.instance.meshNetwork!
        nameLabel.text = unprovisionedDevice.name
        
        // Obtain the Provisioning Manager instance for the Unprovisioned Device.
        provisioningManager = network.provision(unprovisionedDevice: self.unprovisionedDevice, over: self.bearer!)
        provisioningManager.delegate = self
        bearer.delegate = self
        
        // Unicast Address initially will be assigned automatically.
        unicastAddressLabel.text = "Automatic"
        networkKeyLabel.text = provisioningManager.networkKey?.name ?? "New Network Key"
        actionProvision.isEnabled = network.localProvisioner != nil
        
        // We are now connected. Proceed by sending Provisioning Invite request.
        presentStatusDialog(message: "Identifying...", animated: false) {
            do {
                try self.provisioningManager.identify(andAttractFor: ProvisioningViewController.attentionTimer)
            } catch {
                print(error)
                self.abort()
                self.presentAlert(title: "Error", message: "Identifying failed with an error: \(error)")
            }
        }
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
                         type: .nameRequired) { newName in
                            self.unprovisionedDevice.name = newName
                            self.nameLabel.text = newName
        }
    }
    
    /// Presents a dialog to edit or unbind the Provisioner Unicast Address.
    func presentUnicastAddressDialog() {
        let manager = self.provisioningManager!
        let action = UIAlertAction(title: "Automatic", style: .default) { _ in
            manager.unicastAddress = manager.suggestedUnicastAddress
            self.unicastAddressLabel.text = manager.unicastAddress?.asString() ?? "Automatic"
            let deviceSupported = manager.isDeviceSupported == true
            let addressValid = manager.isUnicastAddressValid == true
            self.actionProvision.isEnabled = addressValid && deviceSupported
        }
        presentTextAlert(title: "Unicast address", message: "Hexadecimal value in Provisioner's range.",
                         text: manager.unicastAddress?.hex, placeHolder: "Address", type: .unicastAddressRequired,
                         option: action) { text in
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
        DispatchQueue.main.async {
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
        DispatchQueue.main.async {
            if let alert = self.alert {
                alert.dismiss(animated: true, completion: completion)
            } else {
                completion?()
            }
            self.alert = nil
        }
    }
    
    func abort() {
        DispatchQueue.main.async {
            self.alert?.title   = "Aborting"
            self.alert?.message = "Cancelling connection..."
            self.bearer.close()
        }
    }
    
}

private extension ProvisioningViewController {    
    
    /// This method tries to open the bearer had it been closed when on this screen.
    func openBearer() {
        presentStatusDialog(message: "Connecting...") {
            self.bearer.open()
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
            presentOobPublicKeyDialog(for: unprovisionedDevice) { publicKey in
                self.publicKey = publicKey
                self.startProvisioning()
            }
            return
        }
        publicKey = publicKey ?? .noOobPublicKey
        
        // If any of OOB methods is supported, if should be chosen.
        let staticOobNotSupported = capabilities.staticOobType.isEmpty
        let outputOobNotSupported = capabilities.outputOobActions.isEmpty
        let inputOobNotSupported  = capabilities.inputOobActions.isEmpty
        guard (staticOobNotSupported && outputOobNotSupported && inputOobNotSupported) || authenticationMethod != nil else {
            presentOobOptionsDialog(for: provisioningManager) { method in
                self.authenticationMethod = method
                self.startProvisioning()
            }
            return
        }
        
        // Start provisioning.
        presentStatusDialog(message: "Provisioning...") {
            do {
                try self.provisioningManager.provision(usingAlgorithm:       .fipsP256EllipticCurve,
                                                       publicKey:            self.publicKey!,
                                                       authenticationMethod: self.authenticationMethod!)
            } catch {
                print(error)
                self.abort()
                self.presentAlert(title: "Error", message: "Provisioning failed with an error: \(error)")
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
        presentStatusDialog(message: "Identifying...") {
            do {
                try self.provisioningManager!.identify(andAttractFor: ProvisioningViewController.attentionTimer)
            } catch {
                print(error)
                self.abort()
                self.presentAlert(title: "Error", message: "Identifying failed with an error: \(error)")
            }
        }
    }
    
    func bearer(_ bearer: Bearer, didClose error: Error?) {
        DispatchQueue.main.async {
            self.dismissStatusDialog() {
                self.presentAlert(title: "Status", message: "Device disconnected.")
            }
        }
    }
    
}

extension ProvisioningViewController: ProvisioningDelegate {
    
    func provisioningState(of unprovisionedDevice: UnprovisionedDevice, didChangeTo state: ProvisionigState) {
        print("New state: \(state)")
        
        DispatchQueue.main.async {
            switch state {
                
            case .invitationSent:
                self.presentStatusDialog(message: "Receiving capabilities...")
                
            case .capabilitiesReceived(let capabilities):
                self.elementsCountLabel.text = "\(capabilities.numberOfElements)"
                self.supportedAlgorithmsLabel.text = "\(capabilities.algorithms)"
                self.publicKeyTypeLabel.text = "\(capabilities.publicKeyType)"
                self.staticOobTypeLabel.text = "\(capabilities.staticOobType)"
                self.outputOobSizeLabel.text = "\(capabilities.outputOobSize)"
                self.supportedOutputOobActionsLabel.text = "\(capabilities.outputOobActions)"
                self.inputOobSizeLabel.text = "\(capabilities.inputOobSize)"
                self.supportedInputOobActionsLabel.text = "\(capabilities.inputOobActions)"
                
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
                
                self.dismissStatusDialog() {
                    if deviceSupported && addressValid {
                        // If the device got disconnected after the capabilities were received
                        // the first time, the app had to send invitation again.
                        // This time we can just directly proceed with provisioning.
                        if capabilitiesWereAlreadyReceived {
                            self.startProvisioning()
                        }
                    } else {
                        if !deviceSupported {
                            print("Selected device does not support P256 Elliptic Curve algorithm")
                            self.presentAlert(title: "Error", message: "Selected device is not supported.")
                            self.actionProvision.isEnabled = false
                        } else if !addressValid {
                            self.presentAlert(title: "Error", message: "No available Unicast Address in Provisioner's range.")
                        }
                    }
                }
                
            case let .fail(error):
                self.dismissStatusDialog() {
                    self.presentAlert(title: "Error", message: "Provisionig failed with an error:\n\(error)")
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
            self.dismissStatusDialog() {
                let message = "Enter 16-character hexadecimal string."
                self.presentTextAlert(title: "Static OOB Key", message: message, type: .keyRequired) { hex in
                    callback(Data(hex: hex)!)
                }
            }
        case let .displayAlphanumeric(text):
            self.presentStatusDialog(message: "Enter the following text on your device:\n\n\(text)")
        case let .displayNumber(value, inputAction: action):
            self.presentStatusDialog(message: "Perform \(action) \(value) times on your device.")
        default:
            break
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
