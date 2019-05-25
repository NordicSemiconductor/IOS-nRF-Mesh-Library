//
//  MeshMessage.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 25/05/2019.
//

import Foundation

public protocol MeshMessage {
    /// Returns the Mesh Message as Data.
    var data: Data { get }
}
