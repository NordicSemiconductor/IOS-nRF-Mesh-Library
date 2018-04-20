//
//  NetworkLayerTests.swift
//  nRFMeshProvision_Tests
//
//  Created by Mostafa Berg on 05/03/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
import nRFMeshProvision

class NetworkLayerTests: XCTestCase {

    func testNetworkLayerAssembly() {
        let accessPaylod    = Data([0x00, 0x56, 0x34, 0x12, 0x63, 0x96, 0x47, 0x71, 0x73, 0x4F,
                                    0xBD, 0x76, 0xE3, 0xB4, 0x05, 0x19, 0xD1, 0xD9, 0x4A, 0x48])
        let ivIndex         = Data([0x12, 0x34, 0x56, 0x78])
        let deviceKey       = Data([0x9D, 0x6D, 0xD0, 0xE9, 0x6E, 0xB2, 0x5D, 0xC1, 0x9A, 0x40,
                                    0xED, 0x99, 0x14, 0xF8, 0xF0, 0x3F])
        let ttl             = Data([0x04])
        let seq             = SequenceNumber(withCount: 3221931) //0x3129AB
        let src             = Data([0x00, 0x03])
        let dst             = Data([0x12, 0x01])
        let opcode          = Data([0x00])
        let nonce           = TransportNonce(deviceNonceWithIVIndex: ivIndex, isSegmented: true,
                                             szMIC: 0, seq: seq.sequenceData(), src: src, dst: dst)
        let upperTransportParams = UpperTransportPDUParams(withPayload: accessPaylod, opcode: opcode, IVIndex: ivIndex,
                                                            key: deviceKey, ttl: ttl, seq: seq,
                                                            src: src, dst: dst, nonce: nonce,
                                                            ctl: false, afk: false, aid: Data([0x00]))
        let upperTransportLayer = UpperTransportLayer(withParams: upperTransportParams)
        let lowerTransportParams = LowerTransportPDUParams(withUpperTransportData: upperTransportLayer.encrypt()!,
                                                           ttl: ttl, ctl: Data([0x00]),
                                                           ivIndex: ivIndex, sequenceNumber: seq,
                                                           sourceAddress: src, destinationAddress: dst,
                                                           micSize: Data([0x08]), afk: Data([0x00]),
                                                           aid: Data([0x00]), andOpcode: opcode)
        let lowerTransportLayer = LowerTransportLayer(withParams: lowerTransportParams)
        let netLayer = NetworkLayer(withLowerTransportLayer: lowerTransportLayer,
                                    andNetworkKey: Data([0x7D, 0xD7, 0x36, 0x4C, 0xD8, 0x42, 0xAD, 0x18,
                                                         0xC1, 0x7C, 0x2B, 0x82, 0x0C, 0x84, 0xC3, 0xD6]))
        let networkLayerPDUs = [Data([0x68, 0xCA, 0xB5, 0xC5, 0x34, 0x8A, 0x23, 0x0A,
                                      0xFB, 0xA8, 0xC6, 0x3D, 0x4E, 0x68, 0x63, 0x64,
                                      0x97, 0x9D, 0xEA, 0xF4, 0xFD, 0x40, 0x96, 0x11,
                                      0x45, 0x93, 0x9C, 0xDA, 0x0E]),
                                Data([0x68, 0x16, 0x15, 0xB5, 0xDD, 0x4A, 0x84, 0x6C,
                                      0xAE, 0x0C, 0x03, 0x2B, 0xF0, 0x74, 0x6F, 0x44,
                                      0xF1, 0xB8, 0xCC, 0x8C, 0xE5, 0xED, 0xC5, 0x7E,
                                      0x55, 0xBE, 0xED, 0x49, 0xC0])]
        let result = netLayer.createPDU()
        XCTAssert(result.count == networkLayerPDUs.count,
                  "Expected 2 PDUs, \(result.count) segmentes were created instead")
        XCTAssert(result[0] == networkLayerPDUs[0], "First Network PDU Segment did not match test value")
        XCTAssert(result[1] == networkLayerPDUs[1], "Second Network PDU Segment did not match test value")
    }

