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

class RelatedModelsViewController: UITableViewController {
    
    // MARK: - Properties
    
    var model: Model!
    
    private var sections: [(title: String, models: [Model], emptyText: String?)] = []
    
    // MARK: - View Controller

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let directBaseModels = model.directBaseModels
        let directExtendingModels = model.directExtendingModels
        
        // Add Direct Base Models section.
        let directBaseModelsOnTheSameElement = directBaseModels
            .filter { $0.parentElement == model.parentElement }
        let directBaseModelsOnOtherElements = directBaseModels
            .filter { $0.parentElement != model.parentElement }
        if !directBaseModelsOnOtherElements.isEmpty || directBaseModelsOnOtherElements.isEmpty {
            sections.append((
                title: "Base Models",
                models: directBaseModelsOnTheSameElement,
                emptyText: "This model is a root model."
            ))
        }
        
        // Add Direct Base Models from other Elements.
        let directBaseModelsPerElement = directBaseModelsOnOtherElements.groupedByElement
        directBaseModelsPerElement.forEach { element, models in
            sections.append((
                title: "Base Models on \(element.name ?? "Element \(element.index + 1)")",
                models: models,
                emptyText: nil
            ))
        }
        
        // Add Direct Extending Models section.
        let directExtendingModelsOnTheSameElement = directExtendingModels
            .filter { $0.parentElement == model.parentElement }
        sections.append((
            title: "Extending Models",
            models: directExtendingModelsOnTheSameElement,
            emptyText: "This model is not extend by other Models."
        ))
        
        // Add Direct Base Models from other Elements.
        let directExtendingModelsOnOtherElements = directExtendingModels
            .filter { $0.parentElement != model.parentElement }
        let directExtendingModelsPerElement = directExtendingModelsOnOtherElements.groupedByElement
        directExtendingModelsPerElement.forEach { element, models in
            sections.append((
                title: "Extending Models on \(element.name ?? "Element \(element.index + 1)")",
                models: models,
                emptyText: nil
            ))
        }
        
        // Other other Related Models per Element.
        let relatedModels = model.relatedModels
            .filter { !directBaseModels.contains($0) && !directExtendingModels.contains($0) }
        let relatedModelsPerElement = relatedModels.groupedByElement
        relatedModelsPerElement.forEach { element, models in
            sections.append((
                title: "Related Models on \(element.name ?? "Element \(element.index + 1)")",
                models: models,
                emptyText: nil
            ))
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(1, sections[section].models.count)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = sections[indexPath.section]
        guard !section.models.isEmpty else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "empty", for: indexPath)
            cell.textLabel?.text = section.emptyText
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "model", for: indexPath)
        let model = section.models[indexPath.row]
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
        return cell
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return !sections[indexPath.section].models.isEmpty
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        performSegue(withIdentifier: "details", sender: indexPath)
    }

    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "details" {
            let indexPath = sender as! IndexPath
            let model = sections[indexPath.section].models[indexPath.row]
            let destination = segue.destination as! ModelViewController
            destination.model = model
        }
    }

}

private extension Array where Element == Model {
    
    var groupedByElement: [(element: MeshElement, models: [Model])] {
        var map: [MeshElement: [Model]] = [:]
        
        forEach { model in
            if let element = model.parentElement {
                if map[element] == nil {
                    map[element] = [model]
                } else {
                    map[element]?.append(model)
                }
            }
        }
        return map
            // Map from a dictionary to an array of touples.
            .map { ($0, $1) }
            // Sort by Element index.
            .sorted { $0.element.index < $1.element.index }
    }
    
}


