//
//  MeshNetworkError.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 11/09/2019.
//

import Foundation

public enum MeshNetworkError: Error {
    /// Thrown when trying to send a mesh message before setting up the mesh network.
    case noNetwork
}

extension MeshNetworkError: LocalizedError {
    
    public var errorDescription: String? {
        switch self {
        case .noNetwork: return NSLocalizedString("Mesh Network not created.", comment: "")
        }
    }
    
}
