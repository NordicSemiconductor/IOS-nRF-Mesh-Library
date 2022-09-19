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

class HeartbeatSubscriptionCell: UITableViewCell {

    @IBOutlet weak var sourceLabel: UILabel!
    @IBOutlet weak var sourceIcon: NSLayoutConstraint!
    
    @IBOutlet weak var destinationLabel: UILabel!
    @IBOutlet weak var destinationIcon: UIImageView!
    @IBOutlet weak var destinationSubtitle: UILabel!
    
    var subscription: HeartbeatSubscription! {
        didSet {
            let network = MeshNetworkManager.instance.meshNetwork!
            sourceLabel.text = network.node(withAddress: subscription.source)?
                .name ?? "Unknown Device"
            switch subscription.destination {
            case let unicastAddress where unicastAddress.isUnicast:
                destinationLabel.text = network.node(withAddress: unicastAddress)?.name ?? "Unknown Device"
                destinationSubtitle.text = nil
                destinationIcon.image = #imageLiteral(resourceName: "ic_flag_24pt")
            case let groupAddress where groupAddress.isGroup || groupAddress.isVirtual:
                if let group = network.group(withAddress: groupAddress) ?? Group.specialGroup(withAddress: groupAddress) {
                    destinationLabel.text = group.name
                    destinationSubtitle.text = nil
                } else {
                    destinationLabel.text = "Unknown Group"
                    destinationSubtitle.text = groupAddress.asString()
                }
                destinationIcon.image = #imageLiteral(resourceName: "ic_group_24pt")
            default:
                destinationLabel.text = "Unknown Address"
                destinationSubtitle.text = subscription.destination.asString()
                destinationIcon.image = #imageLiteral(resourceName: "ic_flag_24pt")
            }
        }
    }
    
}
