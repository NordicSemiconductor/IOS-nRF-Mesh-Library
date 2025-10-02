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

class RootViewController: UINavigationController {
    
    // Make sure the status bar is light in the app.
    // The default is set to black, as this one is used in the Launch Screen.
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 26.0, *) {
            return .darkContent
        } else {
            return .lightContent
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let navBarAppearance = UINavigationBarAppearance()
        if #available(iOS 26.0, *) {
            navigationBar.barStyle = .default
            // In case of bar style .black, the barTintColor defines the color of the top part
            // of the screen (status bar area) when nav bar is collapsed.
            // For .default, it has no effect.
            // navigationBar.barTintColor = .nordicBlue
            
            // The NavigationBar background color just applies to the NavBar, not the status bar area.
            // navigationBar.backgroundColor = .nordicBlue
            
            navigationBar.isTranslucent = true
            navigationBar.prefersLargeTitles = true
            
            navBarAppearance.configureWithTransparentBackground()
            navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.dynamicColor(light: .nordicBlue, dark: .white)]
            navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.dynamicColor(light: .nordicBlue, dark: .white)]
        } else {
            navigationBar.barStyle = .default
            navigationBar.isTranslucent = false
            navigationBar.prefersLargeTitles = true
            // This changes the color of nav bar buttons.
            navigationBar.tintColor = .white
            
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.backgroundColor = UIColor.dynamicColor(light: .nordicBlue, dark: .black)
            navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        }
        
        navigationBar.standardAppearance = navBarAppearance
        navigationBar.scrollEdgeAppearance = navBarAppearance
    }

}
