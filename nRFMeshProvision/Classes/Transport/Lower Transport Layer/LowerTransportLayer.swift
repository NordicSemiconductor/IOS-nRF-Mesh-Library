//
//  LowerTransportLayer.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 27/02/2018.
//

import Foundation

public typealias SegmentedMessageAcknowledgeBlock = (_ ackData: Data, _ delay: DispatchTime) -> (Void)
public struct LowerTransportLayer {
    var params : LowerTransportPDUParams!
    var partialIncomingPDU: [Data]?
    var meshStateManager: MeshStateManager?
    var lastSegO: UInt8 = 0
    var segmentedMessageAcknowledge: SegmentedMessageAcknowledgeBlock?
    var segAcknowledgeStartTime: DispatchTime?

    public init(withStateManager aStateManager: MeshStateManager, andSegmentedAcknowlegdeMent anAcknowledgementBlock: SegmentedMessageAcknowledgeBlock?) {
        segmentedMessageAcknowledge = anAcknowledgementBlock
        meshStateManager = aStateManager
        partialIncomingPDU = [Data]()
        lastSegO = 0x00
    }

    public mutating func append(withIncomingPDU aPDU: Data, ctl aCTL: Data, ttl aTTL: Data, src aSRC: Data, dst aDST: Data, IVIndex anIVIndex: Data, andSEQ aSEQ: Data) -> Any? {
        let dst = Data(aPDU[0...1])
        guard dst == meshStateManager?.state().unicastAddress else {
            print("Ignoring message not directed towards us!")
            return nil
        }
        let segmented = Data([aPDU[2] >> 7])
        let akf = Data([aPDU[2] >> 6 & 0x01])
        let aid = Data([aPDU[2] & 0x3F])
        let ctl = aCTL == Data([0x01]) ? true : false
        let isAppKey = akf == Data([0x01]) ? true : false

        if segmented == Data([0x00]) {
            //Unsegmented Message
            let incomingFullSegment = Data(aPDU[3..<aPDU.count])
            let upperLayer = UpperTransportLayer(withIncomingPDU: incomingFullSegment, ctl: ctl, akf: isAppKey, aid: aid, seq: aSEQ, src: aSRC, dst: aDST, szMIC: 0, ivIndex: anIVIndex, andMeshState: meshStateManager!)
            //Return a parsed message
            return upperLayer.assembleMessage()
        } else {
            let szMIC = Data([aPDU[3] >> 7])
            let seqZero = Data([(aPDU[3] & 0x7F) >> 2, ((aPDU[3] << 6) | (aPDU[4] >> 2))])
            let segO = Data([0x00 & UInt8((aPDU[4] & 0x03) << 3) | UInt8((aPDU[5] & 0xE0) >> 5)])
            let segN = Data([aPDU[5] & 0x1F])
            let segment = Data(aPDU[6..<aPDU.count])
            let sequenceNumber = Data([aSEQ.first!, seqZero[0], seqZero[1]])
            print("szMIC = \(szMIC.hexString()), seqZero = \(seqZero.hexString()), segO = \(segO.hexString()), segN = \(segN.hexString()), segment = \(segment.hexString()), sequence: \(sequenceNumber.hexString())")
            print("Partial incomind PDU count = \(partialIncomingPDU!.count)")
            if !partialIncomingPDU!.contains(segment) {
                partialIncomingPDU!.append(segment)
            } else {
                print("Append seg: DUPE")
            }
            if segO == Data([0x00]) && segN != Data([0x00]) {
                if segmentedMessageAcknowledge != nil {
                    segAcknowledgeStartTime = DispatchTime.now()
                    print("Segmetned timer start at \(segAcknowledgeStartTime!)")
                }
            } else if segO != segN {
                print("received part \(segO.hexString()) of \(segN.hexString()), SeqZero = \(seqZero.hexString()).")
            } else {
                if segmentedMessageAcknowledge != nil {
                    if segN == Data([0x00]) {
                        segAcknowledgeStartTime = DispatchTime.now()
                        print("Segmetned timer start at \(segAcknowledgeStartTime!)")
                    }
                }
                print("received last part \(segO.hexString()) of \(segN.hexString()), SeqZero = \(seqZero.hexString()), reassembling")
                if segAcknowledgeStartTime == nil {
                    segAcknowledgeStartTime = DispatchTime.now()
                }
                let (ackData, delay) = self.acknowlegde(withSeqZero: seqZero, segN: segN, segO: segO, dst: aSRC, ttl: aTTL, startTime: segAcknowledgeStartTime!)
                segmentedMessageAcknowledge?(ackData, delay)
                segAcknowledgeStartTime = nil //Reset timer
                var fullData = Data()
                for aPart in partialIncomingPDU! {
                    fullData.append(aPart)
                }
                partialIncomingPDU!.removeAll()
                let upperLayer = UpperTransportLayer(withIncomingPDU: fullData, ctl: ctl, akf: isAppKey, aid: aid, seq: sequenceNumber, src: aSRC, dst: aDST, szMIC: Int(szMIC[0]), ivIndex: anIVIndex, andMeshState: meshStateManager!)

                //Return a parsed message
                return upperLayer.assembleMessage()
            }
        }
        return nil
    }

