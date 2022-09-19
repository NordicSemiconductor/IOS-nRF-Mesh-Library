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

protocol SelectionDelegate {
    func networkKeySelected(_ networkKey: NetworkKey?)
}

class NetworkKeySelectionViewController: UITableViewController {
    
    var selectedNetworkKey: NetworkKey!
    var delegate: SelectionDelegate?
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        let count = MeshNetworkManager.instance.meshNetwork?.networkKeys.count ?? 0
        return min(count, 2)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Primary Network Key"
        default:
            return "Subnetwork Keys"
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = MeshNetworkManager.instance.meshNetwork?.networkKeys.count ?? 0
        switch section {
        case 0:
            return count > 0 ? 1 : 0
        default:
            return count - 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let network = MeshNetworkManager.instance.meshNetwork!
        let networkKey = network.networkKeys[indexPath.keyIndex]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "subtitleCell", for: indexPath)
        cell.textLabel?.text = networkKey.name
        cell.detailTextLabel?.text = networkKey.key.hex
        
        if networkKey == selectedNetworkKey {
            cell.accessoryType = .checkmark
            // Save the checked row number as tag.
            tableView.tag = indexPath.keyIndex
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let network = MeshNetworkManager.instance.meshNetwork!
        selectedNetworkKey = network.networkKeys[indexPath.keyIndex]
        delegate?.networkKeySelected(selectedNetworkKey)
        
        let row = max(tableView.tag - 1, 0)
        let section = tableView.tag > 0 ? 1 : 0
        tableView.reloadRows(at: [indexPath, IndexPath(row: row, section: section)], with: .fade)
    }

}

private extension IndexPath {
    
    /// Returns the Network Key index in mesh network based on the
    /// IndexPath.
    var keyIndex: Int {
        return section + row
    }
    
}
