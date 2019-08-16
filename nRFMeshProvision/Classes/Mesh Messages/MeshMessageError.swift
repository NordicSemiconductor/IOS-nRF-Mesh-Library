//
//  MeshMessageError.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 25/05/2019.
//

import Foundation

public enum MeshMessageError: Error {
    case invalidAddress
    case invalidPdu
    case invalidOpCode
}
