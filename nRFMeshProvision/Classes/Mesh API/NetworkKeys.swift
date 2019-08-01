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
    
    /// Returns a new list of Network Keys containing all the Network Keys
    /// of this list known to the given Node.
    ///
    /// - parameter node: The Node used to filter Network Keys.
    /// - returns: A new list containing all the Network Keys of this list
    ///            known to the given node.
    func knownTo(node: Node) -> [NetworkKey] {
        return filter { node.knows(networkKey: $0) }
    }
    
    /// Returns a new list of Network Keys containing all the Network Keys
    /// of this list NOT known to the given Node.
    ///
    /// - parameter node: The Node used to filter Network Keys.
    /// - returns: A new list containing all the Network Keys of this list
    ///            NOT known to the given node.
    func notKnownTo(node: Node) -> [NetworkKey] {
        return filter { !node.knows(networkKey: $0) }
    }
    
}
