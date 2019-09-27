//
//  MeshData.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 21/03/2019.
//

import Foundation

/// The Mesh Network configuration saved internally.
/// It contains the Mesh Network and additional data that
/// are not in the JSON schema, but are used by in the app.
public class MeshData: Codable {
    /// Mesh Network state.
    public internal(set) var meshNetwork: MeshNetwork?
}
