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

class NodeViewCell: UITableViewCell {
    
    @IBOutlet weak var nodeName: UILabel!
    @IBOutlet weak var icon: UIImageView!
    
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var company: UILabel!
    @IBOutlet weak var elements: UILabel!
    @IBOutlet weak var models: UILabel!
    
    var node: Node! {
        didSet {
            nodeName.text = node.name ?? "Unknown Device"
            address.text = node.primaryUnicastAddress.asString()
            elements.text = "\(node.elements.count)"
            
            if let companyIdentifier = node.companyIdentifier {
                company.text = CompanyIdentifier.name(for: companyIdentifier) ?? "Unknown"
                let modelCount = node.elements.reduce(0, { (result, element) -> Int in
                    result + element.models.count
                })
                models.text = "\(modelCount)"
            } else {
                company.text = "Unknown"
                models.text = "Configuration not complete"
            }
        }
    }
    
    

}
