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

import Foundation
import Security
import CryptoSwift

/// A helper class for handling cryptography.
///
/// Method implementation is based on Security toolbox and other parts from the
/// Bluetooth Mesh Protocol 1.1.
///
/// It is backwards compatible with older versions of the specification.
internal class Crypto {
    
    private init() { }
    
    /// Generates random data of given length, given in bits.
    ///
    /// To generate a key outside of this library, use `Data.random128BitKey()`
    /// or `Data.random256BitKey()`.
    ///
    /// - parameter sizeInBits: Required size of the random data, in bits.
    /// - returns: An array generated using the default random number generator.
    static func generateRandom(sizeInBits: Int) -> Data {
        let sizeInBytes = sizeInBits >> 3
        var buffer = [UInt8](repeating: 0, count: sizeInBytes)
        let status = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        guard status == errSecSuccess else {
            fatalError("Could not generate random, SecRandomCopyBytes returned: \(status)")
        }
        return Data(buffer)
    }
    
    /// Obfuscates or deobfuscates given data by XORing it with PECB, which is
    /// caluclated by encrypting Privacy Plaintext (encrypted data (used as Privacy
    /// Random) and IV Index) using the given key.
    ///
    /// - parameters:
    ///   - data:       The data to obfuscate or deobfuscate.
    ///   - random:     Data used as Privacy Random.
    ///   - ivIndex:    The current IV Index value.
    ///   - privacyKey: The 128-bit Privacy Key.
    /// - returns: Obfuscated data of the same size as input data.
    static func obfuscate(_ data: Data, usingPrivacyRandom random: Data,
                          ivIndex: UInt32, andPrivacyKey privacyKey: Data) -> Data {
        // Privacy Random = (EncDST || EncTransportPDU || NetMIC)[0–6]
        // Privacy Plaintext = 0x0000000000 || IV Index || Privacy Random
        // PECB = e (PrivacyKey, Privacy Plaintext)
        // ObfuscatedData = (CTL || TTL || SEQ || SRC) ⊕ PECB[0–5]
        let privacyRandom = random.subdata(in: 0..<7)
        let privacyPlaintext = Data(repeating: 0, count: 5) + ivIndex.bigEndian + privacyRandom
        let pecb = calculateECB(privacyPlaintext, andKey: privacyKey)
        let obfuscatedData = data ^ pecb.subdata(in: 0..<6)
        return obfuscatedData
    }
    
    /// Calculate the 16-bit Virtual Address based on the 128-bit Label UUID.
    ///
    /// - parameter virtualLabel: The Virtual Label of a Virtual Group.
    /// - returns: 16-bit hash, known as Virtual Address.
    static func calculateVirtualAddress(from virtualLabel: UUID) -> Address {
        let vtad = "vtad".data(using: .utf8)!
        let salt = calculateS1(vtad)
        let hash = calculateCMAC(Data(hex: virtualLabel.hex), andKey: salt)
        var address = UInt16(data: hash.dropFirst(14)).bigEndian
        address |= 0x8000
        address &= 0xBFFF
        return address
    }
    
    /// Calculates key derivatives from the given Network Key.
    ///
    /// The derivatives are:
    /// - NID (LSB, 7 bits),
    /// - Encryption Key (128 bits),
    /// - Privacy Key (128 bits),
    /// - Identity Key (128 bits),
    /// - Beacon Key (128 bits)
    /// - Private Beacon Key (128 bits).
    ///
    /// - parameter key: The Network Key.
    /// - returns: Key derivatives.
    static func calculateKeyDerivatives(from key: Data)
                -> (nid: UInt8, encryptionKey: Data, privacyKey: Data, identityKey: Data, beaconKey: Data, privateBeaconKey: Data) {
        let P = Data([0x69, 0x64, 0x31, 0x32, 0x38, 0x01]) // "id128" || 0x01
        let saltIK = calculateS1("nkik".data(using: .utf8)!)
        let identityKey = calculateK1(withN: key, salt: saltIK, andP: P)
        let saltBK = calculateS1("nkbk".data(using: .utf8)!)
        let beaconKey = calculateK1(withN: key, salt: saltBK, andP: P)
        let saltPK = calculateS1("nkpk".data(using: .utf8)!)
        let privateBeaconKey = calculateK1(withN: key, salt: saltPK, andP: P)
        
        let (nid, encryptionKey, privacyKey) = calculateK2(withN: key, andP: Data([0x00]))
        return (nid, encryptionKey, privacyKey, identityKey, beaconKey, privateBeaconKey)
    }
    
