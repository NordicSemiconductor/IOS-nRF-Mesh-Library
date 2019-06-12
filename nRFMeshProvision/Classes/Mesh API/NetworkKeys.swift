//
//  NetworkKeys.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 07/06/2019.
//

import Foundation

public extension Array where Element == NetworkKey {
    
    subscript(networkId: Data) -> NetworkKey? {
        return first {
            $0.networkId == networkId
        }
    }
    
    subscript(keyIndex: KeyIndex) -> NetworkKey? {
        return first {
            $0.index == keyIndex
        }
    }
    
}
