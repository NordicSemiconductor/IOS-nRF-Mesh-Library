//
//  ProgressViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 28/06/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class ProgressViewController: UITableViewController {
    
    // MARK: - Properties
    
    private var alert: UIAlertController?
    
    // MARK: - Implementation
    
    /// Displays the progress alert with specified status message
    /// and calls the completion callback.
    ///
    /// - parameter completion: A completion handler.
    func start(_ message: String, completion: @escaping (() -> Void)) {
        if alert == nil {
            alert = UIAlertController(title: "Status", message: message, preferredStyle: .alert)
            alert!.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {
                _ in self.alert = nil
                self.refreshControl?.endRefreshing()
            }))
            present(alert!, animated: true)
        }
        
        completion()
    }
    
    /// This method dismisses the progress alert dialog.
    ///
    /// - parameter completion: An optional completion handler.
    func done(completion: (() -> Void)? = nil) {
        if let alert = alert {
            alert.dismiss(animated: true, completion: completion)
        } else {
            completion?()
        }
        alert = nil
    }
    
}
