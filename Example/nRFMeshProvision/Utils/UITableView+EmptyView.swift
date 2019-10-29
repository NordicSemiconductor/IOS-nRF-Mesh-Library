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

// Inspired from https://github.com/tahasonmez/handleEmptyTableView
extension UIView {
    
    /// Sets an empty view, initially hidden.
    func setEmptyView(title: String, message: String, messageImage: UIImage) {
        var emptyView: UIView! = subviews.first(where: { $0.tag == 100 })
        
        if emptyView == nil {
            emptyView = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 240))
            emptyView.tag = 100
            emptyView.alpha = 0
            
            let messageImageView = UIImageView()
            let titleLabel = UILabel()
            let messageLabel = UILabel()
            
            messageImageView.backgroundColor = .clear
            messageImageView.alpha = 0.6
            messageImageView.tag   = 99
            
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            messageImageView.translatesAutoresizingMaskIntoConstraints = false
            messageLabel.translatesAutoresizingMaskIntoConstraints = false
            
            
            titleLabel.textColor = UIColor.dynamicColor(light: .nordicLake, dark: .nordicBlue)
            titleLabel.font = UIFont.systemFont(ofSize: 15.0, weight: .semibold)
            
            if #available(iOS 13.0, *) {
                messageImageView.tintColor = UIColor.secondaryLabel
                messageLabel.textColor = UIColor.secondaryLabel
            } else {
                messageImageView.tintColor = UIColor.darkText
                messageLabel.textColor = UIColor.darkText
            }
            messageLabel.font = UIFont.systemFont(ofSize: 14.0, weight: .medium)
            
            emptyView.addSubview(titleLabel)
            emptyView.addSubview(messageImageView)
            emptyView.addSubview(messageLabel)
            
            NSLayoutConstraint.activate([
                messageImageView.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
                messageImageView.topAnchor.constraint(equalTo: emptyView.topAnchor, constant: 10),
                messageImageView.widthAnchor.constraint(equalToConstant: 100),
                messageImageView.heightAnchor.constraint(equalToConstant: 100),
                
                titleLabel.topAnchor.constraint(equalTo: messageImageView.bottomAnchor, constant: 10),
                titleLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
                
                messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
                messageLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor)
            ])
            
            messageImageView.image = messageImage
            titleLabel.text = title.uppercased()
            messageLabel.text = message
            messageLabel.numberOfLines = 0
            messageLabel.textAlignment = .center
            
            emptyView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(emptyView)
            
            NSLayoutConstraint.activate([
                emptyView.centerXAnchor.constraint(equalTo: centerXAnchor),
                NSLayoutConstraint(item: emptyView!, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 0.8, constant: 0),
                emptyView.leadingAnchor.constraint(equalTo: leadingAnchor),
                emptyView.trailingAnchor.constraint(equalTo: trailingAnchor),
                emptyView.heightAnchor.constraint(equalToConstant: 240)
            ])
        }
    }
    
    func showEmptyView() {
        if let emptyView = subviews.first(where: { $0.tag == 100 }) {
            UIView.animate(withDuration: 0.5, animations: {
                emptyView.alpha = 1.0
            }, completion: { _ in
                if let messageImageView = emptyView.subviews.first(where: { $0.tag == 99 }) {
                    UIView.animate(withDuration: 1.0, delay: 0.4, animations: {
                        messageImageView.transform = CGAffineTransform(rotationAngle: .pi / 10)
                    }, completion: { _ in
                        UIView.animate(withDuration: 1.0, animations: {
                            messageImageView.transform = CGAffineTransform(rotationAngle: -1 * (.pi / 10))
                        }, completion: { _ in
                            UIView.animate(withDuration: 1.0, animations: {
                                messageImageView.transform = CGAffineTransform.identity
                            })
                        })
                    })
                }
            })
        }
    }
    
    func hideEmptyView(_ animated: Bool = true) {
        if let emptyView = subviews.first(where: { $0.tag == 100 }) {
            if animated {
                UIView.animate(withDuration: 0.5) {
                    emptyView.alpha = 0.0
                }
            } else {
                emptyView.alpha = 0.0
            }
        }
    }
    
}

protocol Editable {
    var tableView: UITableView! { get set }
    
    /// Shows the 'Empty View'.
    func showEmptyView()
    /// Hides the 'Empty View'.
    func hideEmptyView(_ animated: Bool)
}

extension Editable where Self: UIViewController {
    
    func showEmptyView() {
        if navigationItem.rightBarButtonItems!.contains(editButtonItem) {
            navigationItem.rightBarButtonItems!.removeAll {
                $0 == self.editButtonItem
            }
        }
        tableView.showEmptyView()
        setEditing(false, animated: false)
        tableView.setEditing(false, animated: false)
    }
    
    func hideEmptyView(_ animated: Bool = true) {
        if !navigationItem.rightBarButtonItems!.contains(editButtonItem) {
            navigationItem.rightBarButtonItems!.append(editButtonItem)
        }
        tableView.hideEmptyView(animated)
    }
    
}
