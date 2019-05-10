//
//  Node+Keys.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 10/05/2019.
//

import Foundation

public extension Node {
    
    /// Returns whether the Node has knowledge about the given Application Key.
    /// The Application Key comparison bases only on the Key Index.
    ///
    /// - parameter applicationKey: The Application Key to look for.
    /// - returns: `True` if the Node has knowledge about the Applicaiton Key
    ///            with the same Key Index as given key, `false` otherwise.
    func knows(applicationKey: ApplicationKey) -> Bool {
        return appKeys.contains(where: { $0.index == applicationKey.index })
    }
    
    /// Returns whether the Node has knowledge about the given Network Key.
    /// The Network Key comparison bases only on the Key Index.
    ///
    /// - parameter networkKey: The Network Key to look for.
    /// - returns: `True` if the Node has knowledge about the Network Key
    ///            with the same Key Index as given key, `false` otherwise.
    func knows(networkKey: NetworkKey) -> Bool {
        return netKeys.contains(where: { $0.index == networkKey.index })
    }
    
}

public extension Array where Element == Node {
    
    /// Returns whether any of elements of this array is using the given
    /// Application Key.
    ///
    /// - parameter applicationKey: The Application Key to look for.
    /// - returns: `True` if any of the Nodes have knowledge about the
    ///            Applicaiton Key with the same Key Index as given key,
    ///            `false` otherwise.
    func knows(applicationKey: ApplicationKey) -> Bool {
        return contains(where: { $0.knows(applicationKey: applicationKey) })
    }
    
    /// Returns whether any of elements of this array is using the given
    /// Network Key.
    ///
    /// - parameter networkKey: The Network Key to look for.
    /// - returns: `True` if any of the Nodes have knowledge about the
    ///            Applicaiton Key with the same Key Index as given key,
    ///            `false` otherwise.
    func knows(networkKey: NetworkKey) -> Bool {
        return contains(where: { $0.knows(networkKey: networkKey) })
    }
    
}
