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

protocol HeartbeatSubscriptionDelegate {
    /// This method is called when the Heartbeat subscription was set.
    func heartbeatSubscriptionSet()
}

class SetHeartbeatSubscriptionViewController: ProgressViewController {
    
    // MARK: - Outlets & Actions
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    @IBAction func doneTapped(_ sender: UIBarButtonItem) {
        setSubscription()
    }
    
    // MARK: - Properties
    
    var node: Node!
    var delegate: HeartbeatSubscriptionDelegate?
    
    private var selectedSource: Address?
    private var selectedDestination: Address?
    private var periodLog: UInt8 = 1 // 0 is not allowed
    
    /// List of all Nodes, except the target one.
    private var nodes: [Node]!
    private var groups: [Group]!
    private var selectedSourceIndexPath: IndexPath?
    private var selectedDestinationIndexPath: IndexPath?
    
    // MARK: - Table View Controller

    override func viewDidLoad() {
        super.viewDidLoad()
        
        MeshNetworkManager.instance.delegate = self

        let network = MeshNetworkManager.instance.meshNetwork!
        // Exclude the current Node.
        nodes = network.nodes.filter { $0.uuid != node.uuid }
        // Virtual Groups may not be set as Heartbeat destination.
        // They will be shown as disabled.
        // Sort the groups, so the Virtual Groups are at the end.
        groups = network.groups.sorted { $1.address.address.isVirtual }
        
        if let subscription = node.heartbeatSubscription {
            selectedSource = subscription.source
            selectedDestination = subscription.destination
            // Otherwise Done button is by default disabled in the Storyboard.
            doneButton.isEnabled = true
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return IndexPath.numberOfSections(for: groups)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case IndexPath.periodSection:
            return 1
        case IndexPath.sourceSection:
            return nodes.count
        case IndexPath.destinationNodeSection:
            return 1
        case IndexPath.destinationGroupsSection where !groups.isEmpty:
            return groups.count
        default:
            return Group.specialGroups.count
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case IndexPath.periodSection:
            return "Period"
        case IndexPath.sourceSection:
            return "Source"
        case IndexPath.destinationNodeSection:
            return "Destination"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == IndexPath.destinationGroupsSection && groups.contains(where: { $0.address.address.isVirtual }) {
            return "Note: Heartbeat messages cannot be sent to Virtual Groups."
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: indexPath.reuseIdentifier,
                                                 for: indexPath)
        if indexPath.isPeriodSection {
            let periodCell = cell as! HeartbeatSubscriptionPeriodCell
            periodCell.delegate = self
            periodCell.periodLog = periodLog
        }
        if indexPath.isSourceSection {
            let otherNode = nodes[indexPath.row]
            if let source = selectedSource, source == otherNode.primaryUnicastAddress {
                selectedSourceIndexPath = indexPath
                selectedSource = nil
            }
            cell.textLabel?.text = otherNode.name ?? "Unknown Device"
            cell.accessoryType = indexPath == selectedSourceIndexPath ? .checkmark : .none
            cell.isEnabled = true
        }
        if indexPath.isDestinationSection {
            if let destination = selectedDestination, destination == node.primaryUnicastAddress {
                selectedDestinationIndexPath = indexPath
                selectedDestination = nil
            }
            cell.textLabel?.text = node.name ?? "Unknown Device"
            cell.accessoryType = indexPath == selectedDestinationIndexPath ? .checkmark : .none
            cell.isEnabled = true
        }
        if indexPath.isGroupsSection && !groups.isEmpty {
            let group = groups[indexPath.row]
            if let destination = selectedDestination, destination == group.address.address {
                selectedDestinationIndexPath = indexPath
                selectedDestination = nil
            }
            cell.textLabel?.text = group.name
            cell.accessoryType = indexPath == selectedDestinationIndexPath ? .checkmark : .none
            cell.isEnabled = !group.address.address.isVirtual
        }
        if indexPath.isSpecialGroupsSection || (indexPath.isGroupsSection && groups.isEmpty) {
            let group = Group.specialGroups[indexPath.row]
            if let destination = selectedDestination, destination == group.address.address {
                selectedDestinationIndexPath = indexPath
                selectedDestination = nil
            }
            cell.textLabel?.text = group.name
            cell.accessoryType = indexPath == selectedDestinationIndexPath ? .checkmark : .none
            cell.isEnabled = true
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !indexPath.isPeriodSection else {
            return
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.isSourceSection {
            sourceSelected(indexPath)
        } else {
            destinationSelected(indexPath)
        }
        doneButton.isEnabled = selectedSourceIndexPath != nil &&
                               selectedDestinationIndexPath != nil
    }

}

extension SetHeartbeatSubscriptionViewController: HeartbeatSubscriptionPeriodDelegate {
    
    func periodDidChange(_ periodLog: UInt8) {
        self.periodLog = periodLog
    }
    
}

private extension SetHeartbeatSubscriptionViewController {
    
    func sourceSelected(_ indexPath: IndexPath) {
        // Refresh previously selected and the new rows.
        var rows: [IndexPath] = []
        if let previousSelection = selectedSourceIndexPath {
            rows.append(previousSelection)
        }
        selectedSourceIndexPath = indexPath
        rows.append(indexPath)
        tableView.reloadRows(at: rows, with: .automatic)
    }
    
    func destinationSelected(_ indexPath: IndexPath) {
        // Refresh previously selected and the new rows.
        var rows: [IndexPath] = []
        if let previousSelection = selectedDestinationIndexPath {
            rows.append(previousSelection)
        }
        selectedDestinationIndexPath = indexPath
        rows.append(indexPath)
        tableView.reloadRows(at: rows, with: .automatic)
    }
    
    func setSubscription() {
        guard let sourceIndexPath = selectedSourceIndexPath,
              let destinationIndexPath = selectedDestinationIndexPath,
              let node = self.node else {
            return
        }
        let sourceAddress = nodes[sourceIndexPath.row].primaryUnicastAddress
        let destinationAddress =
            destinationIndexPath.isDestinationSection ?
                node.primaryUnicastAddress :
                destinationIndexPath.isGroupsSection && !groups.isEmpty ?
                    groups[destinationIndexPath.row].address.address :
                    Group.specialGroups[destinationIndexPath.row].address.address
        let periodLog = self.periodLog
        
        start("Setting Heartbeat Subscription...") {
            let message: AcknowledgedConfigMessage =
                ConfigHeartbeatSubscriptionSet(startProcessingHeartbeatMessagesFor: periodLog,
                                               secondsSentFrom: sourceAddress,
                                               to: destinationAddress)!
            return try MeshNetworkManager.instance.send(message, to: node)
        }
    }
    
}

extension SetHeartbeatSubscriptionViewController: MeshNetworkDelegate {
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            didReceiveMessage message: MeshMessage,
                            sentFrom source: Address, to destination: MeshAddress) {
        // Has the Node been reset remotely.
        guard !(message is ConfigNodeReset) else {
            (UIApplication.shared.delegate as! AppDelegate).meshNetworkDidChange()
            done {
                let rootViewControllers = self.presentingViewController?.children
                self.dismiss(animated: true) {
                    rootViewControllers?.forEach {
                        if let navigationController = $0 as? UINavigationController {
                            navigationController.popToRootViewController(animated: true)
                        }
                    }
                }
            }
            return
        }
        // Is the message targeting the current Node?
        guard node.primaryUnicastAddress == source else {
            return
        }
        
        // Handle the message based on its type.
        switch message {
            
        case let status as ConfigHeartbeatSubscriptionStatus:
            done {
                if status.status == .success {
                    self.dismiss(animated: true)
                    self.delegate?.heartbeatSubscriptionSet()                    
                } else {
                    self.presentAlert(title: "Error", message: status.message)
                }
            }
            
        default:
            break
        }
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            failedToSendMessage message: MeshMessage,
                            from localElement: Element, to destination: MeshAddress,
                            error: Error) {
        // Ignore messages sent from model publication.
        guard message is ConfigMessage else {
            return
        }
        done {
            self.presentAlert(title: "Error", message: error.localizedDescription)
        }
    }
    
}

private extension IndexPath {
    static let periodSection = 0
    static let sourceSection = 1
    static let destinationNodeSection = 2
    static let destinationGroupsSection = 3
    static let destinationSpecialGroupsSection = 4
    
    static func numberOfSections(for groups: [Group]) -> Int {
        return groups.isEmpty ?
            IndexPath.destinationGroupsSection + 1 :
            IndexPath.destinationSpecialGroupsSection + 1
    }
    
    var reuseIdentifier: String {
        switch section {
        case IndexPath.periodSection:
            return "period"
        case IndexPath.sourceSection, IndexPath.destinationNodeSection:
            return "node"
        default:
            return "group"
        }
    }
    
    var isPeriodSection: Bool {
        return section == IndexPath.periodSection
    }
    
    var isSourceSection: Bool {
        return section == IndexPath.sourceSection
    }
    
    var isDestinationSection: Bool {
        return section == IndexPath.destinationNodeSection
    }
    
    var isGroupsSection: Bool {
        return section == IndexPath.destinationGroupsSection
    }
    
    var isSpecialGroupsSection: Bool {
        return section == IndexPath.destinationSpecialGroupsSection
    }
}
