//
//  SetFilterType.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 03/09/2019.
//

import Foundation

public struct SetFilterType: StaticProxyConfigurationMessage {
    public static var opCode: UInt8 = 0x00
    
    public var parameters: Data? {
        return Data([filterType.rawValue])
    }
    
    /// The new filter type.
    public let filterType: ProxyFilerType
    
    /// Creates a new Set Filter Type message.
    ///
    /// This message can be used to set the proxy filter type and
    /// clear the proxy filter list.
    ///
    /// - parameter type: The new filter type. Setting the same
    ///                   filter type as was set before will clear
    ///                   the filter.
    public init(_ type: ProxyFilerType) {
        self.filterType = type
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 1 else {
            return nil
        }
        guard let type = ProxyFilerType(rawValue: parameters[0]) else {
            return nil
        }
        filterType = type
    }
}
