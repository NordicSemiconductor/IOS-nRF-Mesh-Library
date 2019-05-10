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
    
    // MARK: - Outlets and Actions

    @IBOutlet weak var actionProvision: UIBarButtonItem!
    @IBAction func provisionTapped(_ sender: UIBarButtonItem) {
    }
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
    
    // MARK: - Properties
    
    var unprovisionedDevice: UnprovisionedDevice!
    var bearer: ProvisioningBearer!
    
    private var unicastAddress: Address?
    private var networkKey: NetworkKey?
    private var provisioningManager: ProvisioningManager?
    
    private var alert: UIAlertController?
    
    // MARK: - Implementation
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let network = MeshNetworkManager.instance.meshNetwork!
        nameLabel.text = unprovisionedDevice.name
        
        // Unicast Address initially will be assigned automatically.
        unicastAddress = nil
        unicastAddressLabel.text = "Automatic"
        // If there is no Network Key, one will have to be created
        // automatically.
        networkKey = network.networkKeys.first
        networkKeyLabel.text = networkKey?.name ?? "New Network Key"
        
        // Obtainn the Provisioning Manager instance for the
        // Unprovisioned Device.
        provisioningManager = network.provision(unprovisionedDevice: self.unprovisionedDevice, over: self.bearer!)
        provisioningManager!.delegate = self
        bearer.delegate = self
        
        // We are now connected. Proceed by sending Provisioning Invite request.
        alert = UIAlertController(title: "Status", message: "Identifying...", preferredStyle: .alert)
        alert!.addAction(UIAlertAction(title: "Cancel", style: .cancel) { action in
            action.isEnabled = false
            self.alert!.title   = "Aborting"
            self.alert!.message = "Cancelling connection..."
            self.bearer.close()
        })
        present(alert!, animated: false) {
            do {
                try self.provisioningManager!.identify(andAttractFor: 5)
            } catch {
                print(error)
                self.alert!.title   = "Aborting"
                self.alert!.message = "Cancelling connection..."
                self.bearer.close()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "networkKey" {
            let destination = segue.destination as! NetworkKeySelectionViewController
            destination.selectedNetworkKey = networkKey
            destination.delegate = self
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.isDeviceName {
            
        }
    }
    
}

extension ProvisioningViewController: GattBearerDelegate {
    
    func bearerDidOpen(_ bearer: Bearer) {
        DispatchQueue.main.async {
            self.alert?.dismiss(animated: true)
            self.alert = nil
        }
    }
    
    func bearer(_ bearer: Bearer, didClose error: Error?) {
        DispatchQueue.main.async {
            if let alert = self.alert {
                alert.message = "Device disconnected"
                alert.dismiss(animated: true)
                self.alert = nil
            } else {
                let alert = UIAlertController(title: "Status", message: "Device disconnected", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel) { action in
                    alert.dismiss(animated: true)
                })
                self.present(alert, animated: true)
            }
        }
    }
    
}

extension ProvisioningViewController: ProvisioningDelegate {
    
    func provisioningState(of unprovisionedDevice: UnprovisionedDevice, didChangeTo state: ProvisionigState) {
        DispatchQueue.main.async {
            switch state {
            case .invitationSent:
                self.alert?.message = "Receiving capabilities..."
            case .capabilitiesReceived(let capabilities):
                self.elementsCountLabel.text = "\(capabilities.numberOfElements)"
                self.supportedAlgorithmsLabel.text = "\(capabilities.algorithms)"
                self.publicKeyTypeLabel.text = "\(capabilities.publicKeyType)"
                self.staticOobTypeLabel.text = "\(capabilities.staticOobType)"
                self.outputOobSizeLabel.text = "\(capabilities.outputOobSize)"
                self.supportedOutputOobActionsLabel.text = "\(capabilities.outputOobActions)"
                self.inputOobSizeLabel.text = "\(capabilities.inputOobSize)"
                self.supportedInputOobActionsLabel.text = "\(capabilities.inputOobActions)"
                self.alert?.dismiss(animated: true)
            default:
                break
            }
        }
    }
    
}

extension ProvisioningViewController: SelectionDelegate {
    
    func networkKeySelected(_ networkKey: NetworkKey) {
        self.networkKey = networkKey
        self.networkKeyLabel.text = networkKey.name
    }
    
}

private extension IndexPath {
    
    /// Returns whether the IndexPath points the Device Name.
    var isDeviceName: Bool {
        return section == 0 && row == 0
    }
    
    /// Returns whether the IndexPath point to the Unicast Address settings.
    var isUnicastAddress: Bool {
        return section == 2 && row == 0
    }
    
}
