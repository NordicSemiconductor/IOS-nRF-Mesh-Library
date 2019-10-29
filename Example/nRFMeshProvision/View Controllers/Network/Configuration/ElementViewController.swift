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
//

import UIKit
import nRFMeshProvision

class ElementViewController: UITableViewController {
    
    // MARK: - Properties
    
    var element: Element!
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = element.name ?? "Element \(element.index + 1)"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        MeshNetworkManager.instance.delegate = self
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showModel" {
            let indexPath = sender as! IndexPath
            let model = element.models[indexPath.row]
            let destination = segue.destination as! ModelViewController
            destination.model = model
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if element.models.isEmpty {
            return IndexPath.numberOfSection - 1
        }
        return IndexPath.numberOfSection
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case IndexPath.nameSection:
            return IndexPath.titles.count
        case IndexPath.detailsSection:
            return IndexPath.detailsTitles.count
        case IndexPath.modelsSection:
            return element.models.count
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case IndexPath.modelsSection:
            return "Models"
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: indexPath.cellIdentifier, for: indexPath)
        
        if indexPath.isName {
            cell.textLabel?.text = indexPath.title
            cell.detailTextLabel?.text = element.name ?? "No name"
            cell.accessoryType = .disclosureIndicator
        }
        if indexPath.isDetailsSection {
            cell.textLabel?.text = indexPath.title
            cell.accessoryType = .none
            
            switch indexPath.row {
            case 0: // Unicast Address
                let address = element.parentNode!.unicastAddress
                cell.detailTextLabel?.text = "\((address + UInt16(element.index)).asString())"
            case 1: // Location
                cell.detailTextLabel?.text = "\(element.location)"
            default:
                break
            }
        }
        if indexPath.isModelsSection {
            let model = element.models[indexPath.row]
            
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
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return !indexPath.isDetailsSection
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.isName {
            presentNameDialog()
        }
        if indexPath.isModelsSection {
            performSegue(withIdentifier: "showModel", sender: indexPath)
        }
    }
}

extension ElementViewController: MeshNetworkDelegate {
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            didReceiveMessage message: MeshMessage,
                            sentFrom source: Address, to destination: Address) {
        // Has the Node been reset remotely.
        guard !(message is ConfigNodeReset) else {
            (UIApplication.shared.delegate as! AppDelegate).meshNetworkDidChange()
            navigationController?.popToRootViewController(animated: true)
            return
        }
        // Is the message targetting the current Node?
        guard element.unicastAddress == source else {
            return
        }
        
        // Handle the message based on its type.
        switch message {
            
        default:
            break
        }
    }
    
}

private extension ElementViewController {
    
    /// Presents a dialog to edit the Element name.
    func presentNameDialog() {
        presentTextAlert(title: "Network Name", message: nil, text: element.name,
                         placeHolder: "E.g. My House", type: .name) { name in
                            self.element.name = name.isEmpty ? nil : name
                            
                            if MeshNetworkManager.instance.save() {
                                self.title = self.element.name ?? "Element \(self.element.index + 1)"
                                self.tableView.reloadRows(at: [.name], with: .automatic)
                            } else {
                                self.presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
                            }
        }
    }
    
}

private extension IndexPath {
    static let nameSection    = 0
    static let detailsSection = 1
    static let modelsSection  = 2
    static let numberOfSection = IndexPath.modelsSection + 1
    
    static let titles = [
        "Name"
    ]
    
    static let detailsTitles = [
        "Unicast Address", "Location"
    ]
    
    var cellIdentifier: String {
        if isModelsSection {
            return "subtitle"
        }
        return "normal"
    }
    
    var title: String? {
        if isName {
            return IndexPath.titles[row]
        }
        if isDetailsSection {
            return IndexPath.detailsTitles[row]
        }
        return nil
    }
    
    var isName: Bool {
        return section == IndexPath.nameSection && row == 0
    }
    
    var isNameSection: Bool {
        return section == IndexPath.nameSection
    }
    
    var isDetailsSection: Bool {
        return section == IndexPath.detailsSection
    }
    
    var isModelsSection: Bool {
        return section == IndexPath.modelsSection
    }
    
    static let name  = IndexPath(row: 0, section: IndexPath.nameSection)
}
