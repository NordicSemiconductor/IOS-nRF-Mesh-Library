//
//  NodeFeatures.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 25/03/2019.
//

import Foundation

/// The features object represents the functionality of a mesh node
/// that is determined by the set features that the node supports.
public class NodeFeatures: Codable {
    
    /// The state of a feature.
    public enum State: UInt8, Codable {
        case notEnabled   = 0
        case enabled      = 1
        case notSupported = 2
    }
    /// The state of Relay feature. `nil` if unknown.
    public internal(set) var relay: State?
    /// The state of Proxy feature. `nil` if unknown.
    public internal(set) var proxy: State?
    /// The state of Friend feature. `nil` if unknown.
    public internal(set) var friend: State?
    /// The state of Low Power feature. `nil` if unknown.
    public internal(set) var lowPower: State?
    
    internal init(relay: State?, proxy: State?, friend: State?, lowPower: State?) {
        self.relay    = relay
        self.proxy    = proxy
        self.friend   = friend
        self.lowPower = lowPower
    }
    
    internal init() {
        self.relay    = .notSupported
        self.proxy    = .notSupported
        self.friend   = .notSupported
        self.lowPower = .notSupported
    }
    
    internal init(rawValue: UInt16) {
        self.relay    = rawValue & 0x01 == 0 ? .notSupported : .notEnabled
        self.proxy    = rawValue & 0x02 == 0 ? .notSupported : .notEnabled
        self.friend   = rawValue & 0x04 == 0 ? .notSupported : .notEnabled
        self.lowPower = rawValue & 0x08 == 0 ? .notSupported : .notEnabled
    }
}

extension NodeFeatures.State: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .notEnabled:   return "Not enabled"
        case .enabled:      return "Enabled"
        case .notSupported: return "Not supported"
        }
    }
    
}

extension NodeFeatures: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return """
        Relay Feature:     \(relay?.debugDescription ?? "Unknown")
        Proxy Feature:     \(proxy?.debugDescription ?? "Unknown")
        Low Power Feature: \(lowPower?.debugDescription ?? "Unknown")
        Friend Feature:    \(friend?.debugDescription ?? "Unknown")
        """
    }
    
}
