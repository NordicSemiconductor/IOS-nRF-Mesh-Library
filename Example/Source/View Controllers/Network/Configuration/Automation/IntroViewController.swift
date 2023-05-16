/*
* Copyright (c) 2023, Nordic Semiconductor
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

class IntroViewController: UIViewController {
    
    // MARK: - Public properties
    
    var node: Node!
    
    // MARK: - Outlets
    
    @IBOutlet weak var content: UIView!
    @IBOutlet weak var customAppKeyBindings: UIButton!
    @IBOutlet weak var customSubscriptions: UIButton!
    @IBOutlet weak var customPublication: UIButton!
    
    @IBAction func cancelDidTap(_ sender: UIBarButtonItem) {
        navigationController?.dismiss(animated: true)
    }
    
    @IBAction func showInfo(_ sender: UIButton) {
        showInfo(for: sender)
    }
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // By using 'content' view we can position the Empty View
        // more in the middle of the screen.
        // The 'view' property includes the Navigation Bar.
        content.setEmptyView(
            title: "Quick Configuration",
            message: "Configure the node with just few clicks.",
            messageImage: #imageLiteral(resourceName: "auto_fix")
        )
        content.showEmptyView()
        
        makeBlue(customAppKeyBindings)
        makeBlue(customSubscriptions)
        makeBlue(customPublication)
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "bind" {
            let destination = segue.destination as! SelectKeysViewController
            destination.node = node
        }
        if segue.identifier == "subscribe" {
            let destination = segue.destination as! SelectGroupsViewController
            destination.node = node
        }
        if segue.identifier == "publish" {
            let destination = segue.destination as! SelectPublicationViewController
            destination.node = node
        }
    }

}

private extension IntroViewController {
    
    func makeBlue(_ button: UIButton) {
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.almostWhite, for: .highlighted)
        button.backgroundColor = .dynamicColor(light: .nordicLake, dark: .nordicBlue)
        button.layer.cornerRadius = 4
        button.layer.masksToBounds = true
    }
    
    func showInfo(for button: UIButton) {
        switch button.tag {
        case 1:
            presentAlert(
                title: "Bind Application Keys",
                message: "Bind Application Keys to selected Models. The keys (and bound Network Keys) will be sent automatically.")
        case 2:
            presentAlert(
                title: "Subscribe",
                message: "Subscribe Models to selected Groups.")
        case 3:
            presentAlert(
                title: "Set Publication",
                message: "Set Publication to selected Models. The keys (and bound Network Keys) will be sent automatically.")
        default:
            fatalError()
        }
    }
    
}