    /// Generates the Network ID based on the given 128-bit key.
    ///
    /// - parameter key: The 128-bit key.
    /// - returns: Network ID.
    static func calculateNetworkId(from key: Data) -> Data {
        return calculateK3(withN: key)
    }
    
    /// Generates the Application Key Identifier based on the key.
    ///
    /// - parameter key: The Application Key.
    /// - returns: The generated AID.
    static func calculateAid(from key: Data) -> UInt8 {
        return calculateK4(withN: key)
    }
    
    /// Generates Node Identity hash using the given Identity Key.
    ///
    /// - Parameters:
    ///   - data: 48 bits padding of 0s, 65-bit random value and the Unicast Address
    ///           of the Node.
    ///   - key: The Identity Key.
    /// - Returns: Function of the included random number and identity information.
    static func calculateHash(from data: Data, usingIdentityKey key: Data) -> Data {
        return calculateECB(data, andKey: key).dropFirst(8)
    }
    
    /// Authenticates the received Secure Network beacon using the given Beacon Key.
    ///
    /// - parameters:
    ///   - pdu: The received PDU.
    ///   - key: The Beacon Key generated from a Network Key.
    /// - returns: `True` if Secure Network beacon was authenticated, `false` otherwise.
    static func authenticate(secureNetworkBeaconPdu pdu: Data, usingBeaconKey key: Data) -> Bool {
        // Byte 0 of the PDU is the Beacon Type (0x01).
        let flagsNetworkIdAndIVIndex = pdu.subdata(in: 1..<14)
        let authenticationValue = pdu.subdata(in: 14..<22)
        let hash = calculateCMAC(flagsNetworkIdAndIVIndex, andKey: key).subdata(in: 0..<8)
        return authenticationValue == hash
    }
    
    /// Decodes and authenticates the received Private beacon using the given Private
    /// Beacon Key.
    ///
    /// - parameters:
    ///   - pdu: The received PDU.
    ///   - key: The Private Beacon Key generated from a Network Key.
    /// - returns: Network information obtained from the beacon.
    static func decodeAndAuthenticate(privateBeacon pdu: Data,
                                      usingPrivateBeaconKey key: Data) -> (keyRefreshFlag: Bool, ivIndex: IvIndex)? {
        // Byte 0 of the PDU is the Beacon Type (0x02).
        let random = pdu.subdata(in: 1..<14)
        let obfuscatedData = pdu.subdata(in: 14..<19)
        let authenticationTag = pdu.subdata(in: 19..<27)
        
        // Deobfuscate Private Beacon Data.
        let C1 = Data([0x01]) + random + Data([0x00, 0x01])
        let S = calculateECB(C1, andKey: key)
        let privateBeaconData = S.subdata(in: 0..<5) ^ obfuscatedData
        
        // Authenticate the Beacon.
        let B0 = Data([0x19]) + random + Data([0x00, 0x05])
        let C0 = Data([0x01]) + random + Data([0x00, 0x00])
        let P = privateBeaconData + Data(repeating: 0x00, count: 11)
        let T0 = calculateECB(B0, andKey: key)
        let T1 = calculateECB(T0 ^ P, andKey: key)
        let T2 = T1 ^ calculateECB(C0, andKey: key)
        let calculatedAuthenticationTag = T2.subdata(in: 0..<8)
        
        // Authentication tags must match for the beacon to be valid.
        guard authenticationTag == calculatedAuthenticationTag else {
            return nil
        }
        
        // Decode Private Beacon Data.
        let flags = privateBeaconData[0]
        let keyRefreshFlag = (flags & 0x01) != 0
        let updateActive   = (flags & 0x02) != 0
        let index: UInt32 = privateBeaconData.read(fromOffset: 1)
        let ivIndex = IvIndex(index: index.bigEndian, updateActive: updateActive)
        
        return (keyRefreshFlag, ivIndex)
    }
    
