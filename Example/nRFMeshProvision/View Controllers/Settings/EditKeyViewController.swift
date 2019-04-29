//
//  BindAppKeyViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 26/04/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

protocol EditKeyDelegate {
    /// Notifies the delegate that the Key was added to the mesh network.
    ///
    /// - parameter key: The new Key.
    func keyWasAdded(_ key: Key)
    /// Notifies the delegate that the given Key was modified.
    ///
    /// - parameter key: The Key that has been modified.
    func keyWasModified(_ key: Key)
}

class EditKeyViewController: UITableViewController {
    
    // MARK: - Actions
    
    @IBAction func doneTapped(_ sender: UIBarButtonItem) {
        saveKey()
    }
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    // MARK: - Public members
    
    /// The Key to be modified.
    var key: Key? {
        didSet {
            if let key = key {
                newKey = key.key
            }
            isApplicationKey = key is ApplicationKey
        }
    }
    /// A flag containing `true` if the key is an Application Key, or `false`
    /// otherwise.
    var isApplicationKey: Bool! {
        didSet {
            let network = MeshNetworkManager.instance.meshNetwork!
            
            newName  = key?.name ?? defaultName
            keyIndex = key?.index ?? (isApplicationKey ?
                network.nextAvailableApplicationKeyIndex :
                network.nextAvailableNetworkKeyIndex)
            if isApplicationKey {
                newBoundNetKey = (key as? ApplicationKey)?.boundNetKey ?? 0
            } else {
                newBoundNetKey = nil
            }
        }
    }
    /// The delegate will be informed when the Done button is clicked.
    var delegate: EditKeyDelegate?
    
    // MARK: - Private members
    
    private var newName: String!
    private var newKey: Data! = Data.random128BitKey()
    private var keyIndex: KeyIndex!
    private var newBoundNetKey: KeyIndex?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let action = isNewKey ? "Add" : "Edit"
        let type   = isApplicationKey ? "App" : "Network"
        title = "\(action) \(type) Key"
    }
    
    // - Table View Delegate
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // Display Network Key in 2 sections while Application Keys in 3.
        // The second section contains key bindings.
        return isApplicationKey ? 3 : 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1 // Name
        case 1:
            return 2 // Key, Key Index
        default:
            let network = MeshNetworkManager.instance.meshNetwork!
            return network.networkKeys.count
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return nil
        case 1:
            return "Key details"
        default:
            return "Bound Network Key"
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 2 {
            return "An Application Key must be bound to a Network Key. A key that is already used may not be re-bound to a different key."
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let network = MeshNetworkManager.instance.meshNetwork!
        var cell: UITableViewCell!
        
        if indexPath.isName {
            cell = tableView.dequeueReusableCell(withIdentifier: "detailCell", for: indexPath)
            cell.textLabel?.text = "Name"
            cell.detailTextLabel?.text = newName
            cell.selectionStyle = .default
        } else if indexPath.isKey {
            cell = tableView.dequeueReusableCell(withIdentifier: "keyCell", for: indexPath)
            cell.textLabel?.text = newKey.hex
            // The key may only be editable for new keys.
            cell.selectionStyle = isNewKey ? .default : .none
        } else if indexPath.isKeyIndex {
            cell = tableView.dequeueReusableCell(withIdentifier: "detailCell", for: indexPath)
            cell.textLabel?.text = "Key Index"
            cell.detailTextLabel?.text = "\(keyIndex!)"
            cell.selectionStyle = .none
        } else {
            let networkKey = network.networkKeys[indexPath.row]
            
            cell = tableView.dequeueReusableCell(withIdentifier: "subtitleCell", for: indexPath)
            cell.textLabel?.text = networkKey.name
            cell.detailTextLabel?.text = networkKey.key.hex
            cell.selectionStyle = isKeyUsed ? .none : .default
            
            if networkKey.index == newBoundNetKey {
                cell.textLabel?.textColor = .black
                cell.detailTextLabel?.textColor = .black
                cell.accessoryType = .checkmark
                // Save the checked row number as tag.
                tableView.tag = indexPath.row
            } else {
                cell.textLabel?.textColor = isKeyUsed ? .lightGray : .black
                cell.detailTextLabel?.textColor = isKeyUsed ? .lightGray : .black
                cell.accessoryType = .none
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.isName {
            presentNameDialog()
        }
        if isNewKey && indexPath.isKey {
            presentKeyDialog()
        }
        if !isKeyUsed && indexPath.isBoundKeyIndex {
            let network = MeshNetworkManager.instance.meshNetwork!
            let networkKey = network.networkKeys[indexPath.row]
            newBoundNetKey = networkKey.index
            
            tableView.reloadRows(at: [indexPath, IndexPath(row: tableView.tag, section: 2)], with: .fade)
        }
    }

}

private extension EditKeyViewController {
    
    var isNewKey: Bool {
        return key == nil
    }
    
    var isKeyUsed: Bool {
        if key is ApplicationKey {
            let network = MeshNetworkManager.instance.meshNetwork!
            return (key as! ApplicationKey).isUsed(in: network)
        }
        return false
    }
    
    var defaultName: String {
        let network = MeshNetworkManager.instance.meshNetwork!
        if isApplicationKey {
            return "App Key \(network.nextAvailableApplicationKeyIndex + 1)"
        } else {
            return "Network Key \(network.nextAvailableNetworkKeyIndex + 1)"
        }
    }
    
    private func presentKeyDialog() {
        let title = "New Key"
        let message = "The key must be a 32-character hexadecimal string."
        
        presentKeyDialog(title: title, message: message) { key in
            self.newKey = key
            self.tableView.reloadRows(at: [.key], with: .fade)
        }
    }
    
    private func presentNameDialog() {
        presentTextAlert(title: "Edit Key Name", message: nil, text: newName,
                         placeHolder: "E.g. Lights and Switches",
                         type: .nameRequired) { name in
                            self.newName = name
                            self.tableView.reloadRows(at: [.name], with: .fade)
        }
    }
    
    private func saveKey() {
        let network = MeshNetworkManager.instance.meshNetwork!
        
        let adding = isNewKey
        if key == nil {
            if isApplicationKey {
                key = try! network.add(applicationKey: newKey, name: newName)
            } else {
                key = try! network.add(networkKey: newKey, name: newName)
            }
        }
        key!.name = newName
        if let applicationKey = key as? ApplicationKey {
            let networkKey = network.networkKeys.first { $0.index == newBoundNetKey }
            applicationKey.bind(to: networkKey!)
        }
        
        if MeshNetworkManager.instance.save() {
            dismiss(animated: true)
            
            // Finally, notify the parent view controller.
            if adding {
                delegate?.keyWasAdded(key!)
            } else {
                delegate?.keyWasModified(key!)
            }
        } else {
            presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
        }
    }
    
}

private extension IndexPath {
    
    /// Returns whether the IndexPath point to the 128-bit Network Key.
    var isKey: Bool {
        return section == 0 && row == 0
    }
    
    /// Returns whether the IndexPath points to the key name.
    var isName: Bool {
        return section == 1 && row == 0
    }
    
    /// Returns whether the IndexPath point to Key Index.
    var isKeyIndex: Bool {
        return section == 1 && row == 1
    }
    
    /// Returns whether the IndexPath point to Key Index.
    var isBoundKeyIndex: Bool {
        return section == 2
    }
    
    static let key  = IndexPath(row: 0, section: 0)
    static let name = IndexPath(row: 0, section: 1)
}
