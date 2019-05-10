//
//  PublicKey.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 07/05/2019.
//

import Foundation

public enum PublicKey {
    /// No OOB Public Key is used.
    case noOobPublicKey
    /// OOB Public Key is used.
    case oobPublicKey(key: Data)
    
    var value: UInt8 {
        switch self {
        case .noOobPublicKey:       return 0
        case .oobPublicKey(key: _): return 1
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
