//
//  PublicKey.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 07/05/2019.
//

import Foundation

/// The type of Device Public key to be used.
public enum PublicKey {
    /// No OOB Public Key is used.
    case noOobPublicKey
    /// OOB Public Key is used. The key must contain the full value of the Public Key,
    /// depending on the chosen algorithm.
    case oobPublicKey(key: Data)
    
    var value: Data {
        switch self {
        case .noOobPublicKey:       return Data([0])
        case .oobPublicKey(key: _): return Data([1])
        }
    }
}

extension PublicKey: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .noOobPublicKey:
            return "No OOB Public Key"
        case .oobPublicKey(key: _):
            return "OOB Public Key"
        }
    }
    
}


public struct PublicKeyType: OptionSet {
    public let rawValue: UInt8
    
    /// Public Key OOB Information is available.
    public static let publicKeyOobInformationAvailable = PublicKeyType(rawValue: 1 << 0)
    
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    
}

extension PublicKeyType: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        if rawValue == 0 {
            return "None"
        }
        return [(.publicKeyOobInformationAvailable, "Public Key OOB Information Available")]
            .compactMap { (option, name) in contains(option) ? name : nil }
            .joined(separator: ", ")
    }
    
}
