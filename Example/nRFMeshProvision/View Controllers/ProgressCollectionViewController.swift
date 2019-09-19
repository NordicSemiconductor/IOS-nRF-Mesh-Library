//
//  ProgressCollectionViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 27/08/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class ProgressCollectionViewController: UICollectionViewController {
    
    // MARK: - Properties
    
    private var alert: UIAlertController?
    
    // MARK: - Implementation
    
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
                }))
                self.present(self.alert!, animated: true)
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
