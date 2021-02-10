/*
* Copyright (c) 2021, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

import XCTest
@testable import nRFMeshProvision

class CryptoTest: XCTestCase {
    let data     = Data(hex: "00112233445566778899AABBCCDDEEFF")
    let key      = Data(hex: "0123456789ABCDEF0123456789ABCDEF")
    let nonce    = Data(hex: "00112233445566778899AABBCC")
    let label    = UUID(uuidString: "12345678-1234-1234-1234-12345678ABCD")!

    func testRandom() throws {
        let random = Crypto.generateRandom()
        
        XCTAssertEqual(random.count, 16)
    }

    func testVirtualLabel() throws {
        let expected = Address(0xADD5)
        
        let result = Crypto.calculateVirtualAddress(from: label)
        XCTAssertEqual(result, expected)
    }
    
    func testEncryption_MIC4() throws {
        let expected = Data(hex: "6C7854C1E573CD62155BFA987C70673D273AB343")
        
        // Encode
        let result = Crypto.encrypt(data, withEncryptionKey: key, nonce: nonce, andMICSize: 4,
                                    withAdditionalData: nil)
        XCTAssertEqual(result, expected)
        
        // Decode
        let encrypted = result.subdata(in: 0..<data.count)
        let mic       = result.subdata(in: data.count..<result.count)
        let test = Crypto.decrypt(encrypted, withEncryptionKey: key, nonce: nonce,
                                  andMIC: mic, withAdditionalData: nil)
        XCTAssertEqual(test, data)
    }
    
    func testEncryption_MIC8() throws {
        let expected = Data(hex: "6C7854C1E573CD62155BFA987C70673D5CFCB5AC7E3CEA62")
        
        // Encode
        let result = Crypto.encrypt(data, withEncryptionKey: key, nonce: nonce, andMICSize: 8,
                                    withAdditionalData: nil)
        XCTAssertEqual(result, expected)
        
        // Decode
        let encrypted = result.subdata(in: 0..<data.count)
        let mic       = result.subdata(in: data.count..<result.count)
        let test = Crypto.decrypt(encrypted, withEncryptionKey: key, nonce: nonce,
                                  andMIC: mic, withAdditionalData: nil)
        XCTAssertEqual(test, data)
    }
    
    func testEncryption_MIC4_withAdditionalData() throws {
        let expected = Data(hex: "6C7854C1E573CD62155BFA987C70673D19F0C64D")
        
        // Encode
        let result = Crypto.encrypt(data, withEncryptionKey: key, nonce: nonce, andMICSize: 4,
                                    withAdditionalData: label.data)
        XCTAssertEqual(result, expected)
        
        // Decode
        let encrypted = result.subdata(in: 0..<data.count)
        let mic       = result.subdata(in: data.count..<result.count)
        let test = Crypto.decrypt(encrypted, withEncryptionKey: key, nonce: nonce,
                                  andMIC: mic, withAdditionalData: label.data)
        XCTAssertEqual(test, data)
    }
    
    func testEncryption_MIC8_withAdditionalData() throws {
        let expected = Data(hex: "6C7854C1E573CD62155BFA987C70673D37D0CC6CAEF67CFC")
        
        // Encode
        let result = Crypto.encrypt(data, withEncryptionKey: key, nonce: nonce, andMICSize: 8,
                                    withAdditionalData: label.data)
        XCTAssertEqual(result, expected)
        
        // Decode
        let encrypted = result.subdata(in: 0..<data.count)
        let mic       = result.subdata(in: data.count..<result.count)
        let test = Crypto.decrypt(encrypted, withEncryptionKey: key, nonce: nonce,
                                  andMIC: mic, withAdditionalData: label.data)
        XCTAssertEqual(test, data)
    }
    
    func testObfuscation() throws {
        let source   = Data(hex: "050102030001")
        let random   = Data(hex: "00112233445566")
        let ivIndex  = UInt32(0x12345678)
        let expected = Data(hex: "9C0DAE8BC512")
        
        // Obfuscate
        let obfuscated = Crypto.obfuscate(source, usingPrivacyRandom: random,
                                          ivIndex: ivIndex, andPrivacyKey: key)
        XCTAssertEqual(obfuscated, expected)
        
        // Deobfuscate
        let deobfuscated = Crypto.obfuscate(obfuscated, usingPrivacyRandom: random,
                                            ivIndex: ivIndex, andPrivacyKey: key)
        XCTAssertEqual(deobfuscated, source)
    }
    
    func testKeyDerivatives() throws {
        let key = Data(hex: "f7a2a44f8e8a8029064f173ddc1e2b00")
        
        let expectedNID           = UInt8(0x7F)
        let expectedEncryptionKey = Data(hex: "9f589181a0f50de73c8070c7a6d27f46")
        let expectedPrivacyKey    = Data(hex: "4c715bd4a64b938f99b453351653124f")
        let expectedIdentityKey   = Data(hex: "877DE1A131C87A8C6767E655061963A7")
        let expectedBeaconKey     = Data(hex: "CCAE3C53A3BB6FAB728EE94A390DC91F")
        
        let (n, e, p, i, b) = Crypto.calculateKeyDerivatives(from: key)
        XCTAssertEqual(n, expectedNID)
        XCTAssertEqual(e, expectedEncryptionKey)
        XCTAssertEqual(p, expectedPrivacyKey)
        XCTAssertEqual(i, expectedIdentityKey)
        XCTAssertEqual(b, expectedBeaconKey)
    }
    
    func testNetworkId() throws {
        let key = Data(hex: "f7a2a44f8e8a8029064f173ddc1e2b00")
        
        let expected = Data(hex: "ff046958233db014")
        
        let k3 = Crypto.calculateNetworkId(from: key)
        XCTAssertEqual(k3, expected)
    }
    
    func testAid() throws {
        let key = Data(hex: "3216d1509884b533248541792b877f98")
        
        let expectedAID = UInt8(0x38)
        
        let k4 = Crypto.calculateAid(from: key)
        XCTAssertEqual(k4, expectedAID)
    }
    
}
