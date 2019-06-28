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
    
    var alert: UIAlertController?
    
    // MARK: - Implementation
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        MeshNetworkManager.bearer.delegate = self
    }
    
    func connect() {
        alert = UIAlertController(title: "Status", message: "Connecting...", preferredStyle: .alert)
        alert!.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert!, animated: true) {
            if MeshNetworkManager.bearer.isConnected {
                self.bearerDidOpen(MeshNetworkManager.bearer)
            }
        }
    }
    
    func networkReady(alert: UIAlertController) {
        alert.dismiss(animated: true)
    }
    
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
            if let alert = self.alert {
                self.networkReady(alert: alert)
            }
        }
    }
    
    func bearer(_ bearer: Bearer, didClose error: Error?) {
        DispatchQueue.main.async {
            self.alert?.dismiss(animated: true)
        }
    }
    
}
