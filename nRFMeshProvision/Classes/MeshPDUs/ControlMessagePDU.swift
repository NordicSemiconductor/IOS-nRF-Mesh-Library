//
//  ControlMessagePDU.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 08/03/2018.
//

import Foundation

public struct ControlMessagePDU {
    let opcode      : Data
    let payload     : Data
    let key         : Data
    let devkey      : Data?
    let isAppKey    : Bool
    let ivIndex     : Data
    let ttl         : Data
    let src         : Data
    let dst         : Data
    let seq         : SequenceNumber
    
    public init(withPayload aPayload: Data, opcode anOpcode: Data, netKey aNetKey: Data, seq aSeq: SequenceNumber, ivIndex anIVIndex: Data, source aSrc: Data, andDst aDST: Data) {
        isAppKey    = false
        opcode      = anOpcode
        payload     = aPayload
        key         = aNetKey
        devkey      = nil
        src         = aSrc
        dst         = aDST
        ivIndex     = anIVIndex
        seq         = aSeq
        ttl         = Data([0x07])
    }
   
    public init(withPayload aPayload: Data, opcode anOpcode: Data, deviceKey aDeviceKey: Data, netKey aNetKey: Data, seq aSeq: SequenceNumber, ivIndex anIVIndex: Data, source aSrc: Data, andDst aDST: Data) {
        isAppKey    = false
        opcode      = anOpcode
        payload     = aPayload
        key         = aNetKey
        devkey      = aDeviceKey
        src         = aSrc
        dst         = aDST
        ivIndex     = anIVIndex
        seq         = aSeq
        ttl         = Data([0x07])
    }
   
    public func assembleNetworkPDU() -> [Data]? {
        var nonce : TransportNonce
        let segmented = payload.count > 12
        if isAppKey {
            nonce = TransportNonce(appNonceWithIVIndex: ivIndex, isSegmented: segmented, seq: seq.sequenceData(), src: src, dst: dst)
        } else {
            let addressType = MeshAddressTypes(rawValue: dst)!
            if addressType == .Unassigned { //This is a proxy nonce message since destination is an unassigned address
                nonce = TransportNonce(proxyNonceWithIVIndex: ivIndex, seq: seq.sequenceData(), src: src)
            } else {
                nonce = TransportNonce(networkNonceWithIVIndex: ivIndex, ctl: Data([0x01]), ttl: ttl, seq: seq.sequenceData(), src: src)
            }
        }
   
        let upperTransportParams = UpperTransportPDUParams(withPayload: payload, opcode: opcode, IVIndex: ivIndex, key: key, ttl: ttl, seq: seq, src: src, dst: dst, nonce: nonce, ctl: true, afk: isAppKey, aid: Data([0x00]))

        let upperTransport = UpperTransportLayer(withParams: upperTransportParams)

        if let rawPDU = upperTransport.rawData() {
            let isAppKeyData = isAppKey ? Data([0x01]) : Data([0x00])
            let lowerTransportParams = LowerTransportPDUParams(withUpperTransportData: rawPDU, ttl: ttl, ctl: Data([0x01]), ivIndex: ivIndex, sequenceNumber: seq, sourceAddress: src, destinationAddress: dst, micSize: Data([0x01]), afk: isAppKeyData, aid: Data([0x00]), andOpcode: opcode)
            let lowerTransport = LowerTransportLayer(withParams: lowerTransportParams)
            let networkLayer = NetworkLayer(withLowerTransportLayer: lowerTransport, andNetworkKey: key)
            return networkLayer.createPDU()
        } else {
            return nil
        }
   }
}
