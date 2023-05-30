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
        let random_16 = Crypto.generateRandom(sizeInBits: 128)
        XCTAssertEqual(random_16.count, 16)
        
        let random_32 = Crypto.generateRandom(sizeInBits: 256)
        XCTAssertEqual(random_32.count, 32)
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
        
        let expectedNID              = UInt8(0x7F)
        let expectedEncryptionKey    = Data(hex: "9f589181a0f50de73c8070c7a6d27f46")
        let expectedPrivacyKey       = Data(hex: "4c715bd4a64b938f99b453351653124f")
        let expectedIdentityKey      = Data(hex: "877DE1A131C87A8C6767E655061963A7")
        let expectedBeaconKey        = Data(hex: "CCAE3C53A3BB6FAB728EE94A390DC91F")
        let expectedPrivateBeaconKey = Data(hex: "6be76842460b2d3a5850d4698409f1bb")
        
        let (nid, ek, pk, ik, bk, pbk) = Crypto.calculateKeyDerivatives(from: key)
        XCTAssertEqual(nid, expectedNID)
        XCTAssertEqual(ek,  expectedEncryptionKey)
        XCTAssertEqual(pk,  expectedPrivacyKey)
        XCTAssertEqual(ik,  expectedIdentityKey)
        XCTAssertEqual(bk,  expectedBeaconKey)
        XCTAssertEqual(pbk, expectedPrivateBeaconKey)
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
    
    // Test based on Provisioning Sample Data 8.4.6.1 from Mesh Profile 1.1.
    func testPrivateBeacon_IVUpdateInProgress() throws {
        let privateBeaconPdu = Data(hex: "02435f18f85cf78a3121f58478a561e488e7cbf3174f022a514741")
        let key = Data(hex: "6be76842460b2d3a5850d4698409f1bb")
        
        // Deobfuscate and authenticate the Private beacon.
        let privateBeaconData = Crypto.decodeAndAuthenticate(privateBeacon: privateBeaconPdu, usingPrivateBeaconKey: key)
        
        XCTAssertNotNil(privateBeaconData)
        XCTAssertEqual(privateBeaconData?.keyRefreshFlag, false)
        XCTAssertEqual(privateBeaconData?.ivIndex.updateActive, true)
        XCTAssertEqual(privateBeaconData?.ivIndex.index, 0x1010abcd)
    }
    
    // Test based on Provisioning Sample Data 8.4.6.2 from Mesh Profile 1.1.
    func testPrivateBeacon_IVUpdateComplete() throws {
        let privateBeaconPdu = Data(hex: "021b998f82927535ea6f3076f422ce827408ab2f0ffb94cf97f881")
        let key = Data(hex: "ca478cdac626b7a8522d7272dd124f26")
        
        // Deobfuscate and authenticate the Private beacon.
        let privateBeaconData = Crypto.decodeAndAuthenticate(privateBeacon: privateBeaconPdu, usingPrivateBeaconKey: key)
        
        XCTAssertNotNil(privateBeaconData)
        XCTAssertEqual(privateBeaconData?.keyRefreshFlag, false)
        XCTAssertEqual(privateBeaconData?.ivIndex.updateActive, false)
        XCTAssertEqual(privateBeaconData?.ivIndex.index, 0x00000000)
    }
    
    // Test based on Provisioning Sample Data 8.4.6.2 from Mesh Profile 1.1, with modified Authentication Tag.
    func testPrivateBeacon_Invalid() throws {
        let privateBeaconPdu = Data(hex: "021b998f82927535ea6f3076f422ce827408ab0123456789ABCDEF")
        let key = Data(hex: "ca478cdac626b7a8522d7272dd124f26")
        
        // Deobfuscate and authenticate the Private beacon.
        let privateBeaconData = Crypto.decodeAndAuthenticate(privateBeacon: privateBeaconPdu, usingPrivateBeaconKey: key)
        
        XCTAssertNil(privateBeaconData)
    }
    
    // Test based on Provisioning Sample Data 8.17.1 and 8.17.2 from Mesh Profile 1.1.
    func testCalculatingSharedSecret() throws {
        // Received Public Key (X + Y)
        let provisionerPublicKey = Data(hex: "2c31a47b5779809ef44cb5eaaf5c3e43d5f8faad4a8794cb987e9b03745c78dd919512183898dfbecd52e2408e43871fd021109117bd3ed4eaf8437743715d4f")
        // Known Private and Public Keys
        let provisioneePublicKey = Data(hex: "f465e43ff23d3f1b9dc7dfc04da8758184dbc966204796eccf0d6cf5e16500cc0201d048bcbbd899eeefc424164e33c201c2b010ca6b4d43a8a155cad8ecb279")
        let provisioneePrivateKey = Data(hex: "529aa0670d72cd6497502ed473502b037e8803b5c60829a5a3caa219505530ba")
        
        // Convert Provisionee Private key from Data to SecKey.
        let parameters = [kSecAttrKeyType : kSecAttrKeyTypeECSECPrimeRandom,
                    kSecAttrKeySizeInBits : 256,
                          kSecAttrKeyClass: kSecAttrKeyClassPrivate] as [CFString : Any] as CFDictionary
        
        var error: Unmanaged<CFError>?
        let secKey = SecKeyCreateWithData(Data([0x04]) + provisioneePublicKey + provisioneePrivateKey as CFData, parameters, &error)
        XCTAssertNil(error)
        guard error == nil else {
            throw error!.takeRetainedValue()
        }
        
        // Calculate the Shared Secret using Provisionee Private Key and Provisioner Public Key.
        let secret = try Crypto.calculateSharedSecret(privateKey: secKey!, publicKey: provisionerPublicKey)
        
        // Verify the Shared Secret.
        let expectedSecret = Data(hex: "ab85843a2f6d883f62e5684b38e307335fe6e1945ecd19604105c6f23221eb69")
        XCTAssertEqual(secret, expectedSecret)
    }
    
    // Test based on Provisioning Sample Data 8.17.1 from Mesh Profile 1.1.
    func testCalculatingConfirmationValuesUsingCMAC_AES128() throws {
        // Data required to for ConfirmationInputs.
        let provisioningInvite = Data(hex: "00")
        let provisioningCapabilities = Data(hex: "0100010000000000000000")
        let provisioningStart = Data(hex: "0000000000")
        let provisionerPublicKey = Data(hex: "2c31a47b5779809ef44cb5eaaf5c3e43d5f8faad4a8794cb987e9b03745c78dd919512183898dfbecd52e2408e43871fd021109117bd3ed4eaf8437743715d4f")
        let provisioneePublicKey = Data(hex: "f465e43ff23d3f1b9dc7dfc04da8758184dbc966204796eccf0d6cf5e16500cc0201d048bcbbd899eeefc424164e33c201c2b010ca6b4d43a8a155cad8ecb279")
        
        // Create Confirmation Inputs.
        let confirmationInputs = provisioningInvite + provisioningCapabilities + provisioningStart + provisionerPublicKey + provisioneePublicKey
        
        // AuthValue is `.noOob`.
        let authValue = Data(hex: "00000000000000000000000000000000")
        // Shared Secret calculated using the method tested in the previous test.
        let sharedSecret = Data(hex: "ab85843a2f6d883f62e5684b38e307335fe6e1945ecd19604105c6f23221eb69")
        
        // Calculate Provisioner Confirmation.
        let provisionerRandom = Data(hex: "8b19ac31d58b124c946209b5db1021b9")
        let confirmationProvisioner = Crypto.calculateConfirmation(confirmationInputs: confirmationInputs,
                                                        sharedSecret: sharedSecret,
                                                        random: provisionerRandom, authValue: authValue,
                                                        using: .BTM_ECDH_P256_CMAC_AES128_AES_CCM)
        
        let expectedConfirmationProvisioner = Data(hex: "b38a114dfdca1fe153bd2c1e0dc46ac2")
        XCTAssertEqual(confirmationProvisioner, expectedConfirmationProvisioner, "Received: \(confirmationProvisioner.hex)")
        
        // Calculate Device Confirmation.
        let provisioneeRandom = Data(hex: "55a2a2bca04cd32ff6f346bd0a0c1a3a")
        let confirmationDevice = Crypto.calculateConfirmation(confirmationInputs: confirmationInputs,
                                                        sharedSecret: sharedSecret,
                                                        random: provisioneeRandom, authValue: authValue,
                                                        using: .BTM_ECDH_P256_CMAC_AES128_AES_CCM)
        
        let expectedConfirmationDevice = Data(hex: "eeba521c196b52cc2e37aa40329f554e")
        XCTAssertEqual(confirmationDevice, expectedConfirmationDevice, "Received: \(confirmationDevice.hex)")
    }
    
    // Test based on Provisioning Sample Data 8.17.2 from Mesh Profile 1.1.
    func testCalculatingConfirmationValuesUsingHMAC_SHA256() throws {
        // Data required to for ConfirmationInputs.
        let provisioningInvite = Data(hex: "00")
        let provisioningCapabilities = Data(hex: "0100030001000000000000")
        let provisioningStart = Data(hex: "0100010000")
        let provisionerPublicKey = Data(hex: "2c31a47b5779809ef44cb5eaaf5c3e43d5f8faad4a8794cb987e9b03745c78dd919512183898dfbecd52e2408e43871fd021109117bd3ed4eaf8437743715d4f")
        let provisioneePublicKey = Data(hex: "f465e43ff23d3f1b9dc7dfc04da8758184dbc966204796eccf0d6cf5e16500cc0201d048bcbbd899eeefc424164e33c201c2b010ca6b4d43a8a155cad8ecb279")
        
        // Create Confirmation Inputs.
        let confirmationInputs = provisioningInvite + provisioningCapabilities + provisioningStart + provisionerPublicKey + provisioneePublicKey
        
        // AuthValue is 32-byte Static OOB.
        let authValue = Data(hex: "906d73a3c7a7cb3ff730dca68a46b9c18d673f50e078202311473ebbe253669f")
        // Shared Secret calculated using the method tested in the previous test.
        let sharedSecret = Data(hex: "ab85843a2f6d883f62e5684b38e307335fe6e1945ecd19604105c6f23221eb69")
        
        // Calculate Provisioner Confirmation.
        let provisionerRandom = Data(hex: "36f968b94a13000e64b223576390db6bcc6d62f02617c369ee3f5b3e89df7e1f")
        let confirmationProvisioner = Crypto.calculateConfirmation(confirmationInputs: confirmationInputs,
                                                        sharedSecret: sharedSecret,
                                                        random: provisionerRandom, authValue: authValue,
                                                        using: .BTM_ECDH_P256_HMAC_SHA256_AES_CCM)
        
        let expectedConfirmationProvisioner = Data(hex: "c99b54617ae646f5f32cf7e1ea6fcc49fd69066078eba9580fa6c7031833e6c8")
        XCTAssertEqual(confirmationProvisioner, expectedConfirmationProvisioner)
        
        // Calculate Device Confirmation.
        let provisioneeRandom = Data(hex: "5b9b1fc6a64b2de8bece53187ee989c6566db1fc7dc8580a73dafdd6211d56a5")
        let confirmationDevice = Crypto.calculateConfirmation(confirmationInputs: confirmationInputs,
                                                        sharedSecret: sharedSecret,
                                                        random: provisioneeRandom, authValue: authValue,
                                                        using: .BTM_ECDH_P256_HMAC_SHA256_AES_CCM)
        
        let expectedConfirmationDevice = Data(hex: "56e3722d291373d38c995d6f942c02928c96abb015c233557d7974b6e2df662b")
        XCTAssertEqual(confirmationDevice, expectedConfirmationDevice)
    }
    
    // Test based on Provisioning Sample Data 8.17.2 from Mesh Profile 1.1.
    func testCalculatingKeys() throws {
        // Data required to for ConfirmationInputs.
        let provisioningInvite = Data(hex: "00")
        let provisioningCapabilities = Data(hex: "0100030001000000000000")
        let provisioningStart = Data(hex: "0100010000")
        let provisionerPublicKey = Data(hex: "2c31a47b5779809ef44cb5eaaf5c3e43d5f8faad4a8794cb987e9b03745c78dd919512183898dfbecd52e2408e43871fd021109117bd3ed4eaf8437743715d4f")
        let provisioneePublicKey = Data(hex: "f465e43ff23d3f1b9dc7dfc04da8758184dbc966204796eccf0d6cf5e16500cc0201d048bcbbd899eeefc424164e33c201c2b010ca6b4d43a8a155cad8ecb279")
        
        // Create Confirmation Inputs.
        let confirmationInputs = provisioningInvite + provisioningCapabilities + provisioningStart + provisionerPublicKey + provisioneePublicKey
        
        // Shared Secret calculated using the method tested in the previous test.
        let sharedSecret = Data(hex: "ab85843a2f6d883f62e5684b38e307335fe6e1945ecd19604105c6f23221eb69")
        
        // Random Values.
        let provisionerRandom = Data(hex: "36f968b94a13000e64b223576390db6bcc6d62f02617c369ee3f5b3e89df7e1f")
        let provisioneeRandom = Data(hex: "5b9b1fc6a64b2de8bece53187ee989c6566db1fc7dc8580a73dafdd6211d56a5")
        
        // Calculate keys.
        let keys = Crypto.calculateKeys(confirmationInputs: confirmationInputs,
                                        sharedSecret: sharedSecret,
                                        provisionerRandom: provisionerRandom,
                                        deviceRandom: provisioneeRandom,
                                        using: .BTM_ECDH_P256_HMAC_SHA256_AES_CCM)
        
        let expectedDeviceKey = Data(hex: "2770852a737cf05d8813768f22af3a2d")
        XCTAssertEqual(keys.deviceKey, expectedDeviceKey)
        
        let expectedSessionKey = Data(hex: "df4a494da3d45405e402f1d6a6cea338")
        XCTAssertEqual(keys.sessionKey, expectedSessionKey)
        
        let expectedSessionNonce = Data(hex: "11b987db2ae41fbb9e96b80446")
        XCTAssertEqual(keys.sessionNonce, expectedSessionNonce)
    }
    
    // Test based on Provisioning Sample Data 8.17.2 from Mesh Profile 1.1.
    func testEncryptingKeys() throws {
        let flags = Data(hex: "00")
        let ivIndex: UInt32 = 0x01020304
        let key = Data(hex: "efb2255e6422d330088e09bb015ed707")
        let index: KeyIndex = 0x0567
        let sessionNonce = Data(hex: "11b987db2ae41fbb9e96b80446")
        let unicastAddress: Address = 0x0b0c
        let sessionKey = Data(hex: "df4a494da3d45405e402f1d6a6cea338")
        
        // Combined data.
        let data = key + index.bigEndian + flags + ivIndex.bigEndian + unicastAddress.bigEndian
        
        // Encrypt data using the session key and nonce.
        let encryptedData = Crypto.encrypt(provisioningData: data,
                                           usingSessionKey: sessionKey, andNonce: sessionNonce)
        
        let expectedEncryptedData = Data(hex: "f9df98cbb736be1f600659ac4c37821a82db31e410a03de769")
        let expectedMIC = Data(hex: "3a2a0428fbdaf321")
        XCTAssertEqual(encryptedData, expectedEncryptedData + expectedMIC)
    }
    
}
