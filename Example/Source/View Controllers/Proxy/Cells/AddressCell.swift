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

class AddressCell: UITableViewCell {

    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var subtitle: UILabel!
    @IBOutlet weak var detail: UILabel!
    
    var address: Address! {
        didSet {
            let meshNetwork = MeshNetworkManager.instance.meshNetwork!
            switch address! {
                
            case let address where address.isUnicast:
                let node = meshNetwork.node(withAddress: address)
                let targetElement = node?.element(withAddress: address)
                
                title.text = targetElement != nil ?
                    targetElement!.name ?? "Element \(targetElement!.index + 1)" : "Unknown Element"
                subtitle.text = node?.name ?? "Unknown device"
                icon.image = #imageLiteral(resourceName: "ic_flag_24pt")
                tintColor = .nordicLake
                
            case let address where address.isGroup || address.isVirtual:
                if let group = meshNetwork.group(withAddress: address) ?? Group.specialGroup(withAddress: address) {
                    title.text = group.name
                    subtitle.text = group.address.virtualLabel?.uuidString
                } else {
                    title.text = "Unknown Group"
                    subtitle.text = address.asString()
                }                
                icon.image = #imageLiteral(resourceName: "ic_group_24pt")
                tintColor = .nordicLake
                
            default:
                title.text = "Invalid address"
                icon.image = #imageLiteral(resourceName: "ic_flag_24pt")
                tintColor = .nordicRed
            }
            detail.text = address.asString()
        }
    }
    
}
