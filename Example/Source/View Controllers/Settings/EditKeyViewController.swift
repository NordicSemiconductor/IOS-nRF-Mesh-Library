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
    
    /// The Key to be modified. This is `nil` when a new key is being added.
    var key: Key? {
        didSet {
            if let key = key {
                newKey = key.key
                isApplicationKey = key is ApplicationKey
            }
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
            switch key {
            case let applicationKey as ApplicationKey:
                newBoundNetworkKeyIndex = applicationKey.boundNetworkKeyIndex
                oldKey = applicationKey.oldKey
            case let networkKey as NetworkKey:
                newBoundNetworkKeyIndex = nil
                oldKey = networkKey.oldKey
            default:
                break
            }
        }
    }
    /// The delegate will be informed when the Done button is clicked.
    var delegate: EditKeyDelegate?
    
    // MARK: - Private members
    
    private let dateFormatter = DateFormatter()
    
    private var newName: String!
    private var newKey: Data! = Data.random128BitKey()
    private var oldKey: Data?
    private var keyIndex: KeyIndex!
    private var newBoundNetworkKeyIndex: KeyIndex?
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        
        let action = isNewKey ? "Add" : "Edit"
        let type   = isApplicationKey ? "App" : "Network"
        title = "\(action) \(type) Key"
    }
    
    // - Table View Delegate
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // Display Network Key in 2 sections while Application Keys in 3.
        // The second section contains key bindings.
        return isApplicationKey ? IndexPath.numberOfSections : IndexPath.numberOfSections - 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case IndexPath.nameSection:
            return 1 // Name
        case IndexPath.keySection where isApplicationKey:
            return 3 // Key, Old Key, Key Index
        case IndexPath.keySection:
            return isNewKey ? 3 : 6 // Key, Old Key, Key Index [, Phase, Min Security, Last modified ]
        case IndexPath.boundKeySection:
            let network = MeshNetworkManager.instance.meshNetwork!
            return network.networkKeys.count
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case IndexPath.keySection:
            return "Key details"
        case IndexPath.boundKeySection:
            return "Bound Network Key"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == IndexPath.boundKeySection {
            return "An Application Key must be bound to a Network Key. A key that is in use cannot be re-bound to a different key."
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
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        } else if indexPath.isKey {
            cell = tableView.dequeueReusableCell(withIdentifier: "keyCell", for: indexPath)
            cell.textLabel?.text = "Key"
            cell.detailTextLabel?.text = newKey.hex
            // Only new or not used keys may be edited.
            cell.accessoryType = isNewKey || !isKeyUsed ? .disclosureIndicator : .none
            cell.selectionStyle = .default
        } else if indexPath.isOldKey {
            cell = tableView.dequeueReusableCell(withIdentifier: "keyCell", for: indexPath)
            cell.textLabel?.text = "Old Key"
            cell.detailTextLabel?.text = oldKey?.hex ?? "N/A"
            cell.accessoryType = .none
            cell.selectionStyle = oldKey == nil ? .none : .default
        } else if indexPath.isKeyIndex {
            cell = tableView.dequeueReusableCell(withIdentifier: "detailCell", for: indexPath)
            cell.textLabel?.text = "Key Index"
            cell.detailTextLabel?.text = "\(keyIndex!)"
            cell.selectionStyle = .none
        } else if indexPath.isPhase {
            cell = tableView.dequeueReusableCell(withIdentifier: "detailCell", for: indexPath)
            cell.textLabel?.text = "Phase"
            let phase = (key as? NetworkKey)?.phase ?? KeyRefreshPhase.normalOperation
            cell.detailTextLabel?.text = "\(phase)"
            cell.selectionStyle = .none
        } else if indexPath.isMinSecurity {
            cell = tableView.dequeueReusableCell(withIdentifier: "detailCell", for: indexPath)
            cell.textLabel?.text = "Minimum Security"
            let minSecurity = (key as? NetworkKey)?.minSecurity ?? .secure
            cell.detailTextLabel?.text = "\(minSecurity)"
            cell.selectionStyle = .none
        } else if indexPath.isLastModified {
            cell = tableView.dequeueReusableCell(withIdentifier: "detailCell", for: indexPath)
            cell.textLabel?.text = "Last Modified"
            let timestamp = (key as? NetworkKey)?.timestamp
            cell.detailTextLabel?.text = timestamp.map { dateFormatter.string(from: $0) } ?? "N/A"
            cell.selectionStyle = .none
        } else {
            let networkKey = network.networkKeys[indexPath.row]
            
            cell = tableView.dequeueReusableCell(withIdentifier: "subtitleCell", for: indexPath)
            cell.textLabel?.text = networkKey.name
            cell.selectionStyle = isKeyUsed ? .none : .default
            
            if networkKey.index == newBoundNetworkKeyIndex {
                if #available(iOS 13.0, *) {
                    cell.textLabel?.textColor = UIColor.label
                } else {
                    cell.textLabel?.textColor = UIColor.darkText
                }
                cell.accessoryType = .checkmark
                // Save the checked row number as tag.
                tableView.tag = indexPath.row
            } else {
                if #available(iOS 13.0, *) {
                    cell.textLabel?.textColor = isKeyUsed ? .secondaryLabel : .label
                } else {
                    cell.textLabel?.textColor = isKeyUsed ? .lightGray : .darkText
                }
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
        if indexPath.isKey {
            if isNewKey || !isKeyUsed {
                presentKeyDialog()
            } else {
                UIPasteboard.general.string = newKey.hex
                showToast("Key copied to Clipboard.")
            }
        }
        if indexPath.isOldKey {
            if let oldKey = oldKey {
                UIPasteboard.general.string = oldKey.hex
                showToast("Old Key copied to Clipboard.")
            }
        }
        if indexPath.isBoundKeyIndex && !isKeyUsed {
            let network = MeshNetworkManager.instance.meshNetwork!
            let networkKey = network.networkKeys[indexPath.row]
            newBoundNetworkKeyIndex = networkKey.index
            
            tableView.reloadRows(at: [indexPath, IndexPath(row: tableView.tag, section: IndexPath.boundKeySection)], with: .fade)
        }
    }

}

