//
//  Data+Keys.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 26/04/2019.
//

import Foundation

public extension Data {
    
    /// Returns a random 128-bit long key.
    static func random128BitKey() -> Data {
        return OpenSSLHelper().generateRandom()
    }
    
}
