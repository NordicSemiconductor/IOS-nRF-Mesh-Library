//
//  UIViewController+Alert.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 20/03/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

extension UIViewController {
    
    /// Displays an alert dialog with given title and message.
    /// The alert dialog will contain an OK button.
    ///
    /// - parameters:
    ///   - title: The alert title.
    ///   - message: The message below the title.
    ///   - handler: The OK button handler.
    public func presentAlert(title: String?, message: String?, handler: ((UIAlertAction) -> Void)? = nil) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: handler))
            self.present(alert, animated: true)
        }
    }
}
