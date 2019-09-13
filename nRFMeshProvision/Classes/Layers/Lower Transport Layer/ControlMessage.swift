//
//  ControlMessage.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 31/05/2019.
//

import Foundation

internal struct ControlMessage: LowerTransportPdu {    
    let source: Address
    let destination: Address
    let networkKey: NetworkKey
    
    /// Message Op Code.
    let opCode: UInt8
    
    let upperTransportPdu: Data
    
    var transportPdu: Data {
        return Data() + opCode + upperTransportPdu
    }
    
    let type: LowerTransportPduType = .controlMessage
    
    /// Creates a Control Message from a Network PDU that contains
    /// an unsegmented control message.
    ///
    /// - parameter networkPdu: The received Network PDU with unsegmented
    ///                         Upper Transport message.
    /// - returns: The Control Message object, or `nil`, if the given PDU
    ///            was invalid.
    init?(fromNetworkPdu networkPdu: NetworkPdu) {
        let data = networkPdu.transportPdu
        guard data.count >= 1, data[0] & 0x80 == 0 else {
            return nil
        }
        opCode = data[0] & 0x7F
        upperTransportPdu = data.advanced(by: 1)
        
        source = networkPdu.source
        destination = networkPdu.destination
        networkKey = networkPdu.networkKey
    }
    
    /// Creates a Control Message object from the given list of segments.
    ///
    /// - parameter segments: List of ordered segments.
    init(fromSegments segments: [SegmentedControlMessage]) {
        // Assuming all segments have the same AID, source and destination addresses and TransMIC.
        let segment = segments.first!
        opCode = segment.opCode
        source = segment.source
        destination = segment.destination
        networkKey = segment.networkKey
        
        // Segments are already sorted by `segmentOffset`.
        upperTransportPdu = segments.reduce(Data()) {
            $0 + $1.upperTransportPdu
        }
    }
    
    /// Creates a Control Message from the given Proxy Configuration
    /// message. The source should be set to the local Node address.
    /// The given Network Key should be known to the Proxy Node.
    ///
    /// - parameter message:    The message to be sent.
    /// - parameter source:     The address of the local Node.
    /// - parameter networkKey: The Network Key to signe the message with.
    ///                         The key should be known to the connected
    ///                         Proxy Node.
    init(fromProxyConfigurationMessage message: ProxyConfigurationMessage,
         sentFrom source: Address, usingNetworkKey networkKey: NetworkKey) {
        self.opCode = message.opCode
        self.source = source
        self.destination = Address.unassignedAddress
        self.networkKey = networkKey
        self.upperTransportPdu = message.parameters ?? Data()
    }
}

extension ControlMessage: CustomDebugStringConvertible {
    
    var debugDescription: String {
        return "\(type) (opCode: 0x\(opCode.hex), data: 0x\(upperTransportPdu.hex))"
    }
    
}
