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

class NetworkViewController: UITableViewController, UISearchBarDelegate {
    private var sections: [Section] = []
    
    // MARK: - Search Bar
    
    private var searchController: UISearchController!
    private var filteredSections: [Section] = []
    
    // MARK: - Implementation
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.setEmptyView(title: "No Nodes",
                               message: "Click + to provision a new device.",
                               messageImage: #imageLiteral(resourceName: "baseline-network"))
        createSearchBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
            let destination = segue.destination as! NodeViewController
            let (node, originalNode) = sender as! (Node, Node?)
            destination.node = node
            destination.originalNode = originalNode
        case "open":
            let cell = sender as! NodeViewCell
            let destination = segue.destination as! NodeViewController
            destination.node = cell.node
        default:
            break
        }
    }
    
    // MARK: - Search Bar Delegate
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        applyFilter(searchText)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        applyFilter("")
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return filteredSections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredSections[section].nodes.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return filteredSections[section].title
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return filteredSections[indexPath.section].tableView(tableView, cellForRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

private extension NetworkViewController {
    
    func createSearchBar() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.placeholder = "Name, Unicast Address"
        searchController.searchBar.delegate = self
        searchController.searchBar.isTranslucent = false
        if #available(iOS 13.0, *) {
            searchController.searchBar.searchTextField.tintColor = .label
            searchController.searchBar.searchTextField.backgroundColor = .systemBackground
        }
        navigationItem.searchController = searchController
    }
    
    func applyFilter(_ searchText: String) {
        if searchText.isEmpty {
            filteredSections = sections
        } else {
            filteredSections = sections
                .map { section in
                    let filteredNodes = section.nodes.filter {
                        $0.name?.lowercased().contains(searchText.lowercased()) ?? false ||
                        $0.primaryUnicastAddress.asString().lowercased().contains(searchText.lowercased())
                    }
                    return Section(type: section.type, nodes: filteredNodes)
                }
                .filter { !$0.nodes.isEmpty }
        }
        tableView.reloadData()
        
        if filteredSections.isEmpty {
            tableView.showEmptyView()
        } else {
            tableView.hideEmptyView()
        }
    }
    
    func reloadData() {
        sections.removeAll()
        if let network = MeshNetworkManager.instance.meshNetwork {
            let notConfiguredNodes = network.nodes.filter { !$0.isConfigComplete && !$0.isProvisioner }
            let configuredNodes    = network.nodes.filter { $0.isConfigComplete && !$0.isProvisioner }
            let provisionersNodes  = network.nodes.filter { $0.isProvisioner && !$0.isLocalProvisioner }
            
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
        applyFilter(searchController.searchBar.text ?? "")
    }
    
}

extension NetworkViewController: ProvisioningViewDelegate {
    
    func provisionerDidProvisionNewDevice(_ node: Node, whichReplaced previousNode: Node?) {
        performSegue(withIdentifier: "configure", sender: (node, previousNode))
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
                            sentFrom source: Address, to destination: MeshAddress) {
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
