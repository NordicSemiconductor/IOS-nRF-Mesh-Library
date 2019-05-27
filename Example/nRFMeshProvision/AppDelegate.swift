//
//  AppDelegate.swift
//  nRFMeshProvision
//
//  Created by mostafaberg on 12/18/2017.
//  Copyright (c) 2017 mostafaberg. All rights reserved.
//

import UIKit
import nRFMeshProvision

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var meshNetworkManager: MeshNetworkManager!
    var connection: NetworkConnection!
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Create the main MeshNetworkManager instance.
        meshNetworkManager = MeshNetworkManager()
        
        // Try loading the saved configuration.
        var loaded = false
        do {
            loaded = try meshNetworkManager.load()
        } catch {
            print(error)
            // ignore
        }
        
        // If load failed, create a new MeshNetwork.
        if !loaded {
            createNewMeshNetwork()
        } else {
            let meshNetwork = meshNetworkManager.meshNetwork!
            connection = NetworkConnection(to: meshNetwork)
            connection!.dataDelegate = meshNetworkManager
            connection!.open()
        }
        
        return true
    }
    
    func createNewMeshNetwork() {
        // TODO: Implement creator
        connection?.close()
        
        _ = meshNetworkManager.createNewMeshNetwork(withName: "nRF Mesh Network", by: UIDevice.current.name)
        _ = meshNetworkManager.save()
        
        let meshNetwork = meshNetworkManager.meshNetwork!
        connection = NetworkConnection(to: meshNetwork)
        connection!.dataDelegate = meshNetworkManager
        connection!.open()
    }
}

extension MeshNetworkManager {
    
    static var instance: MeshNetworkManager {
        return (UIApplication.shared.delegate as! AppDelegate).meshNetworkManager
    }
    
    static var bearer: Bearer! {
        return (UIApplication.shared.delegate as! AppDelegate).connection
    }
}
