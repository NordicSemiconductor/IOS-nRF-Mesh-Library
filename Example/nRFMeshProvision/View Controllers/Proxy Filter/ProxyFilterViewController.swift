//
//  ProxyFilterViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 16/09/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class ProxyFilterViewController: ProgressViewController, Editable {
    
    // MARK: - Outlets and Actions
    
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    // MARK: - Implementation
    
    override func viewDidLoad() {
        super.viewDidLoad()
        MeshNetworkManager.bearer.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
        
        MeshNetworkManager.instance.proxyFilter?.delegate = self
        addButton.isEnabled = MeshNetworkManager.bearer.isOpen
        
        if MeshNetworkManager.instance.proxyFilter?.addresses.isEmpty == false {
            hideEmptyView()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let navigationController = segue.destination as? UINavigationController
        navigationController?.presentationController?.delegate = self
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 2
        default:
            return MeshNetworkManager.instance.proxyFilter?.addresses.count ?? 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            if MeshNetworkManager.instance.proxyFilter?.type == .blacklist {
                return "The black list filter accepts all destination addresses except those that have been added to the black list."
            } else {
                return "The white list filter blocks all destination addresses except those that have been added to the white list."
            }
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let manager = MeshNetworkManager.instance
        let proxyFilter = manager.proxyFilter!
        
        if indexPath == .status {
            let cell = tableView.dequeueReusableCell(withIdentifier: "status", for: indexPath)
            let bearer = MeshNetworkManager.bearer!
            cell.detailTextLabel?.text = bearer.isOpen ? "\(bearer.name ?? "Unknown device")" : "Connecting..."
            return cell
        }
        if indexPath == .control {
            let cell = tableView.dequeueReusableCell(withIdentifier: "type", for: indexPath) as! FilterTypeCell
            cell.delegate = self
            cell.type = proxyFilter.type
            cell.filterTypeControl.isEnabled = MeshNetworkManager.bearer.isOpen
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "subtitle", for: indexPath) as! AddressCell
        cell.address = proxyFilter.addresses.sorted()[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == IndexPath.addressesSection
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let proxyFilter = MeshNetworkManager.instance.proxyFilter!
        let address = proxyFilter.addresses.sorted()[indexPath.row]
        deleteAddress(address)
    }

}

extension ProxyFilterViewController: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        MeshNetworkManager.instance.proxyFilter?.delegate = self
        tableView.reloadSections(.addresses, with: .automatic)
    }
    
}

extension ProxyFilterViewController: BearerDelegate {
    
    func bearerDidOpen(_ bearer: Bearer) {
        addButton.isEnabled = true
        tableView.reloadRows(at: [.status, .control], with: .automatic)
    }
    
    func bearer(_ bearer: Bearer, didClose error: Error?) {
        addButton.isEnabled = false
        tableView.reloadRows(at: [.status, .control], with: .automatic)
    }
    
}

extension ProxyFilterViewController: ProxyFilterTypeDelegate {
    
    func filterTypeDidChange(_ type: ProxyFilerType) {
        guard let proxyFilter = MeshNetworkManager.instance.proxyFilter else {
            return
        }
        let footer = tableView.footerView(forSection: 0)?.textLabel
        switch type {
        case .blacklist:
            footer?.text = "The black list filter accepts all destination addresses except those that have been added to the black list."
        default:
            footer?.text = "The white list filter blocks all destination addresses except those that have been added to the white list."
        }
        footer?.sizeToFit()
        start("Setting proxy filter...") {
            proxyFilter.setType(type)
        }
    }
    
}

extension ProxyFilterViewController: ProxyFilterDelegate {
    
    func proxyFilterUpdated(type: ProxyFilerType, addresses: Set<Address>) {
        done() {
            self.tableView.reloadSections(.addresses, with: .automatic)
            if addresses.isEmpty {
                self.showEmptyView()
            } else {
                self.hideEmptyView()
            }
        }
    }
    
}

private extension ProxyFilterViewController {
    
    /// Deletes the given address from Proxy Filter.
    ///
    /// - parameter address: The address to delete.
    func deleteAddress(_ address: Address) {
        guard let proxyFilter = MeshNetworkManager.instance.proxyFilter,
                  proxyFilter.addresses.contains(address) else {
            return
        }
        start("Deleting address...") {
            proxyFilter.remove(address: address)
        }
    }
    
}

private extension IndexPath {
    static let statusSection = 0
    static let addressesSection = 1
    
    static let status  = IndexPath(row: 0, section: IndexPath.statusSection)
    static let control = IndexPath(row: 1, section: IndexPath.statusSection)
}

private extension IndexSet {
    static let details   = IndexSet(integer: IndexPath.statusSection)
    static let addresses = IndexSet(integer: IndexPath.addressesSection)
}
