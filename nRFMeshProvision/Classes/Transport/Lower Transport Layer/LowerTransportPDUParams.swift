//
//  UpperTransportPDUParams.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 26/02/2018.
//

import Foundation

public struct LowerTransportPDUParams {
    var upperTransportData  : Data
    var ctl                 : Data
    var ttl                 : Data
    var ivIndex             : Data
    var sequenceNumber      : SequenceNumber
    var sourceAddress       : Data
    var destinationAddress  : Data
    var segmented           : Data
    var appKeyFlag          : Data
    var aid                 : Data
    var szMIC               : Data
    var opcode              : Data
    var seqZero             : Data
    var seqN                : Data
    
    public init(withUpperTransportData someData: Data, ttl aTTL: Data, ctl aCTL: Data, ivIndex anIVIndex: Data, sequenceNumber aSequence: SequenceNumber, sourceAddress aSource: Data, destinationAddress aDestination: Data, micSize aMicSize: Data, afk anAFK: Data, aid anAID: Data, andOpcode anOpcode: Data) {
        upperTransportData  = someData
        ttl                 = aTTL
        ctl                 = aCTL
        ivIndex             = anIVIndex
        sequenceNumber      = aSequence
        sourceAddress       = aSource
        destinationAddress  = aDestination
        szMIC               = aMicSize
        aid                 = anAID
        opcode              = anOpcode
        appKeyFlag          = anAFK
        seqZero             = aSequence.sequenceData()
        let dataCount       = upperTransportData.count
        let segmentCount    = UInt8(ceil(Double(dataCount) / 12.0))
        seqN                = Data([segmentCount])
        segmented           = upperTransportData.count > 12 ? Data([0x01]) : Data([0x00])
    }
}