    func testEndToEndLayer() {
        let accessPaylod    = Data([0x56, 0x34, 0x12, 0x63, 0x96, 0x47, 0x71,
                                    0x73, 0x4F, 0xBD, 0x76, 0xE3, 0xB4, 0x05, 0x19,
                                    0xD1, 0xD9, 0x4A, 0x48])
        let deviceKey       = Data([0x9D, 0x6D, 0xD0, 0xE9, 0x6E, 0xB2, 0x5D, 0xC1,
                                    0x9A, 0x40, 0xED, 0x99, 0x14, 0xF8, 0xF0, 0x3F])
        let netKey          = Data([0x7D, 0xD7, 0x36, 0x4C, 0xD8, 0x42, 0xAD, 0x18,
                                    0xC1, 0x7C, 0x2B, 0x82, 0x0C, 0x84, 0xC3, 0xD6])
        let sequence        = SequenceNumber(withCount: 3221931) //0x3129AB
        let srcAddr         = Data([0x00, 0x03])
        let dstAddr         = Data([0x12, 0x01])
        let ivIndex         = Data([0x12, 0x34, 0x56, 0x78])
        let opcode          = Data([0x00])
        let accessPDU       = AccessMessagePDU(withPayload: accessPaylod,
                                               opcode: opcode,
                                               deviceKey: deviceKey,
                                               netKey: netKey,
                                               seq: sequence,
                                               ivIndex: ivIndex,
                                               source: srcAddr,
                                               andDst: dstAddr)

        let networkLayerPDUs = [Data([0x68, 0xCA, 0xB5, 0xC5, 0x34, 0x8A, 0x23, 0x0A,
                                      0xFB, 0xA8, 0xC6, 0x3D, 0x4E, 0x68, 0x63, 0x64,
                                      0x97, 0x9D, 0xEA, 0xF4, 0xFD, 0x40, 0x96, 0x11,
                                      0x45, 0x93, 0x9C, 0xDA, 0x0E]),
                                Data([0x68, 0x16, 0x15, 0xB5, 0xDD, 0x4A, 0x84, 0x6C,
                                      0xAE, 0x0C, 0x03, 0x2B, 0xF0, 0x74, 0x6F, 0x44,
                                      0xF1, 0xB8, 0xCC, 0x8C, 0xE5, 0xED, 0xC5, 0x7E,
                                      0x55, 0xBE, 0xED, 0x49, 0xC0])]
        if let result = accessPDU.assembleNetworkPDU() {
            XCTAssert(result.count == networkLayerPDUs.count, "Expected network segments to match")
            XCTAssert(result[0] == networkLayerPDUs[0], "Expected Segment 0 to match expected result")
            XCTAssert(result[1] == networkLayerPDUs[1], "Expected Segment 1 to match expected result")
        } else {
            XCTAssert(false, "Failed to generate network PDUs")
        }
   }

