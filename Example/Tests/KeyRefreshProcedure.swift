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

class KeyRefreshProcedure: XCTestCase {
    let key     = Data(hex: "00112233445566778899AABBCCDDEEFF")
    let newKey  = Data(hex: "FFEEDDCCBBAA99887766554433221100")
    let ivIndex = IvIndex(index: 2, updateActive: false)
    let seq     = UInt32(123)
    let ttl     = UInt8(5)
    
    var networkKey: NetworkKey!
    var controlMessage: ControlMessage!
    
    let pduEncodedUsingOldKey = Data(hex: "1E33F32EA453EAAB346A44BBC3E761667272FD")
    let pduEncodedUsingNewKey = Data(hex: "582B063460750280DF9244AA90E637A345E3C3")
    
    override func setUpWithError() throws {
        networkKey = try NetworkKey(name: "Test Key", index: 0, key: key)
        
        let filter = SetFilterType(.acceptList)
        controlMessage = ControlMessage(fromProxyConfigurationMessage: filter, sentFrom: 0x0001,
                                        usingNetworkKey: networkKey, andIvIndex: ivIndex)
    }

    func testNetworkKey_NormalOperation() throws {
        XCTAssertEqual(networkKey.phase, .normalOperation)
        XCTAssertEqual(networkKey.index, 0)
        XCTAssertEqual(networkKey.key, key)
        // Validate key derivatives.
        XCTAssertNotNil(networkKey.keys)
        XCTAssertEqual(networkKey.keys.nid,           0x1E)
        XCTAssertEqual(networkKey.keys.beaconKey,     Data(hex: "44F5E91B3F2B9EE2D1C6023D2A57F1F3"))
        XCTAssertEqual(networkKey.keys.encryptionKey, Data(hex: "EAA68445FFA4F38F96F2CCC5CC16119C"))
        XCTAssertEqual(networkKey.keys.identityKey,   Data(hex: "C7BBF25E84C88EFDE1AF24231A7B90E6"))
        XCTAssertEqual(networkKey.keys.privacyKey,    Data(hex: "33F2DDDEFD05965A2FF862DDCBF8298C"))
        XCTAssertEqual(networkKey.networkId,          Data(hex: "1FBD2C61A4B6E5A4"))
        // Old key should be nil.
        XCTAssertNil(networkKey.oldKey)
        XCTAssertNil(networkKey.oldKeys)
        XCTAssertNil(networkKey.oldNetworkId)
        
        // In Normal Operation the single key should be used.
        XCTAssertEqual(networkKey.keys.encryptionKey, networkKey.transmitKeys.encryptionKey)
        
        // Test whether a message is using the right key.
        let networkPdu = NetworkPdu(encode: controlMessage, ofType: .proxyConfiguration,
                                    withSequence: seq, andTtl: ttl)
        XCTAssertEqual(networkPdu.pdu, pduEncodedUsingOldKey)
        
        // Test whether the message can be decoded.
        let decodedUsingOldKey = NetworkPdu(decode: pduEncodedUsingOldKey, ofType: .proxyConfiguration,
                                            usingNetworkKey: networkKey, andIvIndex: ivIndex)
        XCTAssertNotNil(decodedUsingOldKey)
        let decodedUsingNewKey = NetworkPdu(decode: pduEncodedUsingNewKey, ofType: .proxyConfiguration,
                                            usingNetworkKey: networkKey, andIvIndex: ivIndex)
        XCTAssertNil(decodedUsingNewKey)
    }
    
