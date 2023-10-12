/*
* Copyright (c) 2019, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

import Foundation

/// A feature of a Node.
///
/// Bluetooth Mesh Protocol 1.1 defines 4 features:
/// - If the Relay feature is set, the Relay feature of a Node is in use.
/// - If the Proxy feature is set, the GATT Proxy feature of a Node is in use.
/// - If the Friend feature is set, the Friend feature of a Node is in use.
/// - If the Low Power feature is set, the Node has active relationship with a Friend
///   Node.
public enum NodeFeature: String, Codable {
    /// The Relay feature is used to relay/forward Network PDUs received by a node
    /// over the advertising bearer.
    ///
    /// This feature is optional and if supported can be enabled and disabled.
    case relay = "relay"
    /// The Proxy feature is used to relay/forward Network PDUs received by a node
    /// between GATT and advertising bearers.
    ///
    /// This feature is optional and if supported can be enabled and disabled.
    case proxy = "proxy"
    /// The Friend feature is used to establish friendship with a Low Power node.
    ///
    /// This feature is optional and if supported can be enabled and disabled.
    case friend = "friend"
    /// The Low Power feature specifies that the node can work as a Low Power device.
    ///
    /// This feature is optional but cannot be disabled if supported. A Low Power
    /// node can have friendship established or not, but this flag only says if
    /// the feature is enabled, not the status of the friendship.
    case lowPower = "lowPower"
}

/// A set of currently active features of a Node.
public struct NodeFeatures: OptionSet {
    public let rawValue: UInt16
    
    /// If present, the ``NodeFeatures/relay`` feature is enabled on the Node.
    public static let relay    = NodeFeatures(rawValue: 1 << 0)
    /// If present, the ``NodeFeatures/proxy`` feature is enabled on the Node.
    public static let proxy    = NodeFeatures(rawValue: 1 << 1)
    /// If present, the ``NodeFeatures/friend`` feature is enabled on the Node.
    public static let friend   = NodeFeatures(rawValue: 1 << 2)
    /// If present, the ``NodeFeatures/lowPower`` feature is enabled on the Node.
    public static let lowPower = NodeFeatures(rawValue: 1 << 3)
    
    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }
    
    internal func asArray() -> [NodeFeature] {
        var result: [NodeFeature] = []
        if contains(.relay) {
            result.append(.relay)
        }
        if contains(.proxy) {
            result.append(.proxy)
        }
        if contains(.friend) {
            result.append(.friend)
        }
        if contains(.lowPower) {
            result.append(.lowPower)
        }
        return result
    }
}

/// The state of a feature.
///
/// A Node can have features enabled, disabled, or may not support one.
public enum NodeFeatureState: UInt8, Codable {
    /// The feature is disabled.
    case notEnabled   = 0
    /// The feature is enabled.
    case enabled      = 1
    /// The feature is not supported by the Node.
    case notSupported = 2
}

/// The features state object represents the functionality of a mesh node
/// that is determined by the set features that the node supports.
public class NodeFeaturesState: Codable {
    /// The state of Relay feature or `nil` if unknown.
    public internal(set) var relay: NodeFeatureState?
    /// The state of Proxy feature or `nil` if unknown.
    public internal(set) var proxy: NodeFeatureState?
    /// The state of Friend feature or `nil` if unknown.
    public internal(set) var friend: NodeFeatureState?
    /// The state of Low Power feature or `nil` if unknown.
    public internal(set) var lowPower: NodeFeatureState?
    
    internal var rawValue: UInt16 {
        var bitField: UInt16 = 0
        if relay    == .notSupported {} else { bitField |= 0x01 }
        if proxy    == .notSupported {} else { bitField |= 0x02 }
        if friend   == .notSupported {} else { bitField |= 0x04 }
        if lowPower == .notSupported {} else { bitField |= 0x08 }
        return bitField
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: CodingKey {
        case relay
        case proxy
        case friend
        case lowPower
    }
    
    internal init(relay: NodeFeatureState?,
                  proxy: NodeFeatureState?,
                  friend: NodeFeatureState?,
                  lowPower: NodeFeatureState?) {
        self.relay    = relay
        self.proxy    = proxy
        self.friend   = friend
        self.lowPower = lowPower
    }
    
    internal init() {
        self.relay    = nil
        self.proxy    = nil
        self.friend   = nil
        self.lowPower = nil
    }
    
    /// This method creates the Node Features State object based on the
    /// feature bit-field from the Page 0 of the Composition Data.
    ///
    /// - parameter mask: Features field from the Page 0 of the Composition Page.
    internal init(mask: UInt16) {
        // The state of the following features is unknown until the corresponding
        // Config ... Get message is sent.
        self.relay    = mask & 0x01 == 0 ? .notSupported : nil
        self.proxy    = mask & 0x02 == 0 ? .notSupported : nil
        self.friend   = mask & 0x04 == 0 ? .notSupported : nil
        // The Low Power feature if supported is enabled and cannot be disabled.
        self.lowPower = mask & 0x08 == 0 ? .notSupported : .enabled
    }
    
    internal func applyMissing(from other: NodeFeaturesState) {
        if self.friend == nil {
            self.friend = other.friend
        }
        
        if self.lowPower == nil {
            self.lowPower = other.lowPower
        }
        
        if self.proxy == nil {
            self.proxy = other.proxy
        }
        
        if self.relay == nil {
            self.relay = other.relay
        }
    }
}

extension NodeFeature: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return rawValue
    }
    
}

extension NodeFeatures: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return "\(asArray())"
    }
    
}

extension NodeFeatureState: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .notEnabled:   return "Not enabled"
        case .enabled:      return "Enabled"
        case .notSupported: return "Not supported"
        }
    }
    
}

extension NodeFeaturesState: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return """
        Relay Feature:     \(relay?.debugDescription ?? "Unknown")
        Proxy Feature:     \(proxy?.debugDescription ?? "Unknown")
        Friend Feature:    \(friend?.debugDescription ?? "Unknown")
        Low Power Feature: \(lowPower?.debugDescription ?? "Unknown")
        """
    }
    
}

internal extension Array where Element == NodeFeature {
    
    func asSet() -> NodeFeatures {
        var set = NodeFeatures()
        if contains(.relay) {
            set.insert(.relay)
        }
        if contains(.proxy) {
            set.insert(.proxy)
        }
        if contains(.friend) {
            set.insert(.friend)
        }
        if contains(.lowPower) {
            set.insert(.lowPower)
        }
        return set
    }
    
}
