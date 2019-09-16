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
    @IBAction func addTapped(_ sender: UIBarButtonItem) {
        presentAddressDialog()
    }
    
    // MARK: - Implementation
    
    override func viewDidLoad() {
        super.viewDidLoad()
        MeshNetworkManager.bearer.delegate = self
        MeshNetworkManager.instance.proxyFilter?.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
        
        addButton.isEnabled = MeshNetworkManager.bearer.isOpen
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

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let manager = MeshNetworkManager.instance
        let proxyFilter = manager.proxyFilter!
        
        if indexPath == .status {
            let cell = tableView.dequeueReusableCell(withIdentifier: "status", for: indexPath)
            cell.detailTextLabel?.text = MeshNetworkManager.bearer.isOpen ? "Connected" : "Connecting..."
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
        start("Setting proxy filter...") {
            proxyFilter.setType(type)
        }
    }
    
}

extension ProxyFilterViewController: ProxyFilterDelegate {
    
    func proxyFilterUpdated(type: ProxyFilerType, addresses: Set<Address>) {
        done() {
            self.tableView.reloadSections(.addresses, with: .automatic)
        }
    }
    
}

private extension ProxyFilterViewController {
    
    /// Presents a dialog to add a new Address.
    func presentAddressDialog() {
        presentTextAlert(title: "Address", message: "Hexadecimal value.",
                         text: nil, placeHolder: "Address", type: .validAddressRequired) { text in
                            let address = Address(text, radix: 16)!
                            self.addAddress(address)
        }
    }
    
    func addAddress(_ address: Address) {
        guard let proxyFilter = MeshNetworkManager.instance.proxyFilter,
              !proxyFilter.addresses.contains(address) else {
            return
        }
        start("Adding address...") {
            proxyFilter.add(address: address)
        }
    }
    
}

private extension IndexPath {
    static let status  = IndexPath(row: 0, section: 0)
    static let control = IndexPath(row: 1, section: 0)
}

private extension IndexSet {
    static let addresses = IndexSet(integer: 1)
}
