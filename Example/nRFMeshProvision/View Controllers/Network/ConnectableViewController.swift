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
    func whenConnected(completion: ((UIAlertController?) -> Void)? = nil) {
        callback = completion
        
        alert = UIAlertController(title: "Status", message: "Connecting...", preferredStyle: .alert)
        alert!.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert!, animated: true) {
            if MeshNetworkManager.bearer.isConnected {
                if let completion = completion {
                    self.callback = nil
                    completion(self.alert)
                } else {
                    self.alert?.dismiss(animated: true)
                }
                self.callback = nil
            }
        }
    }
    
    func done() {
        alert?.dismiss(animated: true)
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
        }
    }
    
}
