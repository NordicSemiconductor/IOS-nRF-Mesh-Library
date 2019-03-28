//
//  NodeFeatures.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 25/03/2019.
//

import Foundation

public class NodeFeatures: Codable {
    /// Supported values:
    /// 0 - the Relay feature is not enabled,
    /// 1 - the Relay feature is enabled,
    /// 2 - the Relay feature is not supported
    /// nil - unknown state of the Relay feature.
    var relay: UInt8?
    /// Supported values:
    /// 0 - the Proxy feature is not enabled,
    /// 1 - the Proxy feature is enabled,
    /// 2 - the Proxy feature is not supported
    /// nil - unknown state of the Proxy feature.
    var proxy: UInt8?
    /// Supported values:
    /// 0 - the Low Power feature is not enabled,
    /// 1 - the Low Power feature is enabled,
    /// 2 - the Low Power feature is not supported
    /// nil - unknown state of the Low Power feature.
    var lowPower: UInt8?
    /// Supported values:
    /// 0 - the Friend feature is not enabled,
    /// 1 - the Friend feature is enabled,
    /// 2 - the Friend feature is not supported
    /// nil - unknown state of the Friend feature.
    var friend: UInt8?
}

public extension NodeFeatures {
    
    public var isRelayFeatureStateKnown: Bool {
        return relay != nil
    }
    
    public var isRelayFeatureEnabled: Bool {
        return relay == 1
    }
    
    public var isRelayFeatureDisabled: Bool {
        return relay == 0
    }
    
    public var isRelayFeatureFeatureSupported: Bool {
        return relay != 2
    }
    
    public var isProxyFeatureStateKnown: Bool {
        return proxy != nil
    }
    
    public var isProxyFeatureEnabled: Bool {
        return proxy == 1
    }
    
    public var isProxyFeatureDisabled: Bool {
        return proxy == 0
    }
    
    public var isProxyFeatureSupported: Bool {
        return proxy != 2
    }
    
    public var isLowPowerFeatureStateKnown: Bool {
        return lowPower != nil
    }
    
    public var isLowPowerFeatureEnabled: Bool {
        return lowPower == 1
    }
    
    public var isLowPowerFeatureDisabled: Bool {
        return lowPower == 0
    }
    
    public var isLowPowerFeatureSupported: Bool {
        return lowPower != 2
    }
    
    public var isFriendFeatureStateKnown: Bool {
        return friend != nil
    }
    
    public var isFriendFeatureEnabled: Bool {
        return friend == 1
    }
    
    public var isFriendFeatureDisabled: Bool {
        return friend == 0
    }
    
    public var isFriendFeatureSupported: Bool {
        return friend != 2
    }
}
