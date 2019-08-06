//
//  ConfigGATTProxyStatus.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 06/08/2019.
//

import Foundation

public struct ConfigGATTProxyStatus: ConfigMessage {
    public static let opCode: UInt32 = 0x8014
    
    public var parameters: Data? {
        return Data([state.rawValue])
    }
    
    /// The GATT Proxy state of the Node.
    public let state: NodeFeaturesState
    
    /// Creates the Config GATT Proxy Status message.
    ///
    /// - parameter state: The GATT Proxy state of the Node.
    public init(_ state: NodeFeaturesState) {
        self.state = state
    }
    
    public init(for node: Node) {
        self.state = node.features?.proxy ?? .notSupported
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 1 else {
            return nil
        }
        guard let state = NodeFeaturesState(rawValue: parameters[0]) else {
            return nil
        }
        self.state = state
    }
    
}

