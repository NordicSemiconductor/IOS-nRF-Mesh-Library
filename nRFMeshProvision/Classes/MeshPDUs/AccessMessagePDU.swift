//
//  AccessMessagePDU.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 06/03/2018.
//

import Foundation

public struct AccessMessagePDU {
    let opcode      : Data
    let payload     : Data
    let key         : Data?
    let netKey      : Data
    let isAppKey    : Bool
    let ivIndex     : Data
    let ttl         : Data
    let src         : Data
    let dst         : Data
    let seq         : SequenceNumber

    public init(withPayload aPayload: Data, opcode anOpcode: Data, appKey anAppKey: Data, netKey aNetKey: Data, seq aSeq: SequenceNumber, ivIndex anIVIndex: Data, source aSrc: Data, andDst aDST: Data) {
        isAppKey    = true
        opcode      = anOpcode
        payload     = aPayload
        key         = anAppKey
        netKey      = aNetKey
        src         = aSrc
        dst         = aDST
        ivIndex     = anIVIndex
        seq         = aSeq
        ttl         = Data([0x04])
    }

    public init(withPayload aPayload: Data, opcode anOpcode: Data, deviceKey aDeviceKey: Data, netKey aNetKey: Data, seq aSeq: SequenceNumber, ivIndex anIVIndex: Data, source aSrc: Data, andDst aDST: Data) {
        isAppKey    = false
        opcode      = anOpcode
        payload     = aPayload
        key         = aDeviceKey
        netKey      = aNetKey
        src         = aSrc
        dst         = aDST
        ivIndex     = anIVIndex
        seq         = aSeq
        ttl         = Data([0x04])
    }
   
    public func assembleNetworkPDU() -> [Data]? {
        var nonce : TransportNonce
        let segmented = payload.count > 12
        if isAppKey {
            nonce = TransportNonce(appNonceWithIVIndex: ivIndex, isSegmented: segmented, seq: seq.sequenceData(), src: src, dst: dst)
        } else {
            let addressType = MeshAddressTypes(rawValue: Data(dst))!
            if addressType == .Unassigned { //This is a proxy nonce message since destination is an unassigned address
                nonce = TransportNonce(proxyNonceWithIVIndex: ivIndex, seq: seq.sequenceData(), src: src)
            } else if addressType == .Unicast {
                nonce = TransportNonce(deviceNonceWithIVIndex: ivIndex, isSegmented: segmented, szMIC: 0, seq: seq.sequenceData(), src: src, dst: dst)
            } else {
                nonce = TransportNonce(networkNonceWithIVIndex: ivIndex, ctl: Data([0x00]), ttl: ttl, seq: seq.sequenceData(), src: src)
            }
        }

        var upperTransportParams: UpperTransportPDUParams!

        if nonce.type == .Device {
            upperTransportParams = UpperTransportPDUParams(withPayload: opcode + payload, opcode: opcode, IVIndex: ivIndex, key: key!, ttl: ttl, seq: seq, src: src, dst: dst, nonce: nonce, ctl: false, afk: isAppKey, aid: Data([0x00]))
        } else {
            upperTransportParams = UpperTransportPDUParams(withPayload: opcode + payload, opcode: opcode, IVIndex: ivIndex, key: netKey, ttl: ttl, seq: seq, src: src, dst: dst, nonce: nonce, ctl: false, afk: isAppKey, aid: Data([0x00]))
        }

        let upperTransport = UpperTransportLayer(withParams: upperTransportParams)

        if let encryptedPDU = upperTransport.encrypt() {
            let isAppKeyData = isAppKey ? Data([0x01]) : Data([0x00])
            let lowerTransportParams = LowerTransportPDUParams(withUpperTransportData: encryptedPDU, ttl: ttl, ctl: Data([0x00]), ivIndex: ivIndex, sequenceNumber: seq, sourceAddress: src, destinationAddress: dst, micSize: Data([0x00]), afk: isAppKeyData, aid: Data([0x00]), andOpcode: opcode)
            let lowerTransport = LowerTransportLayer(withParams: lowerTransportParams)
            let networkLayer = NetworkLayer(withLowerTransportLayer: lowerTransport, andNetworkKey: netKey)
            return networkLayer.createPDU()
        } else {
            return nil
        }
   }
}
