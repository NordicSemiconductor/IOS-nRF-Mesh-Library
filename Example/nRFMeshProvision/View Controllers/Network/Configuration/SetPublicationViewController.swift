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
    
    private var applicationKey: ApplicationKey!
    
    // MARK: - View Controller

    override func viewDidLoad() {
        super.viewDidLoad()
        
        MeshNetworkManager.instance.delegate = self
        
        keySelected(model.boundApplicationKeys.first!)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
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
    }

}

extension SetPublicationViewController: KeySelectionDelegate {
    
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
