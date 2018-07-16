//
//  NetrokLayerTests.swift
//  nRFMeshProvision_Tests
//
//  Created by Mostafa Berg on 26/02/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
import nRFMeshProvision

class UpperLayerTests: XCTestCase {

    func testUpperTransportEncryption() {
        //Test input
        let testAccessPayload = Data([0x00, 0x56, 0x34, 0x12, 0x63, 0x96, 0x47, 0x71, 0x73, 0x4F,
                                      0xBD, 0x76, 0xE3, 0xB4, 0x05, 0x19, 0xD1, 0xD9, 0x4A, 0x48])
        let testIVIndex = Data([0x12, 0x34, 0x56, 0x78])
        let testDeviceKey = Data([0x9D, 0x6D, 0xD0, 0xE9, 0x6E, 0xB2, 0x5D, 0xC1,
                                  0x9A, 0x40, 0xED, 0x99, 0x14, 0xF8, 0xF0, 0x3F])
        let testTTL = Data([0x04])
        let testSequence = SequenceNumber(withCount: 3221931) //0x3129AB
        let testSrc = Data([0x00, 0x03])
        let testDst = Data([0x12, 0x01])
        let testNonce = TransportNonce(deviceNonceWithIVIndex: testIVIndex,
                                       isSegmented: false,
                                       szMIC: 0,
                                       seq: testSequence.sequenceData(),
                                       src: testSrc,
                                       dst: testDst)
        let testOpcode = Data([0x00])

        let params = UpperTransportPDUParams(withPayload: testAccessPayload,
                                             opcode: testOpcode,
                                             IVIndex: testIVIndex,
                                             key: testDeviceKey,
                                             ttl: testTTL,
                                             seq: testSequence,
                                             src: testSrc,
                                             dst: testDst,
                                             nonce: testNonce,
                                             ctl: true,
                                             afk: false, aid: Data([0x00]))
        //expected ouptuts
        let expectedEncryptedData = Data([0xEE, 0x9D, 0xDD, 0xFD, 0x21, 0x69, 0x32, 0x6D,
                                          0x23, 0xF3, 0xAF, 0xDF, 0xCF, 0xDC, 0x18, 0xC5,
                                          0x2F, 0xDE, 0xF7, 0x72, 0xE0, 0xE1, 0x73, 0x08])
        let testTransportLayer = UpperTransportLayer(withParams: params)
        guard let encData = testTransportLayer.encrypt() else {
            XCTAssert(false, "Encrypted data was not generated")
            return
        }
        XCTAssert(encData == expectedEncryptedData, "Encrypted data + MIC did not match expected value")
    }

    func testUpperLayerFriendRequest() {
        let controlPayload  = Data([0x4B, 0x50, 0x05, 0x7E, 0x40, 0x00, 0x00, 0x01, 0x00, 0x00])
        let sequence        = SequenceNumber(withCount: 1)
        let srcAddr         = Data([0x12, 0x01])
        let dstAddr         = Data([0xFF, 0xFD])
        let netKey          = Data([0x7D, 0xD7, 0x36, 0x4C, 0xD8, 0x42, 0xAD, 0x18,
                                    0xC1, 0x7C, 0x2B, 0x82, 0x0C, 0x84, 0xC3, 0xD6])
        let ivIndex         = Data([0x12, 0x34, 0x56, 0x78])
        let opcode          = Data([0x00])
        let testNonce = TransportNonce(deviceNonceWithIVIndex: ivIndex,
                                       isSegmented: false,
                                       szMIC: 0,
                                       seq: sequence.sequenceData(),
                                       src: srcAddr,
                                       dst: dstAddr)
        let expectedPDU = Data([0x4B, 0x50, 0x05, 0x7E, 0x40, 0x00, 0x00, 0x01, 0x00, 0x00])

        let upperParams = UpperTransportPDUParams(withPayload: controlPayload,
                                                  opcode: opcode,
                                                  IVIndex: ivIndex,
                                                  key: netKey,
                                                  ttl: Data([0x00]),
                                                  seq: sequence,
                                                  src: srcAddr,
                                                  dst: dstAddr,
                                                  nonce: testNonce,
                                                  ctl: true,
                                                  afk: false,
                                                  aid: Data([0x00]))

        let upperTransportLayer = UpperTransportLayer(withParams: upperParams)
        XCTAssert(expectedPDU == upperTransportLayer.rawData()!, "EXpected upper PDU did not match")
    }
}
