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
        return knows(applicationKeyIndex: applicationKey.index)
    }
    
    /// Returns whether the Node has knowledge about Application Key with the
    /// given index.
    ///
    /// - parameter applicationKeyIndex: The Application Key Index to look for.
    /// - returns: `True` if the Node has knowledge about the Applicaiton Key
    ///            index, `false` otherwise.
    func knows(applicationKeyIndex: KeyIndex) -> Bool {
        return appKeys.contains { $0.index == applicationKeyIndex }
    }
    
    /// Returns whether the Node has knowledge about the given Network Key.
    /// The Network Key comparison bases only on the Key Index.
    ///
    /// - parameter networkKey: The Network Key to look for.
    /// - returns: `True` if the Node has knowledge about the Network Key
    ///            with the same Key Index as given key, `false` otherwise.
    func knows(networkKey: NetworkKey) -> Bool {
        return knows(networkKeyIndex: networkKey.index)
    }
    
    /// Returns whether the Node has knowledge about Network Key with the
    /// given index.
    ///
    /// - parameter networkKeyIndex: The Network Key Index to look for.
    /// - returns: `True` if the Node has knowledge about the Network Key
    ///            index, `false` otherwise.
    func knows(networkKeyIndex: KeyIndex) -> Bool {
        return netKeys.contains { $0.index == networkKeyIndex }
    }
    
    /// Returns whether any of the Element's Models are bound to the
    /// guven Application Key.
    ///
    /// - parameter applicationKey: The Application Key to check bindings.
    /// - returns: `True` if there is at least one Model bound to the given
    ///            Application Key, `false` otherwise.
    func hasModelBoundTo(_ applicationKey: ApplicationKey) -> Bool {
        return elements.contains { $0.hasModelBoundTo(applicationKey) }
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
        return knows(applicationKeyIndex: applicationKey.index)
    }
    
    /// Returns whether any of elements of this array is using an
    /// Application Key with given Key Index.
    ///
    /// - parameter applicationKeyIndex: The Application Key Index to look for.
    /// - returns: `True` if any of the Nodes have knowledge about the
    ///            Applicaiton Key Index, `false` otherwise.
    func knows(applicationKeyIndex: KeyIndex) -> Bool {
        return contains(where: { $0.knows(applicationKeyIndex: applicationKeyIndex) })
    }
    
    /// Returns whether any of elements of this array is using the given
    /// Network Key.
    ///
    /// - parameter networkKey: The Network Key to look for.
    /// - returns: `True` if any of the Nodes have knowledge about the
    ///            Applicaiton Key with the same Key Index as given key,
    ///            `false` otherwise.
    func knows(networkKey: NetworkKey) -> Bool {
        return knows(networkKeyIndex: networkKey.index)
    }
    
    /// Returns whether any of elements of this array is using an
    /// Network Key with given Key Index.
    ///
    /// - parameter applicationKeyIndex: The Network Key Index to look for.
    /// - returns: `True` if any of the Nodes have knowledge about the
    ///            Network Key Index, `false` otherwise.
    func knows(networkKeyIndex: KeyIndex) -> Bool {
        return contains(where: { $0.knows(networkKeyIndex: networkKeyIndex) })
    }
    
}