    public func acknowlegde(withSeqZero seqZero: Data, segN: Data, segO: Data, dst: Data, ttl aTTL: Data, startTime: DispatchTime) -> (Data, DispatchTime) {
        let aState = meshStateManager!.state()
        let delay = startTime + DispatchTimeInterval.milliseconds(150 + (50 * 7))
        var block : UInt32 = 0x00000000
        for _ in 0...segN[0] {
            block = (block << 1) + 0x01
        }
        let blockData = Data([
            UInt8((block & 0xFF000000) >> 24),
            UInt8((block & 0x00FF0000) >> 16),
            UInt8((block & 0x0000FF00) >> 8),
            UInt8((block & 0x000000FF))
            ])
        //First bit of octet 1 is 0 OBO is not implenented yet.
        var payload = Data([UInt8((seqZero[0] & 0x1F) << 2) | UInt8((seqZero[1] & 0xC0) >> 6),
                            UInt8(seqZero[1] << 2)])
        payload.append(Data(blockData))
        let opcode  = Data([0x00]) //Segment ACK Opcode
        let ackMessage = ControlMessagePDU(withPayload: payload, opcode: opcode, netKey: aState.netKey, seq: SequenceNumber(), ivIndex: aState.IVIndex, source: aState.unicastAddress, andDst: dst)
        var ackData = Data([0x00]) //Network PDU
        let networkPDU = ackMessage.assembleNetworkPDU()!.first!
        ackData.append(Data(networkPDU))
        return (Data(ackData), delay)
    }

    public init(withParams someParams: LowerTransportPDUParams) {
        params = someParams
    }
   
    public func createPDU() -> [Data] {
        if params.ctl == Data([0x01]) {
            if isSegmented() {
                return createSegmentedControlMessage()
            } else {
                return [createUnsegmentedControlMessage()]
            }
        } else {
            if isSegmented() {
                return createSegmentedAccessMessage()
            } else {
                return [createUnsegmentedAccessMessasge()]
            }
        }
   }

    // MARK: - Segmentation
    private func createUnsegmentedAccessMessasge() -> Data {
        var lowerData = Data()
        //First octet = (1BIT)0 || (1BIT)AFK || (6BITS)AID
        var headerByte = Data()
        if params.appKeyFlag == Data([0x01]) {
            //APP Key Flag is set, use AFK and AID from upper transport
            let aid : UInt8 = params.aid[0]
            let header = 0x40 | aid //0x40 == 0100 0000
            headerByte.append(Data([header]))
        } else {
            //No APP key used, first octet will be 0x00
            headerByte.append(Data([0x00]))
        }
        lowerData.append(Data(headerByte))
        lowerData.append(Data(params.upperTransportData))
        return lowerData
    }