    /// Encrypts given data using the Encryption Key, Nonce and adds MIC
    /// (Message Integrity Check) of given size to the end of the returned ciphertext.
    ///
    /// - parameters:
    ///   - data:  The data to be encrypted and authenticated, also known as plaintext.
    ///   - key:   The 128-bit key.
    ///   - nonce: A 104-bit nonce.
    ///   - size:  Length of the MIC to be generated, in bytes.
    ///   - aad:   Additional data to be authenticated.
    /// - returns: Encrypted data concatenated with MIC of given size.
    static func encrypt(_ data: Data, withEncryptionKey key: Data, nonce: Data,
                         andMICSize size: UInt8, withAdditionalData aad: Data?) -> Data {
        return calculateCCM(data, withKey: key, nonce: nonce, andMICSize: size, withAdditionalData: aad)
    }
    
    /// Decrypts given ciphertext using the Encryption Key, Nonce and valudates its
    /// integrity using the MIC (Message Integrity Check).
    ///
    /// - parameters:
    ///   - data:  Encrypted data.
    ///   - key:   The 128-bit key.
    ///   - nonce: A 104-bit nonce.
    ///   - mic:   Message Integrity Check data.
    ///   - aad:   Additional data to be authenticated.
    /// - returns: Decrypted data, if decryption is successful and MIC is valid,
    ///            otherwise `nil`.
    static func decrypt(_ data: Data, withEncryptionKey key: Data, nonce: Data,
                        andMIC mic: Data, withAdditionalData aad: Data?) -> Data? {
        return calculateDecryptedCCM(data, withKey: key, nonce: nonce, andMIC: mic, withAdditionalData: aad)
    }
    
    // MARK: - Provisioning
    
    /// Generates a pair of Private and Public Keys using P256 Elliptic Curve
    /// algorithm.
    ///
    /// - parameter algorithm: The algorithm for key pair generation.
    /// - returns: The Private and Public Key pair.
    /// - throws: This method throws an error if the key pair generation has failed
    ///           or the given algorithm is not supported.
    static func generateKeyPair(using algorithm: Algorithm) throws -> (privateKey: SecKey, publicKey: SecKey) {
        switch algorithm {
        case .fipsP256EllipticCurve,
             .BTM_ECDH_P256_CMAC_AES128_AES_CCM,
             .BTM_ECDH_P256_HMAC_SHA256_AES_CCM:
            // Private key parameters.
            let privateKeyParams = [kSecAttrIsPermanent : false] as CFDictionary
            
            // Public key parameters.
            let publicKeyParams = [kSecAttrIsPermanent : false] as CFDictionary
            
            // Global parameters.
            var error: Unmanaged<CFError>?
            let parameters = [kSecAttrKeyType : kSecAttrKeyTypeECSECPrimeRandom,
                        kSecAttrKeySizeInBits : 256,
                           kSecPublicKeyAttrs : publicKeyParams,
                          kSecPrivateKeyAttrs : privateKeyParams] as [CFString : Any]
            
            guard let privateKey = SecKeyCreateRandomKey(parameters as CFDictionary, &error),
                  let publicKey = SecKeyCopyPublicKey(privateKey) else {
                throw ProvisioningError.keyGenerationFailed(error!.takeRetainedValue() as Error)
            }
            
            return (privateKey, publicKey)
        }
    }
    
