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
import NordicMesh

class ProgressViewController: UITableViewController {
    
    // MARK: - Properties
    
    private var alert: UIAlertController?
    private var messageHandle: MessageHandle?
    
    // MARK: - Implementation
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        
        if #available(iOS 13.0, *) {
            if let presentationController = self.parent?.presentationController,
               let delegate = presentationController.delegate {
                delegate.presentationControllerDidDismiss?(presentationController)
            }
        }
    }
    
    /// Displays the progress alert with specified status message
    /// and calls the completion callback.
    ///
    /// - parameter message: Message to be displayed to the user.
    /// - parameter completion: A completion handler.
    func start(_ message: String, completion: @escaping () -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let alert = self.alert {
                alert.message = message
            } else {
                self.alert = UIAlertController(title: "Status", message: message, preferredStyle: .alert)
                self.alert!.addAction(UIAlertAction(title: "Cancel", style: .cancel) {
                    [weak self] _ in self?.alert = nil
                })
                self.present(self.alert!, animated: true)
            }
            
            completion()
        }
    }
    
    /// Displays the progress alert with specified status message
    /// and calls the completion callback.
    ///
    /// - parameter message: Message to be displayed to the user.
    /// - parameter completion: A completion handler.
    func start(_ message: String, completion: @escaping () throws -> MessageHandle?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            do {
                self.messageHandle = try completion()
                guard let _ = self.messageHandle else {
                    self.done()
                    return
                }

                if let alert = self.alert {
                    alert.message = message
                } else {
                    self.alert = UIAlertController(title: "Status",
                                                   message: message,
                                                   preferredStyle: .alert)
                    self.alert!.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
                        self?.messageHandle?.cancel()
                        self?.alert = nil
                        self?.refreshControl?.endRefreshing()
                    })
                    self.present(self.alert!, animated: true)
                }
            } catch {
                self.messageHandle = nil
                let completion: () -> Void = {
                    // Refresh Control does not collapse with animation when
                    // an Alert Control is shown immediately afterwards.
                    self.refreshControl?.endRefreshing()
                    
                    // A dirty hack to finish refreshing with animation.
                    // See: https://stackoverflow.com/a/50278729/2115352
                    self.tableView.setContentOffset(CGPoint.zero, animated: true)
                    
                    self.alert = UIAlertController(title: "Error",
                                                   message: error.localizedDescription,
                                                   preferredStyle: .alert)
                    self.alert!.addAction(UIAlertAction(title: "OK", style: .cancel) { [weak self] _ in
                        self?.alert = nil
                    })
                    self.present(self.alert!, animated: true)
                }
                if let alert = self.alert {
                    alert.dismiss(animated: true, completion: completion)
                } else {
                    completion()
                }
            }
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
