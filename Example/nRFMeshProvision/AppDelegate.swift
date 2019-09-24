//
//  AppDelegate.swift
//  nRFMeshProvision
//
//  Created by mostafaberg on 12/18/2017.
//  Copyright (c) 2017 mostafaberg. All rights reserved.
//

import UIKit
import os.log
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
        meshNetworkManager.acknowledgmentTimerInterval = 0.600
        meshNetworkManager.transmissionTimerInteral = 0.600
        meshNetworkManager.logger = self
        
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
            meshNetworkDidChange()
        }
        
        return true
    }
    
    func createNewMeshNetwork() {
        // TODO: Implement creator
        let provisioner = Provisioner(name: UIDevice.current.name,
                                      allocatedUnicastRange: [AddressRange(0x0001...0x199A)],
                                      allocatedGroupRange:   [AddressRange(0xC000...0xCC9A)],
                                      allocatedSceneRange:   [SceneRange(0x0001...0x3333)])
        _ = meshNetworkManager.createNewMeshNetwork(withName: "nRF Mesh Network", by: provisioner)
        _ = meshNetworkManager.save()
        
        meshNetworkDidChange()
    }
    
    func meshNetworkDidChange() {
        connection?.close()
        
        let meshNetwork = meshNetworkManager.meshNetwork!
        /*
        let genericOnOffServer_0 = Model(sigModelId: 0x1000)
        let genericOnOffClient_0 = Model(sigModelId: 0x1001)
        let element_0 = Element(location: .first, models: [genericOnOffServer_0, genericOnOffClient_0])
        let genericOnOffServer_1 = Model(sigModelId: 0x1000)
        let genericOnOffClient_1 = Model(sigModelId: 0x1001)
        let element_1 = Element(location: .first, models: [genericOnOffServer_1, genericOnOffClient_1])
        meshNetworkManager.localElements = [element_0, element_1]
        */
        connection = NetworkConnection(to: meshNetwork)
        connection!.dataDelegate = meshNetworkManager
        connection!.logger = self
        meshNetworkManager.transmitter = connection
        connection!.open()
    }
}

extension MeshNetworkManager {
    
    static var instance: MeshNetworkManager {
        return (UIApplication.shared.delegate as! AppDelegate).meshNetworkManager
    }
    
    static var bearer: NetworkConnection! {
        return (UIApplication.shared.delegate as! AppDelegate).connection
    }
    
}

// MARK: - Logger

extension AppDelegate: LoggerDelegate {
    
    func log(message: String, ofCategory category: LogCategory, withLevel level: LogLevel) {
        if #available(iOS 10.0, *) {
            os_log("%{public}@", log: category.log, type: level.type, message)
        } else {
            NSLog("%@", message)
        }
    }
    
}

extension LogLevel {
    
    /// Mapping from mesh log levels to system log types.
    var type: OSLogType {
        switch self {
        case .debug:       return .debug
        case .verbose:     return .debug
        case .info:        return .info
        case .application: return .default
        case .warning:     return .error
        case .error:       return .fault
        }
    }
    
}

extension LogCategory {
    
    var log: OSLog {
        return OSLog(subsystem: Bundle.main.bundleIdentifier!, category: rawValue)
    }
    
}