    /// Calculates the Shared Secret based on the given Public Key
    /// and the local Private Key.
    ///
    /// - parameters:
    ///   - privateKey: The local device's Private Key.
    ///   - publicKey: The device's Public Key as bytes.
    /// - returns: The ECDH Shared Secret.
    static func calculateSharedSecret(privateKey: SecKey, publicKey: Data) throws -> Data {
        // First byte has to be 0x04 to indicate uncompressed representation.
        var devicePublicKeyData = Data([0x04])
        devicePublicKeyData.append(contentsOf: publicKey)
        
        let pubKeyParameters = [kSecAttrKeyType : kSecAttrKeyTypeECSECPrimeRandom,
                                kSecAttrKeyClass: kSecAttrKeyClassPublic] as CFDictionary
        
        var error: Unmanaged<CFError>?
        let devicePublicKey = SecKeyCreateWithData(devicePublicKeyData as CFData,
                                                   pubKeyParameters, &error)
        guard error == nil else {
            throw error!.takeRetainedValue()
        }
        
        let exchangeResultParams = [SecKeyKeyExchangeParameter.requestedSize: 32] as CFDictionary
        
        let ssk = SecKeyCopyKeyExchangeResult(privateKey,
                                              SecKeyAlgorithm.ecdhKeyExchangeStandard,
                                              devicePublicKey!, exchangeResultParams, &error)
        guard error == nil else {
            throw error!.takeRetainedValue()
        }
        
        return ssk! as Data
    }
    
    /// This method calculates the Provisioning Confirmation based on the
    /// Confirmation Inputs, 16 or 32-byte Random and 16 or 32-byte AuthValue.
    ///
    /// - parameters:
    ///   - confirmationInputs: The Confirmation Inputs is built over the provisioning
    ///                         process.
    ///   - sharedSecret: Shared secret obtained in the previous step.
    ///   - random: An array of 16 or 32 bytes random bytes, depending on the algorithm.
    ///   - authValue: The Auth Value calculated based on the Authentication Method.
    ///   - algorithm: The algorithm to be used.
    /// - returns: The Provisioning Confirmation value.
    static func calculateConfirmation(confirmationInputs: Data, sharedSecret: Data,
                                      random: Data, authValue: Data,
                                      using algorithm: Algorithm) -> Data {
        switch algorithm {
        case .fipsP256EllipticCurve,
             .BTM_ECDH_P256_CMAC_AES128_AES_CCM:
            // Calculate the Confirmation Salt = s1(confirmationInputs).
            let confirmationSalt = Crypto.calculateS1(confirmationInputs)
            
            // Calculate the Confirmation Key = k1(ECDH Secret, confirmationSalt, 'prck')
            let confirmationKey  = Crypto.calculateK1(withN: sharedSecret,
                                                      salt: confirmationSalt,
                                                      andP: "prck".data(using: .utf8)!)
            
            // Calculate the Confirmation Provisioner using CMAC(random + authValue)
            return Crypto.calculateCMAC(random + authValue, andKey: confirmationKey)
        case .BTM_ECDH_P256_HMAC_SHA256_AES_CCM:
            // Calculate the Confirmation Salt = s2(confirmationInputs).
            let confirmationSalt = Crypto.calculateS2(confirmationInputs)
            
            // Calculate the Confirmation Key = k5(ECDH Secret + authValue, confirmationSalt, 'prck256')
            let confirmationKey  = Crypto.calculateK5(withN: sharedSecret + authValue,
                                                      salt: confirmationSalt,
                                                      andP: "prck256".data(using: .utf8)!)
            
            // Calculate the Confirmation Provisioner using HMAC-SHA-256(random)
            return Crypto.calculateHMAC_SHA256(random, andKey: confirmationKey)
        }
    }
    