    func testNetworkKey_KeyDistribution() throws {
        networkKey.key = newKey
        
        XCTAssertEqual(networkKey.phase, .keyDistribution)
        XCTAssertEqual(networkKey.index, 0)
        XCTAssertEqual(networkKey.key, newKey)
        XCTAssertEqual(networkKey.oldKey, key)
        // Validate key derivatives.
        XCTAssertNotNil(networkKey.keys)
        XCTAssertEqual(networkKey.keys.nid,           0x58)
        XCTAssertEqual(networkKey.keys.beaconKey,     Data(hex: "4D7D24E397FB4FB930D1695F6E91924F"))
        XCTAssertEqual(networkKey.keys.encryptionKey, Data(hex: "BA418775923B2F19C72ED87A74874E46"))
        XCTAssertEqual(networkKey.keys.identityKey,   Data(hex: "0D51723D16362AC90CC85BDA18E793C8"))
        XCTAssertEqual(networkKey.keys.privacyKey,    Data(hex: "60567E5C26BB4F91C421A382AA48C38F"))
        XCTAssertEqual(networkKey.networkId,          Data(hex: "B06E4580BA6419CE"))
        // The key should be stored as old key.
        XCTAssertNotNil(networkKey.oldKeys)
        XCTAssertEqual(networkKey.oldKeys!.nid,           0x1E)
        XCTAssertEqual(networkKey.oldKeys!.beaconKey,     Data(hex: "44F5E91B3F2B9EE2D1C6023D2A57F1F3"))
        XCTAssertEqual(networkKey.oldKeys!.encryptionKey, Data(hex: "EAA68445FFA4F38F96F2CCC5CC16119C"))
        XCTAssertEqual(networkKey.oldKeys!.identityKey,   Data(hex: "C7BBF25E84C88EFDE1AF24231A7B90E6"))
        XCTAssertEqual(networkKey.oldKeys!.privacyKey,    Data(hex: "33F2DDDEFD05965A2FF862DDCBF8298C"))
        XCTAssertEqual(networkKey.oldNetworkId,           Data(hex: "1FBD2C61A4B6E5A4"))
        
        // In Key Distribution the old key should be used.
        XCTAssertEqual(networkKey.oldKeys!.encryptionKey, networkKey.transmitKeys.encryptionKey)
        
        // Test whether a message is using the right key.
        let networkPdu = NetworkPdu(encode: controlMessage, ofType: .proxyConfiguration,
                                    withSequence: seq, andTtl: 5)
        XCTAssertEqual(networkPdu.pdu, pduEncodedUsingOldKey)
        
        // Test whether the message can be decoded.
        let decodedUsingOldKey = NetworkPdu(decode: pduEncodedUsingOldKey, ofType: .proxyConfiguration,
                                            usingNetworkKey: networkKey, andIvIndex: ivIndex)
        XCTAssertNotNil(decodedUsingOldKey)
        let decodedUsingNewKey = NetworkPdu(decode: pduEncodedUsingNewKey, ofType: .proxyConfiguration,
                                            usingNetworkKey: networkKey, andIvIndex: ivIndex)
        XCTAssertNotNil(decodedUsingNewKey)
    }
    
