//
//  ApplicationKey+NetworkKey.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 08/05/2019.
//

import Foundation

public extension ApplicationKey {
    
    /// Bounds the Application Key to the given Network Key.
    ///
    /// - parameter networkKey: The Network Key to bound the Application Key to.
    func bind(to networkKey: NetworkKey) {
        self.boundNetKey = networkKey.index
    }
    
    /// Returns whether the Application Key is bound to the given
    /// Network Key. The Key comparison bases on Key Index property.
    ///
    /// - parameter networkKey: The Network Key to check.
    func isBound(to networkKey: NetworkKey) -> Bool {
        return self.boundNetKey == networkKey.index
    }
    
}

// MARK: - Array methods

public extension Array where Element == ApplicationKey {
    
    /// Returns whether any of the Application Keys in the array is bound to
    /// the given Network Key. The Key comparison bases on Key Index property.
    ///
    /// - parameter networkKey: The Network Key to check.
    func contains(keyBoundTo networkKey: NetworkKey) -> Bool {
        return contains(where: { $0.isBound(to: networkKey) })
    }
    
}