    /// This method calculates the Session Key, Session Nonce and the Device Key based
    /// on the Confirmation Inputs, 16 or 32-byte Provisioner Random and 16 or 32-byte
    /// device Random.
    ///
    /// - parameters:
    ///   - confirmationInputs: The Confirmation Inputs is built over the provisioning
    ///                         process.
    ///   - sharedSecret: Shared secret obtained in the previous step.
    ///   - provisionerRandom: An array of 16 or 32 random bytes.
    ///   - deviceRandom: An array of 16 or 32 random bytes received from the Device.
    ///   - algorithm: The algorithm to be used.
    /// - returns: The Session Key, Session Nonce and the Device Key.
    static func calculateKeys(confirmationInputs: Data, sharedSecret: Data,
                              provisionerRandom: Data, deviceRandom: Data,
                              using algorithm: Algorithm) ->
            (sessionKey: Data, sessionNonce: Data, deviceKey: Data) {
        var confirmationSalt: Data!
        switch algorithm {
        case .fipsP256EllipticCurve,
             .BTM_ECDH_P256_CMAC_AES128_AES_CCM:
            // Calculate the Confirmation Salt = s1(confirmationInputs).
            confirmationSalt = Crypto.calculateS1(confirmationInputs)
        case .BTM_ECDH_P256_HMAC_SHA256_AES_CCM:
            // Calculate the Confirmation Salt = s2(confirmationInputs).
            confirmationSalt = Crypto.calculateS2(confirmationInputs)
        }
        
        // Calculate the Provisioning Salt = s1(confirmationSalt + provisionerRandom + deviceRandom)
        let provisioningSalt = Crypto.calculateS1(confirmationSalt + provisionerRandom + deviceRandom)
        
        // The Session Key is derived as k1(ECDH Shared Secret, provisioningSalt, "prsk")
        let sessionKey = Crypto.calculateK1(withN: sharedSecret,
                                            salt: provisioningSalt,
                                            andP: "prsk".data(using: .utf8)!)
        
        // The Session Nonce is derived as k1(ECDH Shared Secret, provisioningSalt, "prsn")
        // Only 13 least significant bits of the calculated value are used.
        let sessionNonce = Crypto.calculateK1(withN: sharedSecret,
                                              salt: provisioningSalt,
                                              andP: "prsn".data(using: .utf8)!).dropFirst(3)
        
        // The Device Key is derived as k1(ECDH Shared Secret, provisioningSalt, "prdk")
        let deviceKey = Crypto.calculateK1(withN: sharedSecret,
                                           salt: provisioningSalt,
                                           andP: "prdk".data(using: .utf8)!)
        return (sessionKey, sessionNonce, deviceKey)
    }
    
    /// Encrypts the provisioning data using given session key and nonce.
    ///
    /// - parameters:
    ///   - data: Provisioning data to be encrypted.
    ///   - key: Session Key.
    ///   - nonce: Session Nonce.
    /// - returns: Encrypted data.
    static func encrypt(provisioningData data: Data,
                        usingSessionKey key: Data, andNonce nonce: Data) -> Data {
        return Crypto.calculateCCM(data, withKey: key, nonce: nonce,
                                   andMICSize: 8, withAdditionalData: nil)
    }
    
}

private extension Crypto {
    
    /// Calculates salt over given data.
    ///
    /// - parameter data: A non-zero length octet array or ASCII encoded string.
    static func calculateS1(_ data: Data) -> Data {
        let key = Data(repeating: 0, count: 16)
        return calculateCMAC(data, andKey: key)
    }
    
    /// Calculates salt over given data.
    ///
    /// - parameter data: A non-zero length octet array or ASCII encoded string.
    static func calculateS2(_ data: Data) -> Data {
        let key = Data(repeating: 0, count: 32)
        return calculateHMAC_SHA256(data, andKey: key)
    }
    
    /// Calculates Cipher-based Message Authentication Code (CMAC) that uses
    /// AES-128 as the block cipher function, also known as AES-CMAC.
    ///
    /// - parameters:
    ///   - data: Data to be authenticated.
    ///   - key:  The 128-bit key.
    /// - returns: The 128-bit authentication code (MAC).
    static func calculateCMAC(_ data: Data, andKey key: Data) -> Data {
        do {
            let array = try CMAC(key: key.bytes).authenticate(data.bytes)
            return Data(array)
        } catch {
            fatalError("Failed to calculate CMAC: \(error)")
        }
    }
    
    /// RFC 2104 defines HMAC, a mechanism for message authentication using
    /// cryptographic hash functions. FIPS 180-4 defines the SHA-256 secure
    /// hash algorithm.
    ///
    /// The SHA-256 algorithm is used as a hash function for the HMAC mechanism
    /// for the HMAC-SHA-256 function.
    ///
    /// - parameters:
    ///   - data: Data to be authenticated.
    ///   - key:  The 256-bit key.
    /// - returns: The 128-bit authentication code (MAC).
    static func calculateHMAC_SHA256(_ data: Data, andKey key: Data) -> Data {
        do {
            let array = try HMAC(key: key.bytes, variant: .sha2(.sha256)).authenticate(data.bytes)
            return Data(array)
        } catch {
            fatalError("Failed to calculate HMAC-SHA-256: \(error)")
        }
    }
    