    func testProxyMessageFromAPI() {
        let netKey  = Data([0xD1, 0xAA, 0xFB, 0x2A, 0x1A, 0x3C, 0x28, 0x1C,
                            0xBD, 0xB0, 0xE9, 0x60, 0xED, 0xFA, 0xD8, 0x52])
        let ivIndex = Data([0x12, 0x34, 0x56, 0x78])
        let srcAddr = Data([0x00, 0x01])
        let dstAddr = Data([0x00, 0x00])
        let expectedNetworkLayerPDUs = [Data([0x10, 0x38, 0x6B, 0xD6, 0x0E, 0xFB, 0xBB,
                                              0x8B, 0x8C, 0x28, 0x51, 0x2E, 0x79, 0x2D,
                                              0x37, 0x11, 0xF4, 0xB5, 0x26])]
        let testState = MeshState(withNodeList: [],
                                  netKey: netKey,
                                  keyIndex: Data([0x00]),
                                  IVIndex: ivIndex,
                                  globalTTL: 0x00,
                                  unicastAddress: srcAddr,
                                  flags: Data([0x00]),
                                  appKeys: [["testKey1": Data([0xBE, 0xEF])]],
                                  andName: "My test network")
        let whitelistMessage = SetFilterTypeMessage(withFilterType: MeshFilterTypes.whiteList)
        let payloads = whitelistMessage.assemblePayload(withMeshState: testState, toAddress: dstAddr)
        XCTAssert(payloads?.count == expectedNetworkLayerPDUs.count, "Incorrect number of network PDUs created")
        XCTAssert(payloads?[0] == expectedNetworkLayerPDUs[0],
                  "Expected 0x\(expectedNetworkLayerPDUs[0].hexString()), got 0x\(payloads![0].hexString())")
    }

    func testProxyMessage() {
        let controlPayload  = Data([0x00])
        let netKey          = Data([0xD1, 0xAA, 0xFB, 0x2A, 0x1A, 0x3C, 0x28, 0x1C,
                                    0xBD, 0xB0, 0xE9, 0x60, 0xED, 0xFA, 0xD8, 0x52])
        let sequence        = SequenceNumber(withCount: 1)
        let srcAddr         = Data([0x00, 0x01])
        let dstAddr         = Data([0x00, 0x00])
        let ivIndex         = Data([0x12, 0x34, 0x56, 0x78])
        let opcode          = Data([0x00])
        let controlMessage  = ControlMessagePDU(withPayload: controlPayload,
                                                opcode: opcode,
                                                netKey: netKey,
                                                seq: sequence,
                                                ivIndex: ivIndex,
                                                source: srcAddr,
                                                andDst: dstAddr)

        let networkLayerPDUs = [Data([0x10, 0x38, 0x6B, 0xD6, 0x0E, 0xFB, 0xBB, 0x8B,
                                      0x8C, 0x28, 0x51, 0x2E, 0x79, 0x2D, 0x37, 0x11,
                                      0xF4, 0xB5, 0x26])]
        if let result = controlMessage.assembleNetworkPDU() {
            XCTAssert(result.count == networkLayerPDUs.count, "Expected network segments to match")
            XCTAssert(result[0] == networkLayerPDUs[0],
                      "Expected 0x\(networkLayerPDUs[0].hexString()), got 0x\(result[0].hexString())")
        } else {
            XCTAssert(false, "Failed to generate network PDUs")
        }
    }

    func testFriendRequest() {
        let controlPayload  = Data([0x4B, 0x50, 0x05, 0x7E, 0x40, 0x00, 0x00, 0x01, 0x00, 0x00])
        let sequence        = SequenceNumber(withCount: 1)
        let srcAddr         = Data([0x12, 0x01])
        let dstAddr         = Data([0xFF, 0xFD])
        let netKey          = Data([0x7D, 0xD7, 0x36, 0x4C, 0xD8, 0x42, 0xAD, 0x18,
                                    0xC1, 0x7C, 0x2B, 0x82, 0x0C, 0x84, 0xC3, 0xD6])
        let ivIndex         = Data([0x12, 0x34, 0x56, 0x78])
        let opcode          = Data([0x03])
        let expectedNetworkLayerPDUs = [Data([0x68, 0xEC, 0xA4, 0x87, 0x51, 0x67, 0x65, 0xB5,
                                              0xE5, 0xBF, 0xDA, 0xCB, 0xAF, 0x6C, 0xB7, 0xFB,
                                              0x6B, 0xFF, 0x87, 0x1F, 0x03, 0x54, 0x44, 0xCE,
                                              0x83, 0xA6, 0x70, 0xDF])]

        let controlMessage  = ControlMessagePDU(withPayload: controlPayload, opcode: opcode,
                                                netKey: netKey, seq: sequence, ivIndex: ivIndex,
                                                source: srcAddr, andDst: dstAddr)
        if let result = controlMessage.assembleNetworkPDU() {
            XCTAssert(result.count == expectedNetworkLayerPDUs.count, "Expected network segments to match")
            XCTAssert(result[0] == expectedNetworkLayerPDUs[0],
                      "Expected 0x\(expectedNetworkLayerPDUs[0].hexString()), got 0x\(result[0].hexString())")
        } else {
            XCTAssert(false, "Failed to generate network PDUs")
        }
    }