    func testNetworkKey_UsingNewKeys() throws {
        networkKey.key = newKey
        networkKey.phase = .usingNewKeys
        
        XCTAssertEqual(networkKey.phase, .usingNewKeys)
        XCTAssertEqual(networkKey.index, 0)
        XCTAssertEqual(networkKey.key, newKey)
        XCTAssertEqual(networkKey.oldKey, key)
        // Validate key derivatives.
        XCTAssertNotNil(networkKey.keys)
        XCTAssertEqual(networkKey.keys.nid,           0x58)
        XCTAssertEqual(networkKey.keys.beaconKey,     Data(hex: "4D7D24E397FB4FB930D1695F6E91924F"))
        XCTAssertEqual(networkKey.keys.encryptionKey, Data(hex: "BA418775923B2F19C72ED87A74874E46"))
        XCTAssertEqual(networkKey.keys.identityKey,   Data(hex: "0D51723D16362AC90CC85BDA18E793C8"))
        XCTAssertEqual(networkKey.keys.privacyKey,    Data(hex: "60567E5C26BB4F91C421A382AA48C38F"))
        XCTAssertEqual(networkKey.networkId,          Data(hex: "B06E4580BA6419CE"))
        // The key should be stored as old key.
        XCTAssertNotNil(networkKey.oldKeys)
        XCTAssertEqual(networkKey.oldKeys!.nid,           0x1E)
        XCTAssertEqual(networkKey.oldKeys!.beaconKey,     Data(hex: "44F5E91B3F2B9EE2D1C6023D2A57F1F3"))
        XCTAssertEqual(networkKey.oldKeys!.encryptionKey, Data(hex: "EAA68445FFA4F38F96F2CCC5CC16119C"))
        XCTAssertEqual(networkKey.oldKeys!.identityKey,   Data(hex: "C7BBF25E84C88EFDE1AF24231A7B90E6"))
        XCTAssertEqual(networkKey.oldKeys!.privacyKey,    Data(hex: "33F2DDDEFD05965A2FF862DDCBF8298C"))
        XCTAssertEqual(networkKey.oldNetworkId,           Data(hex: "1FBD2C61A4B6E5A4"))
        
        // In Using New Keys phase the new key should be used.
        XCTAssertEqual(networkKey.keys.encryptionKey, networkKey.transmitKeys.encryptionKey)
        
        // Test whether a message is using the right key.
        let networkPdu = NetworkPdu(encode: controlMessage, ofType: .proxyConfiguration,
                                    withSequence: seq, andTtl: ttl)
        XCTAssertEqual(networkPdu.pdu, pduEncodedUsingNewKey)
        
        // Test whether the message can be decoded.
        let decodedUsingOldKey = NetworkPdu(decode: pduEncodedUsingOldKey, ofType: .proxyConfiguration,
                                            usingNetworkKey: networkKey, andIvIndex: ivIndex)
        XCTAssertNotNil(decodedUsingOldKey)
        let decodedUsingNewKey = NetworkPdu(decode: pduEncodedUsingNewKey, ofType: .proxyConfiguration,
                                            usingNetworkKey: networkKey, andIvIndex: ivIndex)
        XCTAssertNotNil(decodedUsingNewKey)
    }
    
    func testNetworkKey_KeysRevoked() throws {
        networkKey.key = newKey
        networkKey.phase = .usingNewKeys
        networkKey.oldKey = nil
        
        XCTAssertEqual(networkKey.phase, .normalOperation)
        XCTAssertEqual(networkKey.index, 0)
        XCTAssertEqual(networkKey.key, newKey)
        // Validate key derivatives.
        XCTAssertNotNil(networkKey.keys)
        XCTAssertEqual(networkKey.keys.nid,           0x58)
        XCTAssertEqual(networkKey.keys.beaconKey,     Data(hex: "4D7D24E397FB4FB930D1695F6E91924F"))
        XCTAssertEqual(networkKey.keys.encryptionKey, Data(hex: "BA418775923B2F19C72ED87A74874E46"))
        XCTAssertEqual(networkKey.keys.identityKey,   Data(hex: "0D51723D16362AC90CC85BDA18E793C8"))
        XCTAssertEqual(networkKey.keys.privacyKey,    Data(hex: "60567E5C26BB4F91C421A382AA48C38F"))
        XCTAssertEqual(networkKey.networkId,          Data(hex: "B06E4580BA6419CE"))
        // Old keys should be revoked now.
        XCTAssertNil(networkKey.oldKey)
        XCTAssertNil(networkKey.oldKeys)
        XCTAssertNil(networkKey.oldNetworkId)
        
        // In Normal Operation the single key should be used.
        XCTAssertEqual(networkKey.keys.encryptionKey, networkKey.transmitKeys.encryptionKey)
        
        // Test whether a message is using the right key.
        let networkPdu = NetworkPdu(encode: controlMessage, ofType: .proxyConfiguration,
                                    withSequence: seq, andTtl: 5)
        XCTAssertEqual(networkPdu.pdu, pduEncodedUsingNewKey)
        
        // Test whether the message can be decoded.
        let decodedUsingOldKey = NetworkPdu(decode: pduEncodedUsingOldKey, ofType: .proxyConfiguration,
                                            usingNetworkKey: networkKey, andIvIndex: ivIndex)
        XCTAssertNil(decodedUsingOldKey)
        let decodedUsingNewKey = NetworkPdu(decode: pduEncodedUsingNewKey, ofType: .proxyConfiguration,
                                            usingNetworkKey: networkKey, andIvIndex: ivIndex)
        XCTAssertNotNil(decodedUsingNewKey)
    }

}
