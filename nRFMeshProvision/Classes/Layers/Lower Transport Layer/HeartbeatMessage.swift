//
//  HeartbeatMessage.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 31/05/2019.
//

import Foundation

internal struct Features: OptionSet {
    let rawValue: UInt16
    
    static let relay    = Features(rawValue: 1 << 0)
    static let proxy    = Features(rawValue: 1 << 1)
    static let friend   = Features(rawValue: 1 << 2)
    static let lowPower = Features(rawValue: 1 << 3)
}

internal struct HearbeatMessage: ControlMessage {
    let source: Address?
    let destination: Address
    
    let opCode: UInt8
    
    /// Initial TTL used when sending the message.
    let initTtl: UInt8
    /// Currently active features of the node.
    let features: Features
    
    var transportPdu: Data {
        return Data() + opCode + initTtl + features.rawValue.bigEndian
    }
    
    let type: LowerTransportPduType = .controlMessage
    
    init?(from networkPdu: NetworkPdu) {
        let data = networkPdu.transportPdu
        guard data.count == 4, data[0] & 0x80 == 0 else {
            return nil
        }
        opCode = data[0] & 0x7F
        guard opCode == 0x0A else {
            return nil
        }
        initTtl = data[1] & 0x7F
        features = Features(rawValue: UInt16(data[2] << 8) | UInt16(data[3]))
        
        source = networkPdu.source
        destination = networkPdu.destination
    }
    
    /// Creates the Heartbeat message.
    ///
    /// - parameter ttl:         Initial TTL used when sending the message.
    /// - parameter features:    Currently active features of the node.
    /// - parameter destination: The destination address.
    init(withInitialTtl ttl: UInt8, andFeatures features: Features, targetting destination: Address) {
        self.opCode = 0x0A
        self.initTtl = ttl
        self.features = features
        self.source = nil
        self.destination = destination
    }
}
