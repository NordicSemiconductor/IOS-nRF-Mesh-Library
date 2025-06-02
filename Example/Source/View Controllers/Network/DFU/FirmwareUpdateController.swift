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

class FirmwareUpdateController: UIViewController {
    private let key = "FirmwareUpdateControllerShown"
    
    // MARK: - Outlets
    
    @IBAction func cancelDidTap(_ sender: UIBarButtonItem) {
        navigationController?.dismiss(animated: true)
    }
    @IBAction func showInfo(_ sender: UIButton) {
        switch sender.tag {
        case 1:
            presentAlert(title: "DFU over SMP",
                         message: "DFU over Simple Management Protocol (SMP) service uses active GATT connection to quickly transfer the firmware image to the connected Firmware Distributor node. The image is then slowly distributed to target nodes using BLOB messages, but user presence is no longer required.")
        case 2:
            presentAlert(title: "DFU over BLOB",
                         message: "In this mode the firmware image is transferred to the Distributor node using BLOB Transfer models.\n\nThis method is not supported due to bandwidth limitations.")
        case 3:
            presentAlert(title: "DFU over HTTPS",
                         message: "This Out of Band (OOB) method assumes, that the Distributor can retrieve the firmware image from the Internet based on the HTTPS URIs provided by target nodes.\n\nThis method is not supported.")
        default:
            break
        }
        
    }
    
    @IBOutlet weak var content: UIView!
    
    @IBOutlet weak var dfuOverSmpButton: UIButton!
    @IBOutlet weak var dfuOverBlobButton: UIButton!
    @IBOutlet weak var dfuOverHttpsButton: UIButton!
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // By using 'content' view we can position the Empty View
        // more in the middle of the screen.
        // The 'view' property includes the Navigation Bar.
        content.setEmptyView(
            title: "Device Firmware Update",
            message: "Update the firmware on your nodes over the air.",
            messageImage: #imageLiteral(resourceName: "update_dfu")
        )
        content.showEmptyView()
        
        dfuOverSmpButton.makeBlue(enabled: true)
        dfuOverBlobButton.makeBlue(enabled: false)
        dfuOverHttpsButton.makeBlue(enabled: false)
        
        // To avoid showing the controller every time the app is launched,
        // we store a flag in UserDefaults.
        let controllerAlreadyShown = UserDefaults.standard.bool(forKey: key)
        if controllerAlreadyShown {
            performSegue(withIdentifier: "smp", sender: nil)
        } else {
            UserDefaults.standard.set(true, forKey: key)
        }
    }
    
}
