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

class SelectModelsForPublicationViewController: UITableViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var selectAction: UIBarButtonItem!
    @IBOutlet weak var nextButton: UIBarButtonItem!
    
    @IBAction func selectActionTapped(_ sender: UIBarButtonItem) {
        if selectedModels.count == allModels.count {
            selectedModels.removeAll()
            selectAction.title = "Select All"
            nextButton.isEnabled = false
        } else {
            selectedModels = allModels
            selectAction.title = "Select None"
            nextButton.isEnabled = true
        }
        tableView.reloadData()
    }
    
    // MARK: - Public properties
    
    var node: Node!
    var publish: Publish!
    
    // MARK: - Private properties
    
    private var selectedModels: [Model] = []
    private var allModels: [Model]!
    
    // MARK: - View Controller

    override func viewDidLoad() {
        super.viewDidLoad()
        
        allModels = node.elements
            .flatMap { $0.models }
            .filter { $0.supportsModelPublication ?? true }
        // Initially, no Models are selected.
        nextButton.isEnabled = false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "start" {
            let destination = segue.destination as! ConfigurationViewController
            destination.set(publication: publish, to: selectedModels)
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return IndexPath.numberOfFixedSection + node.elements.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case IndexPath.infoSection:
            return 0
        default:
            return node
                .elements[section.elementIndex]
                .models.count
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case IndexPath.infoSection:
            return nil
        default:
            return node.elements[section.elementIndex].name ?? "Element \(section)"
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case IndexPath.infoSection:
            return "Select Models for setting Publication."
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = node
            .elements[indexPath.section.elementIndex]
            .models[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "model", for: indexPath)
        cell.textLabel?.text = model.modelName
        cell.detailTextLabel?.text = model.companyName
        cell.accessoryType = selectedModels.contains(model) ? .checkmark : .none
        cell.isEnabled = model.supportsApplicationKeyBinding
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Find the Model under the selected row.
        let model = node
            .elements[indexPath.section.elementIndex]
            .models[indexPath.row]
        
        // Toggle the selection.
        if let index = selectedModels.firstIndex(of: model) {
            selectedModels.remove(at: index)
        } else {
            selectedModels.append(model)
        }
        tableView.reloadRows(at: [indexPath], with: .automatic)
        nextButton.isEnabled = !selectedModels.isEmpty
        
        // If all Models were selected, change the button to Select None.
        if selectedModels.count == allModels.count {
            selectAction.title = "Select None"
        } else {
            selectAction.title = "Select All"
        }
    }

}

private extension IndexPath {
    
    static let infoSection = 0
    static let numberOfFixedSection =  Self.infoSection + 1
    
}

private extension Int {
    
    var elementIndex: Int {
        return self - IndexPath.numberOfFixedSection
    }
    
}
