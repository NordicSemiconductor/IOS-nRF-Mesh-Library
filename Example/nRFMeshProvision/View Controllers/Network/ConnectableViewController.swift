//
//  ConnectableViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 28/06/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class ConnectableViewController: UITableViewController, GattBearerDelegate {
    
    // MARK: - Properties
    
    private var alert: UIAlertController?
    private var callback: ((UIAlertController?) -> Void)?
    
    // MARK: - Implementation
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        MeshNetworkManager.bearer.delegate = self
    }
    
    /// Waits until the mesh network connection is open and then calls the
    /// given completion handler. If the connection to the mesh network was
    /// already open, the handler is called immediately.
    ///
    /// - parameter completion: An optional completion handler.
    func whenConnected(completion: @escaping ((UIAlertController?) -> Void)) {
        if alert == nil {
            alert = UIAlertController(title: "Status", message: "Connecting...", preferredStyle: .alert)
            alert!.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in self.alert = nil }))
            present(alert!, animated: true)
        }
            
        if MeshNetworkManager.bearer.isConnected {
            // If we are already connected, don't wait with the request
            // until the alert is presented.
            completion(alert)
        } else {
            // Otherwise, the completion delegate will be called upon
            // connection.
            callback = completion
        }
    }
    
    /// This method dismisses the progress alert dialog.
    func done() {
        alert?.dismiss(animated: true)
        alert = nil
    }
    
    // MARK: - GattBearerDelegate
    
    func bearerDidConnect(_ bearer: Bearer) {
        DispatchQueue.main.async {
            self.alert?.message = "Discovering services..."
        }
    }
    
    func bearerDidDiscoverServices(_ bearer: Bearer) {
        DispatchQueue.main.async {
            self.alert?.message = "Initializing..."
        }
    }
    
    func bearerDidOpen(_ bearer: Bearer) {
        DispatchQueue.main.async {
            if let completion = self.callback {
                completion(self.alert)
            }
            self.callback = nil
        }
    }
    
    func bearer(_ bearer: Bearer, didClose error: Error?) {
        DispatchQueue.main.async {
            self.alert?.dismiss(animated: true)
            self.callback = nil
            self.alert = nil
        }
    }
    
}
