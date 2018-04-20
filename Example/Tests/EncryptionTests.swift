import UIKit
import XCTest
import nRFMeshProvision

class EncryptionTests: XCTestCase {

    func testPECB() {
        let testPrivacyRandom = Data(bytes: [0x00, 0x00, 0x00, 0x00, 0x00, 0x12, 0x34, 0x56,
                                             0x78, 0xB0, 0xE5, 0xD0, 0xAD, 0x97, 0x0D, 0x57])
        let testPrivacyKey    = Data(bytes: [0x5D, 0x39, 0x6D, 0x4B, 0x54, 0xD3, 0xCB, 0xAF,
                                             0xE9, 0x43, 0xE0, 0x51, 0xFE, 0x9A, 0x4E, 0xB8])
        let testOutput        = Data(bytes: [0x04, 0xEB, 0xA0, 0x90, 0x2A, 0x0E])
        let helper            = OpenSSLHelper()
        var output            = helper.calculateEvalue(with: testPrivacyRandom, andKey: testPrivacyKey)
        output = output![0..<6]
        XCTAssert(output == testOutput,
                  "Expected \(testOutput.hexString()), got: \(output!.hexString())")
    }

    func testObfuscation() {
        let testInputENCPDU     = Data(bytes: [0x0D, 0x0D, 0x73, 0x0F, 0x94, 0xD7, 0xF3, 0x50, 0x9D])
        let testInputCTLTTL     = Data(bytes: [0x8B])
        let testInputSequence   = Data(bytes: [0x01, 0x48, 0x35])
        let testIVIndex         = Data(bytes: [0x12, 0x34, 0x56, 0x78])
        let testPrivacyKey      = Data(bytes: [0x8B, 0x84, 0xEE, 0xDE, 0xC1, 0x00, 0x06, 0x7D, 0x67,
                                               0x09, 0x71, 0xDD, 0x2A, 0xA7, 0x00, 0xCF])
        let testSrcAddress      = Data(bytes: [0x23, 0x45])
        let testOutput          = Data(bytes: [0xE4, 0x76, 0xB5, 0x57, 0x9C, 0x98])
        let helper              = OpenSSLHelper()
        let output = helper.obfuscateENCPDU(testInputENCPDU,
                                            cTLTTLValue: testInputCTLTTL,
                                            sequenceNumber: testInputSequence,
                                            ivIndex: testIVIndex,
                                            privacyKey: testPrivacyKey,
                                            andsrcAddr: testSrcAddress)
        XCTAssert(output == testOutput,
                  "Obfuscated header mismatch!, expected: \(testOutput.hexString()), got \(output!.hexString())")
    }

    func testK1() {
        let helper      = OpenSSLHelper()
        //Test input data.
        let nValueData  = Data(bytes: [0x32, 0x16, 0xD1, 0x50, 0x98, 0x84, 0xB5, 0x33,
                                       0x24, 0x85, 0x41, 0x79, 0x2B, 0x87, 0x7F, 0x98])
        let saltValueData  = Data(bytes: [0x2B, 0xA1, 0x4F, 0xFA, 0x0D, 0xF8, 0x4A, 0x28,
                                          0x31, 0x93, 0x8D, 0x57, 0xD2, 0x76, 0xCA, 0xB4])
        let pValueData  = Data(bytes: [0x5A, 0x09, 0xD6, 0x07, 0x97, 0xEE, 0xB4, 0x47,
                                       0x8A, 0xAD, 0xA5, 0x9D, 0xB3, 0x35, 0x2A, 0x0D])
        //Test output data.
        let expectedOutput = Data(bytes: [0xF6, 0xED, 0x15, 0xA8, 0x93, 0x4A, 0xFB, 0xE7,
                                          0xD8, 0x3E, 0x8D, 0xCB, 0x57, 0xFC, 0xF5, 0xD7])
        //Run test
        let result = helper.calculateK1(withN: nValueData, salt: saltValueData, andP: pValueData)
        //Assert result
        XCTAssert(result! == expectedOutput,
                  "Expected 0x\(expectedOutput.hexString()), got 0x\(result!.hexString()) instead")
    }

    func testK2() {
        let helper      = OpenSSLHelper()
        //Test input data.
        let nValueData  = Data(bytes: [0xf7, 0xa2, 0xa4, 0x4f, 0x8e, 0x8a, 0x80, 0x29,
                                       0x06, 0x4f, 0x17, 0x3d, 0xdc, 0x1e, 0x2b, 0x00])
        let pValueData  = Data(bytes: [0x00])
        //Test output data.
        let expectedOutput = Data(bytes: [0x7F, 0x9F, 0x58, 0x91, 0x81, 0xA0, 0xF5, 0x0D,
                                          0xE7, 0x3C, 0x80, 0x70, 0xC7, 0xA6, 0xD2, 0x7F,
                                          0x46, 0x4C, 0x71, 0x5B, 0xD4, 0xA6, 0x4B, 0x93,
                                          0x8F, 0x99, 0xB4, 0x53, 0x35, 0x16, 0x53, 0x12,
                                          0x4F])
        //Run test
        let result      = helper.calculateK2(withN: nValueData, andP: pValueData)
        //Assert result
        XCTAssert(result! == expectedOutput,
                  "Incorrect output, expected 0x\(expectedOutput.hexString()), got 0x\(result!.hexString()) instead")
    }

    func testK3() {
        let helper      = OpenSSLHelper()
        //Test input data.
        let nValueData = Data(bytes: [0xF7, 0xA2, 0xA4, 0x4F, 0x8E, 0x8A, 0x80, 0x29,
                                      0x06, 0x4F, 0x17, 0x3D, 0xDC, 0x1E, 0x2B, 0x00])
        //Test output data.
        let expectedOutput = Data(bytes: [0xFF, 0x04, 0x69, 0x58, 0x23, 0x3D, 0xB0, 0x14])
        //Run test
        let result = helper.calculateK3(withN: nValueData)
        //Assert result
        XCTAssert(result! == expectedOutput,
                  "Expected 0x\(expectedOutput.hexString()), got 0x\(result!.hexString()) instead")
    }

    func testK4() {
        let helper = OpenSSLHelper()
        //Test input data.
        let nValueData = Data(bytes: [0x32, 0x16, 0xD1, 0x50, 0x98, 0x84, 0xB5, 0x33,
                                      0x24, 0x85, 0x41, 0x79, 0x2B, 0x87, 0x7F, 0x98])
        //Test output data.
        let expectedOutput = Data(bytes: [0x38])
        //Run test
        let result = helper.calculateK4(withN: nValueData)
        //Assert result
        XCTAssert(result! == expectedOutput,
                  "Expected 0x\(expectedOutput.hexString()), got 0x\(result!.hexString()) instead")
    }
}
