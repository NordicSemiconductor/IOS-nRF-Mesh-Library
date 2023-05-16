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
    
    private var selectedKeys: [ApplicationKey] = []
    
    // MARK: - View Controller

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let network = MeshNetworkManager.instance.meshNetwork!
        network.applicationKeys.first.map {
            selectedKeys.append($0)
        }
        nextButton.isEnabled = !selectedKeys.isEmpty
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "next" {
            let destination = segue.destination as! SelectModelsForBindingViewController
            destination.node = node
            destination.selectedKeys = selectedKeys.sorted { $0.index < $1.index }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return IndexPath.numberOfSection
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case IndexPath.infoSection:
            return 0
        case IndexPath.keysSection:
            let network = MeshNetworkManager.instance.meshNetwork!
            return network.applicationKeys.count + 1 // Add New Key
        default: fatalError()
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case IndexPath.keysSection:
            return "Application Keys"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case IndexPath.infoSection:
            return "Select Application Keys to bind to Models."
        case IndexPath.keysSection:
            return "If necessary, selected keys will be added automatically."
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let network = MeshNetworkManager.instance.meshNetwork!
        guard indexPath.row < network.applicationKeys.count else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "action", for: indexPath)
            cell.detailTextLabel?.text = "Bound to \(node.networkKeys.first!.name)"
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "key", for: indexPath)
        let key = network.applicationKeys[indexPath.row]
        cell.textLabel?.text = key.name
        cell.detailTextLabel?.text = key.boundNetworkKey.name
        cell.accessoryType = selectedKeys.contains(key) ? .checkmark : .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let manager = MeshNetworkManager.instance
        let network = manager.meshNetwork!
        guard indexPath.row < network.applicationKeys.count else {
            let index = network.applicationKeys.count + 1
            if let newKey = try? network.add(applicationKey: .random128BitKey(), name: "App Key \(index)") {
                _ = manager.save()
                selectedKeys.append(newKey)
                tableView.insertRows(at: [indexPath], with: .automatic)
                nextButton.isEnabled = true
            }
            return
        }
    
        let key = network.applicationKeys[indexPath.row]
        if let index = selectedKeys.firstIndex(of: key) {
            selectedKeys.remove(at: index)
        } else {
            selectedKeys.append(key)
        }
        tableView.reloadRows(at: [indexPath], with: .automatic)
        nextButton.isEnabled = !selectedKeys.isEmpty
    }

}

private extension IndexPath {
    static let infoSection     = 0
    static let keysSection     = 1
    static let numberOfSection = IndexPath.keysSection + 1
    
    var isKeysSection: Bool {
        return section == IndexPath.keysSection
    }
    
}
