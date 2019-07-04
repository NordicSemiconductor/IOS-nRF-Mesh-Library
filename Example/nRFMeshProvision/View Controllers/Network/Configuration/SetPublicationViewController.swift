//
//  SetPublicationViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 03/07/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

protocol PublicationDelegate {
    /// This method is called when the publication has changed.
    func publicationChanged()
}

class SetPublicationViewController: ConnectableViewController {
    
    // MARK: - Outlets & Actions
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    @IBAction func doneTapped(_ sender: UIBarButtonItem) {
    }
    
    @IBOutlet weak var destinationLabel: UILabel!
    @IBOutlet weak var keyCell: UITableViewCell!
    @IBOutlet weak var friendshipCredentialsFlagSwitch: UISwitch!
    @IBOutlet weak var ttlLabel: UILabel!
    @IBOutlet weak var publishingPeriodLabel: UILabel!
    @IBOutlet weak var retransmitCountLabel: UILabel!
    @IBOutlet weak var retransmitIntervalLabel: UIView!
        
    // MARK: - Properties
    
    var model: Model!
    var delegate: PublicationDelegate?
    
    private var destination: MeshAddress?
    private var applicationKey: ApplicationKey!
    private var ttl: UInt8 = 0xFF {
        didSet {
            if ttl == 0xFF {
                ttlLabel.text = "Default"
            } else {
                ttlLabel.text = "\(ttl)"
            }
        }
    }
    
    // MARK: - View Controller

    override func viewDidLoad() {
        super.viewDidLoad()
        
        MeshNetworkManager.instance.delegate = self
        
        keySelected(model.boundApplicationKeys.first!)
        if model.boundApplicationKeys.count == 1 {
            keyCell.accessoryType = .none
            keyCell.selectionStyle = .none
        }
        doneButton.isEnabled = destination != nil
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "selectKey" {
            return model.boundApplicationKeys.count > 1
        }
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case .some("setDestination"):
            let destination = segue.destination as! SetPublicationDestinationsViewController
            destination.model = model
            destination.delegate = self
        case .some("selectKey"):
            let destination = segue.destination as! SetPublicationSelectKeyViewController
            destination.model = model
            destination.delegate = self
            destination.selectedKey = applicationKey
        default:
            break
        }
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath == .ttl {
            presentTTLDialog()
        }
    }

}

private extension SetPublicationViewController {
    
    /// Presents a dialog to edit the Publish TTL.
    func presentTTLDialog() {
        presentTextAlert(title: "Publish TTL",
                         message: "TTL = Time To Live\n\nTTL limits the number of times a message can be relayed.\nMax value is 127. Message with TTL 0 will not be relayed.",
                         text: "5", placeHolder: "Default is 5",
                         type: .ttlRequired,
                         option: UIAlertAction(title: "Use Node's default", style: .default, handler: { _ in
                            self.ttl = 0xFF
                         })) { value in
                            self.ttl = UInt8(value)!
        }
    }
    
}

extension SetPublicationViewController: KeySelectionDelegate, DestinationDelegate {
    
    func destinationSet(to name: String, withAddress address: MeshAddress) {
        self.destination = address
        self.destinationLabel.text = name
        self.destinationLabel.textColor = .darkText
        self.doneButton.isEnabled = true
    }
    
    func keySelected(_ applicationKey: ApplicationKey) {
        self.applicationKey = applicationKey
        self.keyCell.textLabel?.text = applicationKey.name
        self.keyCell.detailTextLabel?.text = "Bound to \(applicationKey.boundNetworkKey.name)"
    }
    
}

extension SetPublicationViewController: MeshNetworkDelegate {
    
    func meshNetwork(_ meshNetwork: MeshNetwork, didDeliverMessage message: MeshMessage, from source: Address) {
        
    }
    
}

private extension IndexPath {
    static let ttl = IndexPath(row: 0, section: 2)
}
