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

class SelectModelsViewController: UITableViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var nextButton: UIBarButtonItem!
    
    // MARK: - Public properties
    
    var node: Node!
    var selectedKeys: [ApplicationKey]!
    
    // MARK: - Private properties
    
    private var selectedModels: [Model] = []
    
    // MARK: - View Controller

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // If no App Keys are selected, the step can be skipped.
        nextButton.title = "Skip"
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return node.elements.count + 1 // Info
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == IndexPath.infoSection {
            return 0
        }
        return node.elements[section - 1].models.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section > 0 {
            return node.elements[section - 1].name ?? "Element \(section)"
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == IndexPath.infoSection {
            return "ⓘ Select Models to bind the Application Keys to.\n\nⓘ Skip to only transfer "
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = node.elements[indexPath.section - 1].models[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "model", for: indexPath)
        cell.textLabel?.text = model.name
        if model.isBluetoothSIGAssigned {
            cell.textLabel?.text = model.name ?? "Unknown Model ID: \(model.modelIdentifier.asString())"
            cell.detailTextLabel?.text = "Bluetooth SIG"
        } else {
            cell.textLabel?.text = "Vendor Model ID: \(model.modelIdentifier.asString())"
            if let companyId = model.companyIdentifier {
                if let companyName = CompanyIdentifier.name(for: companyId) {
                    cell.detailTextLabel?.text = companyName
                } else {
                    cell.detailTextLabel?.text = "Unknown Company ID (\(companyId.asString()))"
                }
            } else {
                cell.detailTextLabel?.text = "Unknown Company ID"
            }
        }
        cell.accessoryType = selectedModels.contains(model) ? .checkmark : .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let model = node.elements[indexPath.section - 1].models[indexPath.row]
        if let index = selectedModels.firstIndex(of: model) {
            selectedModels.remove(at: index)
        } else {
            selectedModels.append(model)
        }
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }

}

private extension IndexPath {
    static let infoSection = 0
}
