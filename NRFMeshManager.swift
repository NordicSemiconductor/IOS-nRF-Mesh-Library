//
//  NRFMeshManager.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 09/05/2018.
//

import Foundation
import CoreBluetooth

public struct NRFMeshManager {
    private var targetProxyNode: ProvisionedMeshNode?
    private var targetCentralManager: CBCentralManager
    private var targetStateManager: MeshStateManager

    public init?() {
        targetCentralManager = CBCentralManager()
        if MeshStateManager.stateExists() {
            if let restoredState = MeshStateManager.restoreState() {
                targetStateManager = restoredState
            } else {
                print("State manager couldn't be restored")
                return nil
            }
        } else {
            if let newStateManager = MeshStateManager.generateState() {
                targetStateManager = newStateManager
            } else {
                print("Failure to create state manager for Mesh Manager Object")
                return nil
            }
        }
    }
    
    public mutating func updateProxyNode(_ aNode: ProvisionedMeshNode) {
        targetProxyNode = aNode
    }
    
    public func proxyNode() -> ProvisionedMeshNode? {
        return targetProxyNode
    }
    
    public func centralManager() -> CBCentralManager {
        return targetCentralManager
    }
    
    public func stateManager() -> MeshStateManager {
        return targetStateManager
    }
}
