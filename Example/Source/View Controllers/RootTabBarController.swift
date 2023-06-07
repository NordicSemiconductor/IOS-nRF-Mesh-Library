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

class RootTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // If the network has not been loaded (first run), open the New Network Wizard.
        let manager = MeshNetworkManager.instance
        if !manager.isNetworkCreated {
            presentNewNetworkWizard()
        }
    }
    
    func presentGroups() {
        selectedIndex = .groupsTabIndex
        if let rootViewController = selectedViewController as? RootViewController {
            rootViewController.popToRootViewController(animated: true)
        }
    }
    
    func presentNetworkKeysSettings() {
        selectedIndex = .settingsTabIndex
        if let rootViewController = selectedViewController as? RootViewController {
            guard let topViewController = rootViewController.topViewController else {
                return
            }
            // If we are in Network Keys View Controller already?
            if topViewController is NetworkKeysViewController {
                return
            }
            // If we are in Settings?
            if let settingsViewController = topViewController as? SettingsViewController {
                // If so, present Net Keys.
                settingsViewController.performSegue(withIdentifier: "networkKeys", sender: nil)
            } else {
                // Else, we need to navigate back to Settings and present Net Keys.
                topViewController.navigationController?.popViewController(animated: false)
                if let settingsViewController = topViewController as? SettingsViewController {
                    settingsViewController.performSegue(withIdentifier: "networkKeys", sender: nil)
                }
            }
        }
    }
    
    func presentApplicationKeysSettings() {
        selectedIndex = .settingsTabIndex
        if let rootViewController = selectedViewController as? RootViewController {
            guard let topViewController = rootViewController.topViewController else {
                return
            }
            // If we are in Application Keys View Controller already?
            if topViewController is AppKeysViewController {
                return
            }
            // If we are in Settings?
            if let settingsViewController = topViewController as? SettingsViewController {
                // If so, present App Keys.
                settingsViewController.performSegue(withIdentifier: "appKeys", sender: nil)
            } else {
                // Else, we need to navigate back to Settings and present App Keys.
                topViewController.navigationController?.popViewController(animated: false)
                if let settingsViewController = topViewController as? SettingsViewController {
                    settingsViewController.performSegue(withIdentifier: "appKeys", sender: nil)
                }
            }
        }
    }
    
    func presentScenesSettings() {
        selectedIndex = .settingsTabIndex
        if let rootViewController = selectedViewController as? RootViewController {
            guard let topViewController = rootViewController.topViewController else {
                return
            }
            // If we are in Scenes View Controller already?
            if topViewController is ScenesViewController {
                return
            }
            // If we are in Settings?
            if let settingsViewController = topViewController as? SettingsViewController {
                // If so, present Scenes.
                settingsViewController.performSegue(withIdentifier: "scenes", sender: nil)
            } else {
                // Else, we need to navigate back to Settings and present Scenes.
                topViewController.navigationController?.popViewController(animated: false)
                if let settingsViewController = topViewController as? SettingsViewController {
                    settingsViewController.performSegue(withIdentifier: "scenes", sender: nil)
                }
            }
        }
    }
    
    func presentNewNetworkWizard() {
        selectedIndex = .settingsTabIndex
        // The wizard will be opened from Settings View Controller.
    }

}

private extension Int {
    
    static let localNodeTabIndex = 0
    static let networkTabIndex   = 1
    static let groupsTabIndex    = 2
    static let proxyTabIndex     = 3
    static let settingsTabIndex  = 4
    
}
