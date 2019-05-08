//
//  PublicKey.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 07/05/2019.
//

import Foundation

public enum PublicKey: UInt8 {
    /// No OOB Public Key is used.
    case noOobPublicKey = 0
    /// OOB Public Key is used.
    case oobPublicKey   = 1
}

public struct PublicKeyType: OptionSet {
    public let rawValue: UInt8
    
    /// Public Key OOB Information is available.
    static let publicKeyOobInformationAvailable = PublicKeyType(rawValue: 1 << 0)
    
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    
}

extension PublicKeyType: CustomStringConvertible {
    
    public var description: String {
        return [(.publicKeyOobInformationAvailable, "Public Key OOB Information Available")]
            .compactMap { (option, name) in contains(option) ? name : nil }
            .joined(separator: ", ")
    }
    
}
