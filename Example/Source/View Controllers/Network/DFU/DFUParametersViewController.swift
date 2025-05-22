/*
* Copyright (c) 2025, Nordic Semiconductor
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
import NordicMesh
import iOSMcuManagerLibrary

class DFUParametersViewController: UITableViewController {
    private let tagTransferMode = 0
    private let tagUpdatePolicy = 1
    
    // MARK: - Properties
    
    var distributor: Node! {
        didSet {
            ttl = distributor.defaultTTL ?? 5
        }
    }
    var bearer: GattBearer!
    var applicationKey: ApplicationKey!
    var receivers: [Receiver]!
    var updatePackage: UpdatePackage!
    
    private var ttl: UInt8 = 0
    private var timeoutBase: UInt16 = 118
    private var transferMode: TransferMode = .push
    private var updatePolicy: FirmwareUpdatePolicy = .verifyOnly
    private var selectedGroup: Group?
    
    private var groups: [Group]!
    
    // MARK: - View Controller

    override func viewDidLoad() {
        super.viewDidLoad()

        let manager = MeshNetworkManager.instance
        let network = manager.meshNetwork
        groups = network?.groups ?? []
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "next" {
            let destination = segue.destination as! ConfigurationViewController
            destination.update(receivers: receivers, with: updatePackage,
                               parameters: DFUParameters(
                                    applicationKey: applicationKey,
                                    ttl: ttl, timeoutBase: timeoutBase,
                                    transferMode: transferMode, updatePolicy: updatePolicy,
                                    selectedGroup: selectedGroup
                               ),
                               on: distributor, over: bearer)
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return IndexPath.numberOfSections
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case IndexPath.paramsSection: return "Firmware Distribution Parameters"
        case IndexPath.multicastSection: return "Multicast Distribution"
        default: fatalError("Invalid section")
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case IndexPath.multicastSection: return "Firmware Update Server and BLOB Server models on target nodes will get automatically subscribed to the selected group."
        default: return nil
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case IndexPath.paramsSection: return IndexPath.numberOfRows
        case IndexPath.multicastSection: return groups.count + 1 // Unassigned group
        default: fatalError("Invalid section")
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case IndexPath.paramsSection:
            switch indexPath.row {
            case IndexPath.ttlRow:
                let cell = tableView.dequeueReusableCell(withIdentifier: "ttl", for: indexPath)
                cell.detailTextLabel?.text = "\(ttl)"
                return cell
            case IndexPath.timeoutRow:
                let cell = tableView.dequeueReusableCell(withIdentifier: "timeout", for: indexPath) as! TimeoutViewCell
                cell.ttl = ttl
                cell.delegate = self
                return cell
            case IndexPath.transferModeRow:
                let cell = tableView.dequeueReusableCell(withIdentifier: "option", for: indexPath) as! SegmentedControlViewCell
                cell.label.text = "Transfer Mode"
                cell.segmentedControl.tag = tagTransferMode
                cell.segmentedControl.setTitle("Push", forSegmentAt: 0)
                cell.segmentedControl.setTitle("Pull", forSegmentAt: 1)
                cell.segmentedControl.selectedSegmentIndex = transferMode == .push ? 0 : 1
                cell.delegate = self
                return cell
            case IndexPath.updatePolicyRow:
                let cell = tableView.dequeueReusableCell(withIdentifier: "option", for: indexPath) as! SegmentedControlViewCell
                cell.label.text = "Update Policy"
                cell.segmentedControl.tag = tagUpdatePolicy
                cell.segmentedControl.setTitle("Verify Only", forSegmentAt: 0)
                cell.segmentedControl.setTitle("Verify and Apply", forSegmentAt: 1)
                cell.segmentedControl.selectedSegmentIndex = updatePolicy == .verifyOnly ? 0 : 1
                cell.delegate = self
                return cell
            default: fatalError("Invalid row")
            }
        case IndexPath.multicastSection:
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "unassigned", for: indexPath)
                cell.accessoryType = selectedGroup == nil ? .checkmark : .none
                return cell
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: "group", for: indexPath)
            let group = groups[indexPath.row - 1]
            cell.textLabel?.text = group.name
            cell.accessoryType = selectedGroup == group ? .checkmark : .none
            // Virtual Address is not supported yet.
            cell.isEnabled = group.address.virtualLabel == nil
            return cell
        default: fatalError("Invalid section")
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        // Only TTL is selectable in params section.
        return indexPath.row == IndexPath.ttlRow || indexPath.section == IndexPath.multicastSection
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case IndexPath.paramsSection:
            // In section 0 only the TTL is selectable.
            presentTTLDialog()
        case IndexPath.multicastSection:
            let index = groups.firstIndex { $0 == selectedGroup }
            if indexPath.row == 0 {
                selectedGroup = nil
            } else {
                selectedGroup = groups[indexPath.row - 1]
            }
            if let index = index {
                let oldIndexPath = IndexPath(row: index + 1, section: indexPath.section)
                tableView.reloadRows(at: [oldIndexPath, indexPath], with: .automatic)
            } else {
                tableView.reloadRows(at: [IndexPath(row: 0, section: indexPath.section), indexPath], with: .automatic)
            }
            break
        default:
            fatalError("Invalid section")
        }
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        guard indexPath.section == 0 else { return }
        switch indexPath.row {
        case IndexPath.timeoutRow: // Timeout
            presentAlert(title: "Timeout",
                         message: "Timeout is calculated using the following formula:\n\n10000 * (Timeout Base + 2) + 100 * TTL (milliseconds)\n\n" +
                                  "Timeout Base is a UINT16 value, but for simplicity the range of the slider is limited to a subset of values.\n" +
                                  "Currently selected Timeout Base is \(timeoutBase).")
        default:
            break
        }
    }

}

extension DFUParametersViewController: TimeoutViewCell.Delegate, SegmentedControlViewCell.Delegate {
    
    func timeoutBase(didChange timeoutBase: UInt16) {
        self.timeoutBase = timeoutBase
    }
    
    func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        switch sender.tag {
        case tagTransferMode:
            transferMode = sender.selectedSegmentIndex == 0 ? .push : .pull
        case tagUpdatePolicy:
            updatePolicy = sender.selectedSegmentIndex == 0 ? .verifyOnly : .verifyAndApply
        default:
            fatalError("Invalid tag")
        }
    }
    
}

private extension DFUParametersViewController {
 
    /// Presents a dialog to edit the Initial TTL for Heartbeat messages.
    func presentTTLDialog() {
        presentTextAlert(title: "Update TTL",
                         message: "TTL = Time To Live\n\nTTL to be used when distributing firmware.\n"
                                + "Max value is 127. Message with TTL 0 will not be relayed.",
                         text: "\(ttl)", placeHolder: "Default is \(distributor.defaultTTL ?? 5)",
                         type: .ttlRequired, cancelHandler: nil) { value in
            self.ttl = UInt8(value)!
            self.tableView.reloadRows(at: [.ttl, .timeout], with: .none)
        }
    }
    
}

private extension IndexPath {
    static let paramsSection = 0
    static let multicastSection = 1
    static let numberOfSections = multicastSection + 1
    
    static let ttlRow = 0
    static let timeoutRow = 1
    static let transferModeRow = 2
    static let updatePolicyRow = 3
    static let numberOfRows = updatePolicyRow + 1
    
    static let ttl = IndexPath(row: ttlRow, section: paramsSection)
    static let timeout = IndexPath(row: timeoutRow, section: paramsSection)
}
