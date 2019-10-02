//
//  ProgressCollectionViewCell.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 02/10/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class ProgressCollectionViewCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    private var alert: UIAlertController?
    private var messageHandle: MessageHandle?
    
    // MARK: - Implementation
    
    /// Displays the progress alert with specified status message
    /// and calls the completion callback.
    ///
    /// - parameter message: Message to be displayed to the user.
    /// - parameter completion: A completion handler.
    func start(_ message: String, completion: @escaping (() throws -> MessageHandle?)) {
        DispatchQueue.main.async {
            do {
                self.messageHandle = try completion()
                guard let _ = self.messageHandle else { return }

                if self.alert == nil {
                    self.alert = UIAlertController(title: "Status", message: message, preferredStyle: .alert)
                    self.alert!.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                        self.messageHandle?.cancel()
                        self.alert = nil
                    }))
                    self.parentViewController?.present(self.alert!, animated: true)
                } else {
                    self.alert?.message = message
                }
            } catch {
                let completition: () -> Void = {
                    self.alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    self.alert!.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
                        self.alert = nil
                    }))
                }
                if self.alert != nil {
                    self.alert?.dismiss(animated: true, completion: completition)
                } else {
                    completition()
                }
            }
        }
    }
    
    /// This method dismisses the progress alert dialog.
    ///
    /// - parameter message: Message to be displayed to the user.
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
