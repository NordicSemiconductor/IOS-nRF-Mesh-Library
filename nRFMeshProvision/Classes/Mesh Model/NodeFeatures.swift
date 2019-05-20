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
    /// The state of Low Power feature. `nil` if unknown.
    public internal(set) var lowPower: State?
    /// The state of Friend feature. `nil` if unknown.
    public internal(set) var friend: State?
    
    internal init(relay: State?, proxy: State?, lowPower: State?, friend: State?) {
        self.relay = relay
        self.proxy = proxy
        self.lowPower = lowPower
        self.friend = friend
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