    func testConfigAppKeyAddMessageThroughAPI() {
        let accessOpCode = Data([0x00])
        let accessPayloadData   = Data([0x56, 0x34, 0x12, 0x63, 0x96, 0x47, 0x71, 0x73, 0x4F,
                                        0xBD, 0x76, 0xE3, 0xB4, 0x05, 0x19, 0xD1, 0xD9, 0x4A, 0x48])
        let netKey              = Data([0x7D, 0xD7, 0x36, 0x4C, 0xD8, 0x42, 0xAD, 0x18,
                                        0xC1, 0x7C, 0x2B, 0x82, 0x0C, 0x84, 0xC3, 0xD6])
        let deviceKey           = Data([0x9D, 0x6D, 0xD0, 0xE9, 0x6E, 0xB2, 0x5D, 0xC1,
                                        0x9A, 0x40, 0xED, 0x99, 0x14, 0xF8, 0xF0, 0x3F])
        let sequence            = SequenceNumber(withCount: 3221931) //0x3129AB
        let ivIndex             = Data([0x12, 0x34, 0x56, 0x78])
        let srcAddr             = Data([0x00, 0x03])
        let dstAddr             = Data([0x12, 0x01])

        let expectedNetworkLayerPDUs = [
            Data([0x68, 0xCA, 0xB5, 0xC5, 0x34, 0x8A, 0x23, 0x0A, 0xFB, 0xA8, 0xC6, 0x3D, 0x4E, 0x68,
                  0x63, 0x64, 0x97, 0x9D, 0xEA, 0xF4, 0xFD, 0x40, 0x96, 0x11, 0x45, 0x93, 0x9C, 0xDA, 0x0E]),
            Data([0x68, 0x16, 0x15, 0xB5, 0xDD, 0x4A, 0x84, 0x6C, 0xAE, 0x0C, 0x03, 0x2B, 0xF0, 0x74,
                  0x6F, 0x44, 0xF1, 0xB8, 0xCC, 0x8C, 0xE5, 0xED, 0xC5, 0x7E, 0x55, 0xBE, 0xED, 0x49, 0xC0])
        ]

        let accessMessage = AccessMessagePDU(withPayload: accessPayloadData,
                                             opcode: accessOpCode,
                                             deviceKey: deviceKey,
                                             netKey: netKey,
                                             seq: sequence,
                                             ivIndex: ivIndex,
                                             source: srcAddr,
                                             andDst: dstAddr)
        let pdus = accessMessage.assembleNetworkPDU()!

        XCTAssert(pdus.count == expectedNetworkLayerPDUs.count,
                  "Expected \(expectedNetworkLayerPDUs.count) PDUS, got \(pdus.count)")
        XCTAssert(pdus[0] == expectedNetworkLayerPDUs[0],
                  "PDU 0x\(pdus[0].hexString()) did not match expected 0x\(expectedNetworkLayerPDUs[0].hexString())")
        XCTAssert(pdus[1] == expectedNetworkLayerPDUs[1],
                  "PDU 0x\(pdus[1].hexString()) did not match expected 0x\(expectedNetworkLayerPDUs[1].hexString())")
    }

