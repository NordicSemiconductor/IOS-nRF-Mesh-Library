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
    
    init?(fromNetworkPdu networkPdu: NetworkPdu) {
        let data = networkPdu.transportPdu
        guard data.count >= 5, data[0] & 0x80 == 0 else {
            return nil
        }
        opCode = data[0] & 0x7F
        guard opCode == 0x00 else {
            return nil
        }
        upperTransportPdu = data.dropFirst()
        
        source = networkPdu.source
        destination = networkPdu.destination
        networkKey = networkPdu.networkKey
    }
    
    init(from segments: [SegmentedControlMessage]) {
        // Assuming all segments have the same AID, source and destination addresses and TransMIC.
        let segment = segments.first!
        opCode = segment.opCode
        source = segment.source
        destination = segment.destination
        networkKey = segment.networkKey
        
        // Segments are already sorted by `segmentOffset`.
        upperTransportPdu = segments
            .reduce(Data(), { (result, next) -> Data in
                return result + next.upperTransportPdu
            })
    }
}

extension ControlMessage: CustomDebugStringConvertible {
    
    var debugDescription: String {
        return "\(type) (\(source.hex)->\(destination.hex)): Op Code: \(opCode), 0x\(upperTransportPdu.hex)"
    }
    
}
