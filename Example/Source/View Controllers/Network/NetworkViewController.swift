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

private enum SectionType {
    case notConfiguredNodes
    case configuredNodes
    case provisionersNodes
    case thisProvisioner
    
    var title: String? {
        switch self {
        case .notConfiguredNodes: return nil
        case .configuredNodes:    return "Configured Nodes"
        case .provisionersNodes:  return "Other Provisioners"
        case .thisProvisioner:    return "This Provisioner"
        }
    }
}

private struct Section {
    let type: SectionType
    let nodes: [Node]
    
    init(type: SectionType, nodes: [Node]) {
        self.type = type
        self.nodes = nodes
    }
    
    var title: String? {
        return type.title
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> NodeViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "node", for: indexPath) as! NodeViewCell
        cell.node = nodes[indexPath.row]
        return cell
    }
}

class NetworkViewController: UITableViewController {
    private var sections: [Section] = []
    
    // MARK: - Implementation
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.setEmptyView(title: "No Nodes",
                               message: "Click + to provision a new device.",
                               messageImage: #imageLiteral(resourceName: "baseline-network"))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        
        MeshNetworkManager.instance.delegate = self
        
        reloadData()
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "provision" {
            let network = MeshNetworkManager.instance.meshNetwork
            let hasProvisioner = network?.localProvisioner != nil
            // If the Provisioner has not been set before,
            // display the error message.
            // When the OK button is clicked the Add Provisioner popup will present.
            // When done, the Provisioning will resume.
            if !hasProvisioner {
                presentAlert(title: "Provisioner not set", message: "Create a Provisioner before provisioning a new device.") { _ in
                    let storyboard = UIStoryboard(name: "Settings", bundle: .main)
                    let popup = storyboard.instantiateViewController(withIdentifier: "newProvisioner")
                    if let popup = popup as? UINavigationController,
                        let editProvisionerViewController = popup.topViewController as? EditProvisionerViewController {
                        editProvisionerViewController.delegate = self
                    }
                    self.present(popup, animated: true)
                }
            }
            return hasProvisioner
        }
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "provision":
            let destination = segue.destination as! UINavigationController
            let scannerViewController = destination.topViewController! as! ScannerTableViewController
            scannerViewController.delegate = self
        case "configure":
            let destination = segue.destination as! ConfigurationViewController
            destination.node = sender as? Node
        case "open":
            let cell = sender as! NodeViewCell
            let destination = segue.destination as! ConfigurationViewController
            destination.node = cell.node
        default:
            break
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].nodes.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return sections[indexPath.section].tableView(tableView, cellForRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

private extension NetworkViewController {
    
    func reloadData() {
        sections.removeAll()
        if let network = MeshNetworkManager.instance.meshNetwork {
            let notConfiguredNodes = network.nodes.filter({ !$0.isConfigComplete && !$0.isProvisioner })
            let configuredNodes    = network.nodes.filter({ $0.isConfigComplete && !$0.isProvisioner })
            let provisionersNodes  = network.nodes.filter({ $0.isProvisioner && !$0.isLocalProvisioner })
            
            if !notConfiguredNodes.isEmpty {
                sections.append(Section(type: .notConfiguredNodes, nodes: notConfiguredNodes))
            }
            if !configuredNodes.isEmpty {
                sections.append(Section(type: .configuredNodes, nodes: configuredNodes))
            }
            if !provisionersNodes.isEmpty {
                sections.append(Section(type: .provisionersNodes, nodes: provisionersNodes))
            }
            if let thisProvisionerNode = network.localProvisioner?.node {
                sections.append(Section(type: .thisProvisioner, nodes: [thisProvisionerNode]))
            }
        }
        tableView.reloadData()
        
        if sections.isEmpty {
            tableView.showEmptyView()
        } else {
            tableView.hideEmptyView()
        }
    }
    
}

extension NetworkViewController: ProvisioningViewDelegate {
    
    func provisionerDidProvisionNewDevice(_ node: Node) {
        performSegue(withIdentifier: "configure", sender: node)
    }
    
}

extension NetworkViewController: EditProvisionerDelegate {
    
    func provisionerWasAdded(_ provisioner: Provisioner) {
        // A new Provisioner was added. Continue wit provisioning.
        performSegue(withIdentifier: "provision", sender: nil)
    }
    
    func provisionerWasModified(_ provisioner: Provisioner) {
        // Not used.
    }
    
}

extension NetworkViewController: MeshNetworkDelegate {
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            didReceiveMessage message: MeshMessage,
                            sentFrom source: Address, to destination: Address) {
        switch message {
            
        case is ConfigNodeReset:
            // The node has been reset remotely.
            (UIApplication.shared.delegate as! AppDelegate).meshNetworkDidChange()
            reloadData()
            presentAlert(title: "Reset", message: "The mesh network was reset remotely.")
            
        default:
            break
        }
    }
    
}
