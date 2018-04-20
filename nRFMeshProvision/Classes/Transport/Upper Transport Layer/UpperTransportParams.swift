//
//  UpperTransportParams.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 26/02/2018.
//

import Foundation

public struct UpperTransportPDUParams {
    let opcode              : Data
    let payload             : Data
    let ivIndex             : Data
    let key                 : Data
    let ttl                 : Data
    let sequenceNumber      : SequenceNumber
    let sourceAddress       : Data
    let destinationAddress  : Data
    let nonce               : TransportNonce
    let ctl                 : Bool
    let afk                 : Bool
    let aid                 : Data
    
    public init(withPayload aPayload: Data, opcode anOpcode: Data, IVIndex anIVIndex: Data, key aKey: Data, ttl aTTL: Data,
                seq aSeq: SequenceNumber, src aSrc: Data, dst aDst: Data, nonce aNonce: TransportNonce,
                ctl aCtl: Bool, afk anAFK: Bool, aid anAID: Data) {
        opcode              = anOpcode
        payload             = aPayload
        ivIndex             = anIVIndex
        key                 = aKey
        ttl                 = aTTL
        sequenceNumber      = aSeq
        sourceAddress       = aSrc
        destinationAddress  = aDst
        nonce               = aNonce
        ctl                 = aCtl
        afk                 = anAFK
        aid                 = anAID
    }
}