    private func createSegmentedAccessMessage() -> [Data] {
        var chunkedData = [Data]()
        let chunkSize   = 12 //12 bytes is the max
        let chunkRanges = calculateDataRanges(params.upperTransportData, withSize: chunkSize)

        for aChunkRange in chunkRanges {
            var headerByte  = Data()
            if params.appKeyFlag == Data([0x01]) {
                //APP Key flag is set, use AFK and AID from upper transport
                //Octet 0 is 11xx xxx == where xx xxx is AID
                let header = 0xC0 | params.aid[0]
                headerByte.append(Data([header]))
            } else {
                //No Appkey used, Octet 0 is 1000 0000 == 0x80
                headerByte.append(Data([0x80]))
            }
            var currentChunk = Data()
            let segO = UInt8(chunkRanges.index(of: aChunkRange)!)
            let segN = UInt8(chunkRanges.count - 1) //0 index
            var bytes: UInt8 = (params.szMIC[0] << 7 ) | ((params.sequenceNumber.sequenceData()[1] << 2) & 0x7F) | (params.sequenceNumber.sequenceData()[2] >> 6)
            headerByte.append(Data([bytes]))
            bytes = (params.sequenceNumber.sequenceData()[2] << 2) | (segO >> 6)
            headerByte.append(Data([bytes]))
            bytes = (segO << 5) | (segN & 0x1F)
            headerByte.append(Data([bytes]))
            //Append header
            currentChunk.append(Data(headerByte))
            //Then append current chunk
            currentChunk.append(Data(params.upperTransportData.subdata(in: aChunkRange)))
            chunkedData.append(Data(currentChunk))
        }
        return chunkedData
    }

    private func createUnsegmentedControlMessage() -> Data {
        var pdu = Data()
        pdu.append(Data([0x7F & params.opcode[0]]))
        pdu.append(Data(params.upperTransportData))
        return pdu
    }

    private func createSegmentedControlMessage() -> [Data] {
        var chunkedData = [Data]()
        let chunkSize   = 8 //8 bytes is the max for control messages
        let chunkRanges = calculateDataRanges(params.upperTransportData, withSize: chunkSize)
        for aChunkRange in chunkRanges {
            var headerByte  = Data()
            headerByte.append(0x80 | (params.opcode[0] & 0x7F))
            var currentChunk = Data()
            let segO = UInt8(chunkRanges.index(of: aChunkRange)!)
            let segN = UInt8(chunkRanges.count - 1) //0 index
            //First bit is 1 (RFU)
            let sequenceData = params.sequenceNumber.sequenceData()
            var bytes: UInt8 = 0x00 | ((sequenceData[1] << 2) & 0x7F) | (sequenceData[2] >> 6)
            headerByte.append(bytes)
            bytes = (sequenceData[2] << 2) | (segO >> 6)
            headerByte.append(bytes)
            bytes = (segO << 5) | (segN & 0x1F)
            headerByte.append(bytes)
            //Append header
            currentChunk.append(headerByte)
            //Then append current chunk
            currentChunk.append(params.upperTransportData.subdata(in: aChunkRange))
            chunkedData.append(currentChunk)
        }
        return chunkedData
    }
   
    // MARK: - Helpers
    private func isSegmented() -> Bool {
        return params.segmented == Data([0x01])
    }

    private func calculateDataRanges(_ someData: Data, withSize aChunkSize: Int) -> [Range<Int>] {
        var totalLength = someData.count
        var ranges = [Range<Int>]()
        var partIdx = 0
        while (totalLength > 0) {
            var range : Range<Int>
            if totalLength > aChunkSize {
                totalLength -= aChunkSize
                range = (partIdx * aChunkSize) ..< aChunkSize + (partIdx * aChunkSize)
            } else {
                range = (partIdx * aChunkSize) ..< totalLength + (partIdx * aChunkSize)
                totalLength = 0
            }
            ranges.append(range)
            partIdx += 1
        }
        return ranges
    }
}
