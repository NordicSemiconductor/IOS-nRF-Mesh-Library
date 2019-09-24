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
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        
        if #available(iOS 13.0, *) {
            if let presentationController = self.parent?.presentationController {
                presentationController.delegate?.presentationControllerDidDismiss?(presentationController)
            }
        }
    }
    
    /// Displays the progress alert with specified status message
    /// and calls the completion callback.
    ///
    /// - parameter completion: A completion handler.
    func start(_ message: String, completion: @escaping (() -> Void)) {
        DispatchQueue.main.async {
            if self.alert == nil {
                self.alert = UIAlertController(title: "Status", message: message, preferredStyle: .alert)
                self.alert!.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {
                    _ in self.alert = nil
                    self.refreshControl?.endRefreshing()
                }))
                self.present(self.alert!, animated: true)
            } else {
                self.alert?.message = message
            }
        
            completion()
        }
    }
    
    /// This method dismisses the progress alert dialog.
    ///
    /// - parameter completion: An optional completion handler.
    func done(completion: (() -> Void)? = nil) {
        if let alert = alert {
            DispatchQueue.main.async {
                alert.dismiss(animated: true, completion: completion)
            }
        } else {
            DispatchQueue.main.async {
                completion?()
            }
        }
        alert = nil
    }
    
}
