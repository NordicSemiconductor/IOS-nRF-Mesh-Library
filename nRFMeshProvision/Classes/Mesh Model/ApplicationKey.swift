//
//  ApplicationKey.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 21/03/2019.
//

import Foundation

public class ApplicationKey: Codable {
    /// UTF-8 string, which should be a human readable name for the application
    /// functionality associated with this application key, e.g. "Home Automation".
    public var name: String
    /// Index of this Application Key, in range from 0 through to 4095.
    public internal(set) var index: KeyIndex
    /// Corresponding Network Key index from the Network Keys array.
    public internal(set) var boundNetKey: KeyIndex
    /// 128-bit application key.
    public internal(set) var key: Data
    /// Previous 128-bit application key, if Key Update procedure is in progress.
    public internal(set) var oldKey: Data?
    
    internal init(name: String, index: KeyIndex, key: Data) {
        self.name        = name
        self.index       = index
        self.key         = key
        self.boundNetKey = 0
    }
    
}

// MARK: - Public API

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

// MARK: - Operators

extension ApplicationKey: Equatable {
    
    public static func == (lhs: ApplicationKey, rhs: ApplicationKey) -> Bool {
        return lhs.index == rhs.index && lhs.key == rhs.key
    }
    
    public static func != (lhs: ApplicationKey, rhs: ApplicationKey) -> Bool {
        return lhs.index != rhs.index || lhs.key != rhs.key
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
