//
//  ApplicationKeys.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 10/06/2019.
//

import Foundation

public extension Array where Element == ApplicationKey {
    
    subscript(keyIndex: KeyIndex) -> ApplicationKey? {
        return first {
            $0.index == keyIndex
        }
    }
    
    /// Returns a new list of Application Keys containing all the Application Keys
    /// of this list known to the given Node.
    ///
    /// - parameter node: The Node used to filter Application Keys.
    /// - returns: A new list containing all the Application Keys of this list
    ///            known to the given node.
    func knownTo(node: Node) -> [ApplicationKey] {
        return filter { node.knows(applicationKey: $0) }
    }
    
    /// Returns a new list of Application Keys containing all the Application Keys
    /// of this list NOT known to the given Node.
    ///
    /// - parameter node: The Node used to filter Application Keys.
    /// - returns: A new list containing all the Application Keys of this list
    ///            NOT known to the given node.
    func notKnownTo(node: Node) -> [ApplicationKey] {
        return filter { !node.knows(applicationKey: $0) }
    }
    
}