    /// Calculates Electronic codebook (ECB).
    ///
    /// - parameters:
    ///   - data: The input data.
    ///   - key: The 128-bit key.
    /// - returns: Calculated electronic codebook (ECB).
    static func calculateECB(_ data: Data, andKey key: Data) -> Data {
        do {
            let ecb = ECB()
            let aes = try AES(key: key.bytes, blockMode: ecb, padding: .noPadding)
            let array = try aes.encrypt(data.bytes)
            return Data(array)
        } catch {
            fatalError("Calculating ECB failed: \(error)")
        }
    }
    
    /// RFC3610 defines teh AES Counter with CBC-MAC (CCM).
    /// This method generates ciphertext and MIC (Message Integrity Check).
    ///
    /// - parameters:
    ///   - data:  The data to be encrypted and authenticated, also known as plaintext.
    ///   - key:   The 128-bit key.
    ///   - nonce: A 104-bit nonce.
    ///   - size:  Length of the MIC to be generated, in bytes.
    ///   - aad:   Additional data to be authenticated.
    /// - returns: Encrypted data concatenated with MIC of given size.
    static func calculateCCM(_ data: Data, withKey key: Data, nonce: Data,
                             andMICSize size: UInt8, withAdditionalData aad: Data?) -> Data {
        do {
            let ccm = CCM(iv: nonce.bytes, tagLength: Int(size), messageLength: data.count,
                          additionalAuthenticatedData: aad?.bytes)
            let aes = try AES(key: key.bytes, blockMode: ccm, padding: .noPadding)
            let array = try aes.encrypt(data.bytes)
            return Data(array)
        } catch {
            fatalError("CCM encryption failed: \(error)")
        }
    }
    
    /// Decrypts data encrypted with CCM.
    ///
    /// - parameters:
    ///   - data:  Encrypted data.
    ///   - key:   The 128-bit key.
    ///   - nonce: A 104-bit nonce.
    ///   - mic:   Message Integrity Check data.
    ///   - aad:   Additional data to be authenticated.
    /// - returns: Decrypted data, if decryption is successful and MIC is valid,
    ///            otherwise `nil`.
    static func calculateDecryptedCCM(_ data: Data, withKey key: Data, nonce: Data,
                                      andMIC mic: Data, withAdditionalData aad: Data?) -> Data? {
        do {
            // In CryptoSwift 1.3.8 the authenticationTag is ignored in CCM:
            // https://github.com/krzyzanowskim/CryptoSwift/issues/853
            let concatenated = data + mic
            let ccm = CCM(iv: nonce.bytes, tagLength: mic.count, messageLength: data.count,
                          // authenticationTag: mic.bytes,
                          additionalAuthenticatedData: aad?.bytes)
            let aes = try AES(key: key.bytes, blockMode: ccm, padding: .noPadding)
            let array = try aes.decrypt(concatenated.bytes /* data.bytes */)
            return Data(array)
        } catch CCM.Error.fail {
            return nil
        } catch {
            fatalError("CCM decryption failed: \(error)")
        }
    }
    
// MARK: - Helpers
    
    /// The network key material derivation function k1 is used to generate
    /// instances of Identity Key and Beacon Key.
    ///
    /// The definition of this derivation function makes use of the MAC function
    /// AES-CMAC(T) with 128-bit key T.
    ///
    /// - parameters:
    ///   - N: 0 or more octets.
    ///   - salt: 128 bit salt.
    ///   - P: 0 or more octets.
    /// - returns: 128-bit key.
    static func calculateK1(withN N: Data, salt: Data, andP P: Data) -> Data {
        let T = calculateCMAC(N, andKey: salt)
        return calculateCMAC(P, andKey: T)
    }
    
