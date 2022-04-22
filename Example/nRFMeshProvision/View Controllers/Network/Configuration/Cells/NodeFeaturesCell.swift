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

class NodeFeaturesCell: UITableViewCell {
    @IBOutlet weak var relayLabel: UILabel!
    @IBOutlet weak var friendLabel: UILabel!
    @IBOutlet weak var proxyLabel: UILabel!
    @IBOutlet weak var lowPowerLabel: UILabel!
    
    var node: Node! {
        didSet {
            // The Page 0 of the Composition Data contains only "supported" / "not supported" info for Node features.
            // The accurate "enabled" / "not enabled" information is obtained by sending a Config ... Get messages
            // for given feature, which may also return "not supported".
            // nRF Mesh app sends those messages from the Configuration Server Model screen, together with
            // Config Network Transmit Get. That means, that if Network Transmit object is not nil, that means that
            // the features status was requested.
            if let _ = node.networkTransmit {
                relayLabel.text = node.features?.relay?.debugDescription ?? "Unknown"
                proxyLabel.text = node.features?.proxy?.debugDescription ?? "Unknown"
                friendLabel.text = node.features?.friend?.debugDescription ?? "Unknown"
                lowPowerLabel.text = node.features?.lowPower?.debugDescription ?? "Unknown"
            } else {
                // Otherwise, the "not enabled" does not mean that the feature is actually disabled, but that
                // its "enabled" / "not enabled" state is unknown. The only certain state is "not supported".
                relayLabel.text = node.features?.relay == .notSupported ? node.features?.relay?.debugDescription : "Unknown"
                proxyLabel.text = node.features?.proxy == .notSupported ? node.features?.proxy?.debugDescription : "Unknown"
                friendLabel.text = node.features?.friend == .notSupported ? node.features?.friend?.debugDescription : "Unknown"
                lowPowerLabel.text = node.features?.lowPower == .notSupported ? node.features?.lowPower?.debugDescription : "Unknown"
            }
        }
    }
    
}