    func testConfigAppKeyAddMessage() {
        let accessPayloadData   = Data([0x00, 0x56, 0x34, 0x12, 0x63, 0x96, 0x47, 0x71,
                                        0x73, 0x4F, 0xBD, 0x76, 0xE3, 0xB4, 0x05, 0x19,
                                        0xD1, 0xD9, 0x4A, 0x48])
        let ivIndex             = Data([0x12, 0x34, 0x56, 0x78])
        let deviceKey           = Data([0x9D, 0x6D, 0xD0, 0xE9, 0x6E, 0xB2, 0x5D, 0xC1,
                                        0x9A, 0x40, 0xED, 0x99, 0x14, 0xF8, 0xF0, 0x3F])
        let netKey              = Data([0x7D, 0xD7, 0x36, 0x4C, 0xD8, 0x42, 0xAD, 0x18,
                                        0xC1, 0x7C, 0x2B, 0x82, 0x0C, 0x84, 0xC3, 0xD6])
        let sequence            = SequenceNumber(withCount: 3221931) //0x3129AB
        let srcAddr             = Data([0x00, 0x03])
        let dstAddr             = Data([0x12, 0x01])

        let expectedNetworkLayerPDUs = [
            Data([0x68, 0xCA, 0xB5, 0xC5, 0x34, 0x8A, 0x23, 0x0A, 0xFB, 0xA8, 0xC6, 0x3D, 0x4E, 0x68,
                  0x63, 0x64, 0x97, 0x9D, 0xEA, 0xF4, 0xFD, 0x40, 0x96, 0x11, 0x45, 0x93, 0x9C, 0xDA, 0x0E]),
            Data([0x68, 0x16, 0x15, 0xB5, 0xDD, 0x4A, 0x84, 0x6C, 0xAE, 0x0C, 0x03, 0x2B, 0xF0, 0x74,
                  0x6F, 0x44, 0xF1, 0xB8, 0xCC, 0x8C, 0xE5, 0xED, 0xC5, 0x7E, 0x55, 0xBE, 0xED, 0x49, 0xC0])
        ]

        let nonce = TransportNonce(deviceNonceWithIVIndex: ivIndex, isSegmented: true,
                                   szMIC: 0, seq: sequence.sequenceData(),
                                   src: srcAddr, dst: dstAddr)
        let upperParams = UpperTransportPDUParams(withPayload: accessPayloadData, opcode: Data([0x00]),
                                                  IVIndex: ivIndex, key: deviceKey, ttl: Data([0x04]),
                                                  seq: sequence, src: srcAddr, dst: dstAddr,
                                                  nonce: nonce, ctl: false, afk: false, aid: Data([0x00]))
        let upperTrans = UpperTransportLayer(withParams: upperParams)
        let lowerParams = LowerTransportPDUParams(withUpperTransportData: upperTrans.encrypt()!,
                                                  ttl: Data([0x04]), ctl: Data([0x00]),
                                                  ivIndex: ivIndex, sequenceNumber: sequence,
                                                  sourceAddress: srcAddr, destinationAddress: dstAddr,
                                                  micSize: Data([0x00]), afk: Data([0x00]),
                                                  aid: Data([0x00]), andOpcode: Data([0x00]))
        let lowerLayer = LowerTransportLayer(withParams: lowerParams)
        let netLayer = NetworkLayer(withLowerTransportLayer: lowerLayer, andNetworkKey: netKey)
        let pdus = netLayer.createPDU()
        XCTAssert(pdus.count == expectedNetworkLayerPDUs.count,
                  "Expected \(expectedNetworkLayerPDUs.count) network PDUS, got \(pdus.count)")
        XCTAssert(pdus[0] == expectedNetworkLayerPDUs[0],
                  "PDU 0x\(pdus[0].hexString()) did not match expected 0x\(expectedNetworkLayerPDUs[0].hexString())")
        XCTAssert(pdus[1] == expectedNetworkLayerPDUs[1],
                  "PDU 0x\(pdus[1].hexString()) did not match expected 0x\(expectedNetworkLayerPDUs[1].hexString())")
    }
}