    /// The network key material derivation function k2 is used to generate
    /// instances of Encryption Key, Privacy Key and NID for use as Master and
    /// Private Low Power node communication. This method returns 33 byte data.
    ///
    /// The definition of this derivation function makes use of the MAC function
    /// AES-CMAC(T) with 128-bit key T.
    ///
    /// - parameters:
    ///   - N: 128-bit key.
    ///   - P: 1 or more octets.
    /// - returns: NID (7 bits), Encryption Key (128 bits) and Privacy Key (128 bits).
    static func calculateK2(withN N: Data, andP P: Data)
                -> (nid: UInt8, encryptionKey: Data, privacyKey: Data) {
        let smk2 = Data([0x73, 0x6D, 0x6B, 0x32]) // "smk2" as Data
        let s1 = calculateS1(smk2)
        let T  = calculateCMAC(N, andKey: s1)
        let T0 = Data()
        let T1 = calculateCMAC(T0 + P + Data([0x01]), andKey: T)
        let T2 = calculateCMAC(T1 + P + Data([0x02]), andKey: T)
        let T3 = calculateCMAC(T2 + P + Data([0x03]), andKey: T)
        
        let nid = T1[15] & 0x7F
        return (nid, T2, T3)
    }
    
    /// The derivation function k3 us used to generate a public value of 64 bits
    /// derived from a private key.
    ///
    /// The definition of this derivation function makes use of the MAC function
    /// AES-CMAC(T) with 128-bit key T.
    ///
    /// - parameter N: 128-bit key.
    /// - returns: 64 bits of a public value derived from the key.
    static func calculateK3(withN N: Data) -> Data {
        let smk3 = Data([0x73, 0x6D, 0x6B, 0x33]) // "smk3" as Data
        let s1 = calculateS1(smk3)
        let T  = calculateCMAC(N, andKey: s1)
        let id64_0x01 = Data([0x69, 0x64, 0x36, 0x34, 0x01]) // "id64" || 0x01
        let result = calculateCMAC(id64_0x01, andKey: T)
        return result.subdata(in: result.count - 8..<result.count)
    }
    
    /// The derivation function k4 us used to generate a public value of 6 bits
    /// derived from a private key.
    ///
    /// The definition of this derivation function makes use of the MAC function
    /// AES-CMAC(T) with 128-bit key T.
    ///
    /// - parameter N: 128-bit key.
    /// - returns: UInt8 with 6 LSB bits of a public value derived from the key.
    static func calculateK4(withN N: Data) -> UInt8 {
        let smk4 = Data([0x73, 0x6D, 0x6B, 0x34]) // "smk4" as Data
        let s1 = calculateS1(smk4)
        let T  = calculateCMAC(N, andKey: s1)
        let id6_0x01 = Data([0x69, 0x64, 0x36, 0x01]) // "id6" || 0x01
        let result = calculateCMAC(id6_0x01, andKey: T)
        return result[15] & 0x3F
    }
    
    /// The provisioning material derivation function k5 is used to generate
    /// the 256-bit key used in provisioning using ``Algorithm/BTM_ECDH_P256_HMAC_SHA256_AES_CCM``
    /// algorithm.
    ///
    /// The definition of this derivation function makes use of the MAC
    /// function HMAC-SHA-256 with a 256-bit key T.
    ///
    /// - parameters:
    ///   - N: 32 or more octets.
    ///   - salt: 256 bit salt.
    ///   - P: 1 or more octets.
    /// - returns: 256-bit key.
    static func calculateK5(withN N: Data, salt: Data, andP P: Data) -> Data {
        let T = calculateHMAC_SHA256(N, andKey: salt)
        return calculateHMAC_SHA256(P, andKey: T)
    }
    
}

private extension Data {
    
    /// XOR implementation.
    ///
    /// - parameters:
    ///   - left:  Left operand.
    ///   - right: Right operand.
    /// - returns: Xored result as Data.
    static func ^ (left: Data, right: Data) -> Data {
        var result = Data(repeating: 0, count: left.count)
        for i in 0..<left.count {
            result[i] = left[i] ^ right[i % right.count]
        }
        return result
    }

}