private extension EditKeyViewController {
    
    var isNewKey: Bool {
        return key == nil
    }
    
    var isKeyUsed: Bool {
        if key is NetworkKey {
            let network = MeshNetworkManager.instance.meshNetwork!
            return (key as! NetworkKey).isUsed(in: network)
        }
        if key is ApplicationKey {
            let network = MeshNetworkManager.instance.meshNetwork!
            return (key as! ApplicationKey).isUsed(in: network)
        }
        return false
    }
    
    var defaultName: String {
        let network = MeshNetworkManager.instance.meshNetwork!
        if isApplicationKey {
            return "App Key \((network.nextAvailableApplicationKeyIndex ?? 0xFFF) + 1)"
        } else {
            return "Network Key \((network.nextAvailableNetworkKeyIndex ?? 0xFFF) + 1)"
        }
    }
    
    func presentKeyDialog() {
        let title = "New Key"
        let message = "The key must be a 32-character hexadecimal string."
        
        presentKeyDialog(title: title, message: message, key: key?.key) { key in
            self.newKey = key
            self.tableView.reloadRows(at: [.key], with: .fade)
        }
    }
    
    func presentNameDialog() {
        presentTextAlert(title: "Edit Key Name", message: nil, text: newName,
                         placeHolder: "E.g. Lights and Switches",
                         type: .nameRequired, cancelHandler: nil) { name in
                            self.newName = name
                            self.tableView.reloadRows(at: [.name], with: .fade)
        }
    }
    
    func saveKey() {
        let network = MeshNetworkManager.instance.meshNetwork!
        
        // Those 2 must be saved before setting the key.
        let index = newBoundNetworkKeyIndex
        let adding = isNewKey
        // It is not possible to modify the key without doing Key Refresh Procedure.
        // Instead, we'll remove the old key and create a new one with the same key
        // Index and new data.
        let keyIndex = key?.index
        if let oldKey = key, oldKey.key != newKey {
            if let key = oldKey as? ApplicationKey {
                try! network.remove(applicationKey: key, force: true)
            } else if let key = oldKey as? NetworkKey {
                try! network.remove(networkKey: key, force: true)
            }
            key = nil
        }
        // If a new key was added, or the old one removed, create new keys.
        if key == nil {
            if isApplicationKey {
                key = try! network.add(applicationKey: newKey, withIndex: keyIndex, name: newName)
            } else {
                key = try! network.add(networkKey: newKey, withIndex: keyIndex, name: newName)
            }
        }
        key!.name = newName
        if let applicationKey = key as? ApplicationKey,
           let index = index,
           let networkKey = network.networkKeys[index] {
            try? applicationKey.bind(to: networkKey)
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
    static let nameSection = 0
    static let keySection  = 1
    static let boundKeySection = 2
    static let numberOfSections = boundKeySection + 1
    
    /// Returns whether the IndexPath points to the key name.
    var isName: Bool {
        return section == IndexPath.nameSection && row == 0
    }
    
    /// Returns whether the IndexPath points to the 128-bit Network Key.
    var isKey: Bool {
        return section == IndexPath.keySection && row == 0
    }
    
    /// Returns whether the IndexPath points to the old 128-bit Network Key.
    var isOldKey: Bool {
        return section == IndexPath.keySection && row == 1
    }
    
    /// Returns whether the IndexPath points to Key Index.
    var isKeyIndex: Bool {
        return section == IndexPath.keySection && row == 2
    }
    
    /// Returns whether the IndexPath points to Network Key phase.
    var isPhase: Bool {
        return section == IndexPath.keySection && row == 3
    }
    
    /// Returns whether the IndexPath points to Network Key min security.
    var isMinSecurity: Bool {
        return section == IndexPath.keySection && row == 4
    }
    
    /// Returns whether the IndexPath points to Network Key last modified timestamp.
    var isLastModified: Bool {
        return section == IndexPath.keySection && row == 5
    }
    
    /// Returns whether the IndexPath points to Bound Network Key Index.
    var isBoundKeyIndex: Bool {
        return section == IndexPath.boundKeySection
    }
    
    static let key  = IndexPath(row: 0, section: IndexPath.keySection)
    static let name = IndexPath(row: 0, section: IndexPath.nameSection)
}
