/*
* Copyright (c) 2023, Nordic Semiconductor
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

class SelectKeysViewController: UITableViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var nextButton: UIBarButtonItem!
    
    // MARK: - Public properties
    
    var node: Node!
    
    // MARK: - Private properties
    
    private var knownKeys: [ApplicationKey]!
    private var missingKeys: [ApplicationKey]!
    
    private var selectedKeys: [ApplicationKey] = []
    
    // MARK: - View Controller

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let manager = MeshNetworkManager.instance
        let allKeys = manager.meshNetwork?.applicationKeys
        missingKeys = allKeys?.notKnownTo(node: node) ?? []
        knownKeys = allKeys?.knownTo(node: node) ?? []
        
        // If no App Keys are selected, the step can be skipped.
        nextButton.title = "Skip"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "next" {
            let destination = segue.destination as! SelectModelsViewController
            destination.node = node
            destination.selectedKeys = selectedKeys
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if knownKeys.isEmpty {
            return 2
        }
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case IndexPath.infoSection:
            return 0
        case IndexPath.unknownKeysSection:
            return missingKeys.count + 1 // One to Add New Key
        case IndexPath.knownKeysSection:
            return knownKeys.count
        default: fatalError()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        // This is needed for the footer to be displayed correctly on iOS 16.
        // Otherwise it's drawn on top of the last row. Looks like iOS bug?
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == IndexPath.knownKeysSection {
            return "Existing Keys"
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == IndexPath.infoSection {
            return "ⓘ Select Application Keys to bind to Models. Missing keys, together with bound Network Keys, will be sent automatically."
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.isUnknownKeysSection {
            if indexPath.row < missingKeys.count {
                let cell = tableView.dequeueReusableCell(withIdentifier: "key", for: indexPath)
                let key = missingKeys[indexPath .row]
                cell.textLabel?.text = key.name
                cell.detailTextLabel?.text = key.boundNetworkKey.name
                cell.accessoryType = selectedKeys.contains(key) ? .checkmark : .none
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "action", for: indexPath)
                cell.detailTextLabel?.text = "Bound to \(node.networkKeys.primaryKey!.name)"
                return cell
            }
        }
        if indexPath.isKnownKeysSection {
            let cell = tableView.dequeueReusableCell(withIdentifier: "key", for: indexPath)
            let key = knownKeys[indexPath.row]
            cell.textLabel?.text = key.name
            cell.detailTextLabel?.text = key.boundNetworkKey.name
            cell.accessoryType = selectedKeys.contains(key) ? .checkmark : .none
            return cell
        }
        fatalError()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.isUnknownKeysSection {
            if indexPath.row < missingKeys.count {
                // A key that is not known to the Node was selected.
                let key = missingKeys[indexPath.row]
                if let index = selectedKeys.firstIndex(of: key) {
                    selectedKeys.remove(at: index)
                } else {
                    selectedKeys.append(key)
                }
                tableView.reloadRows(at: [indexPath], with: .automatic)
            } else {
                // Add New Key was clicked
                let manager = MeshNetworkManager.instance
                if let network = manager.meshNetwork,
                   let newKey = try? network.add(applicationKey: .random128BitKey(), name: "App Key \(network.applicationKeys.count + 1)") {
                    _ = manager.save()
                    // Local Provisioner immediately knows all keys.
                    if node.isLocalProvisioner {
                        knownKeys.append(newKey)
                        tableView.beginUpdates()
                        // For the first key we need to add a section as well.
                        if knownKeys.count == 1 {
                            tableView.insertSections(IndexSet(integer: IndexPath.knownKeysSection), with: .automatic)
                        }
                        tableView.insertRows(at: [IndexPath(row: knownKeys.count - 1, section: IndexPath.knownKeysSection)], with: .automatic)
                        tableView.endUpdates()
                    } else {
                        missingKeys.append(newKey)
                        selectedKeys.append(newKey)
                        tableView.insertRows(at: [IndexPath(row: missingKeys.count - 1, section: IndexPath.unknownKeysSection)], with: .automatic)
                    }
                }
            }
        } else {
            // A key that was sent before is selected.
            let key = knownKeys[indexPath.row]
            if let index = selectedKeys.firstIndex(of: key) {
                selectedKeys.remove(at: index)
            } else {
                selectedKeys.append(key)
            }
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
        nextButton.title = selectedKeys.isEmpty ? "Skip" : "Next"
    }

}

private extension IndexPath {
    static let infoSection        = 0
    static let unknownKeysSection = 1
    static let knownKeysSection   = 2
    static let numberOfSection    = IndexPath.knownKeysSection + 1
    
    var isUnknownKeysSection: Bool {
        return section == IndexPath.unknownKeysSection
    }
    
    var isKnownKeysSection: Bool {
        return section == IndexPath.knownKeysSection
    }
    
}
