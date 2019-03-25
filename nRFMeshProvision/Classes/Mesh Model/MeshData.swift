//
//  MeshData.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 21/03/2019.
//

import Foundation

/// The Mesh Network configuration saved by internally.
/// It contains the Mesh Network and additional data that
/// are not in the JSON schema, but are used for provisioning.
public class MeshData: Codable {
    /// Mesh Network state.
    public internal(set) var meshNetwork: MeshNetwork?
    /// Global Time To Leave value. This value is used for all mesh messages.
    public var globalTTL: UInt8  = 5
}
