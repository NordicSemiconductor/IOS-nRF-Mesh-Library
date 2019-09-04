//
//  FilterStatus.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 03/09/2019.
//

import Foundation

public struct FilterStatus: StaticProxyConfigurationMessage {
    public static var opCode: UInt8 = 0x03
    
    public var parameters: Data? {
        return Data([filterType.rawValue]) + listSize.bigEndian
    }
    
    /// The current filter type.
    public let filterType: ProxyFilerType
    /// Number of addresses in the proxy filter list.
    public let listSize: UInt16
    
    /// Creates a new Filter Status message.
    ///
    /// - parameter type: The current filter type.
    /// - parameter listSize: Number of addresses in the proxy
    ///                       filter list.
    public init(_ type: ProxyFilerType, listSize: UInt16) {
        self.filterType = type
        self.listSize = listSize
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 3 else {
            return nil
        }
        guard let type = ProxyFilerType(rawValue: parameters[0]) else {
            return nil
        }
        filterType = type
        listSize = parameters.readBigEndian(fromOffset: 1)
    }
}
