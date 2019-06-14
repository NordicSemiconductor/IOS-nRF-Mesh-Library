//
//  ConfigCompositionDataStatus.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 14/06/2019.
//

import Foundation

public struct ConfigCompositionDataStatus: ConfigMessage {
    public let opCode: UInt32 = 0x02
    public var parameters: Data? {
        return Data([page]) // TODO
    }
    
    /// Page number of the Composition Data to get.
    public let page: UInt8
    
    /// The 16-bit Company Identifier (CID) assigned by the Bluetooth SIG.
    /// The value of this property is obtained from node composition data.
    public let companyIdentifier: UInt16
    /// The 16-bit vendor-assigned Product Identifier (PID).
    /// The value of this property is obtained from node composition data.
    public let productIdentifier: UInt16
    /// The 16-bit vendor-assigned Version Identifier (VID).
    /// The value of this property is obtained from node composition data.
    public let versionIdentifier: UInt16
    /// The minimum number of Replay Protection List (RPL) entries for this
    /// node. The value of this property is obtained from node composition
    /// data.
    public let minimumNumberOfReplayProtectionList: UInt16
    /// Node's features. See `NodeFeatures` for details.
    public let features: NodeFeatures
    /// An array of node's elements.
    public let elements: [Element]
    
    public init(node: Node) {
        page = 0
        companyIdentifier = node.companyIdentifier ?? 0
        productIdentifier = node.productIdentifier ?? 0
        versionIdentifier = node.versionIdentifier ?? 0
        minimumNumberOfReplayProtectionList = node.minimumNumberOfReplayProtectionList ?? 0
        features = node.features ?? NodeFeatures()
        elements = node.elements
    }
    
    public init?(parameters: Data) {
        guard parameters.count >= 11 else {
            return nil
        }
        page = parameters[0]
        companyIdentifier = CFSwapInt16BigToHost(parameters.convert(offset: 1))
        productIdentifier = CFSwapInt16BigToHost(parameters.convert(offset: 3))
        versionIdentifier = CFSwapInt16BigToHost(parameters.convert(offset: 5))
        minimumNumberOfReplayProtectionList = CFSwapInt16BigToHost(parameters.convert(offset: 7))
        let bitField = CFSwapInt16BigToHost(parameters.convert(offset: 9))
        features = NodeFeatures(rawValue: bitField)
        
        if parameters.count == 11 {
            elements = []
        } else {
            /*
            var offset = 11
            while offset < parameters.count {
                guard parameters.count >= offset + 4 else {
                    return nil
                }
            }*/
            elements = [] // TODO: Finish implementation
        }
    }
    
}
