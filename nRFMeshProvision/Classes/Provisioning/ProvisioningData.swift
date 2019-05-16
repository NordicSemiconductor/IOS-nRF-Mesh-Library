//
//  ProvisioningData.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 15/05/2019.
//

import Foundation

internal class ProvisioningData {
    private let helper = OpenSSLHelper()
    
    private let networkKey: NetworkKey
    private let ivIndex: IvIndex
    private let unicastAddress: Address
    
    private var privateKey: SecKey!
    private var publicKey: SecKey!
    private var sharedSecret: Data!
    private var authValue: Data!
    private var deviceConfirmation: Data!
    private var deviceRandom: Data!
    private(set) var deviceKey: Data!
    private(set) var provisionerRandom: Data!
    private(set) var provisionerPublicKey: Data!
    
    /// The Confirmation Inputs is built over the provisioning process.
    /// It is composed for: Provisioning Invite PDU, Provisioning Capabilities PDU,
    /// Provisioning Start PDU, Provisioner's Public Key and device's Public Key.
    private var confirmationInputs: Data
    
    init(for network: MeshNetwork, networkKey: NetworkKey, unicastAddress: Address, using algorithm: Algorithm) throws {
        self.networkKey = networkKey
        self.ivIndex = network.ivIndex
        self.unicastAddress = unicastAddress
        self.confirmationInputs = Data(capacity: 1 + 11 + 5 + 64 + 64)
        
        // Generate Provisioner Random.
        provisionerRandom = randomData(length: 16)
        
        // Generate Public and Private Keys.
        let (pk, sk) = try generateKeyPair(using: algorithm)
        privateKey = sk
        publicKey  = pk
        try provisionerPublicKey = pk.toData()
    }
    
}

internal extension ProvisioningData {
    
    func accumulate(pdu: Data) {
        confirmationInputs += pdu
    }
    
    func provisionerDidObtain(devicePublicKey key: Data) throws {
        sharedSecret = try calculateSharedSecret(publicKey: key)
    }
    
    func provisionerDidObtain(authValue data: Data) {
        authValue = data
    }
    
    func provisionerDidObtain(deviceConfirmation data: Data) {
        deviceConfirmation = data
    }
    
    func provisionerDidObtain(deviceRandom data: Data) {
        deviceRandom = data
    }
    
    func validateConfirmation() throws {
        let confirmation = calculateConfirmation(random: deviceRandom, authValue: authValue)
        guard deviceConfirmation == confirmation else {
            throw ProvisioningError.confirmationFailed
        }
    }
    
    var provisionerConfirmation: Data {
        return calculateConfirmation(random: provisionerRandom, authValue: authValue)
    }
    
    var encryptedProvisioningDataWithMic: Data {
        let keys = calculateKeys()
        deviceKey = keys.deviceKey
        
        let flags = Flags(ivIndex: ivIndex, networkKey: networkKey)
        let data  = networkKey.key + networkKey.index.bigEndian + flags.rawValue + ivIndex.index.bigEndian + unicastAddress.bigEndian
        return helper.calculateCCM(data, withKey: keys.sessionKey, nonce: keys.sessionNonce, dataSize: 25, andMICSize: 8)
    }
}

// MARK: - Helper methods

private extension ProvisioningData {
    
    /// Generates a pair of Private and Public Keys using P256 Elliptic Curve
    /// algorithm.
    ///
    /// - parameter algorithm: The algorithm for key pair generation.
    /// - returns: The Private and Public Key pair.
    /// - throws: This method throws an error if the key pair generation has failed
    ///           or the given algorithm is not supported.
    func generateKeyPair(using algorithm: Algorithm) throws -> (privateKey: SecKey, publicKey: SecKey) {
        guard case .fipsP256EllipticCurve = algorithm else {
            throw ProvisioningError.unsupportedAlgorithm
        }
        
        // Private key parameters.
        let privateKeyParams = [kSecAttrIsPermanent : false] as CFDictionary
        
        // Public key parameters.
        let publicKeyParams = [kSecAttrIsPermanent : false] as CFDictionary
        
        // Global parameters.
        let parameters = [kSecAttrKeyType : kSecAttrKeyTypeECSECPrimeRandom,
                          kSecAttrKeySizeInBits : 256,
                          kSecPublicKeyAttrs : publicKeyParams,
                          kSecPrivateKeyAttrs : privateKeyParams] as CFDictionary
        
        var publicKey, privateKey: SecKey?
        let status = SecKeyGeneratePair(parameters as CFDictionary, &publicKey, &privateKey)
        
        guard status == errSecSuccess else {
            throw ProvisioningError.keyGenerationFailed(status)
        }
        return (privateKey!, publicKey!)
    }
    
    /// Calculates the Shared Secret based on the given Public Key
    /// and the local Private Key.
    ///
    /// - parameter publicKey: The device's Public Key as bytes.
    /// - returns: The ECDH Shared Secret.
    func calculateSharedSecret(publicKey: Data) throws -> Data {
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
        
        let exchangeResultParams = [kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom] as CFDictionary
        
        let ssk = SecKeyCopyKeyExchangeResult(privateKey,
                                              SecKeyAlgorithm.ecdhKeyExchangeStandardX963SHA256,
                                              devicePublicKey!, exchangeResultParams, &error)
        guard error == nil else {
            throw error!.takeRetainedValue()
        }
        
        return ssk! as Data
    }
    
    /// This method calculates the Provisioning Confirmation based on the
    /// Confirmation Inputs, 16-byte Random and 16-byte AuthValue.
    ///
    /// - parameter random:    An array of 16 random bytes.
    /// - parameter authValue: The Auth Value calculated based on the Authentication Method.
    /// - returns: The Provisioning Confirmation value.
    func calculateConfirmation(random: Data, authValue: Data) -> Data {
        // Calculate the Confirmation Salt = s1(confirmationInputs).
        let confirmationSalt = helper.calculateSalt(confirmationInputs)!
        
        // Calculate the Confirmation Key = k1(ECDH Secret, confirmationSalt, 'prck')
        let confirmationKey  = helper.calculateK1(withN: sharedSecret!,
                                                  salt: confirmationSalt,
                                                  andP: "prck".data(using: .ascii)!)!
        
        // Calculate the Confirmation Provisioner using CMAC(random + authValue)
        let confirmationData = random + authValue
        return helper.calculateCMAC(confirmationData, andKey: confirmationKey)!
    }
    
    /// This method calculates the Session Key, Session Nonce and the Device Key based
    /// on the Confirmation Inputs, 16-byte Provisioner Random and 16-byte device Random.
    ///
    /// - returns: The Session Key, Session Nonce and the Device Key.
    func calculateKeys() -> (sessionKey: Data, sessionNonce: Data, deviceKey: Data) {
        // Calculate the Confirmation Salt = s1(confirmationInputs).
        let confirmationSalt = helper.calculateSalt(confirmationInputs)!
        
        // Calculate the Provisioning Salt = s1(confirmationSalt + provisionerRandom + deviceRandom)
        let provisioningSalt = helper.calculateSalt(confirmationSalt + provisionerRandom! + deviceRandom!)!
        
        // The Session Key is derived as k1(ECDH Shared Secret, provisioningSalt, "prsk")
        let sessionKey = helper.calculateK1(withN: sharedSecret!,
                                            salt: provisioningSalt,
                                            andP: "prsk".data(using: .ascii)!)!
        
        // The Session Nonce is derived as k1(ECDH Shared Secret, provisioningSalt, "prsn")
        // Only 13 least significant bits of the calculated value are used.
        let sessionNonce = helper.calculateK1(withN: sharedSecret!,
                                              salt: provisioningSalt,
                                              andP: "prsn".data(using: .ascii)!)!.dropFirst(3)
        
        // The Device Key is derived as k1(ECDH Shared Secret, provisioningSalt, "prdk")
        let deviceKey = helper.calculateK1(withN: sharedSecret!,
                                           salt: provisioningSalt,
                                           andP: "prdk".data(using: .ascii)!)!
        return (sessionKey: sessionKey, sessionNonce: sessionNonce, deviceKey: deviceKey)
    }
    
    /// Generates an array of cryptographically secure random bytes.
    func randomData(length: Int) -> Data {
        var data = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, length, &data)
        return Data(data)
    }
    
}

private struct Flags: OptionSet {
    let rawValue: UInt8
    
    static let keyRefreshFinalizing = Flags(rawValue: 1 << 0)
    static let ivUpdateActive       = Flags(rawValue: 1 << 1)
    
    init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    
    init(ivIndex: IvIndex, networkKey: NetworkKey) {
        var value: UInt8 = 0
        if case .finalizing = networkKey.phase {
            value |= 1 << 0
        }
        if ivIndex.updateActive {
            value |= 1 << 1
        }
        self.rawValue = value
    }
}

private extension SecKey {
    
    /// Returns the Public Key as Data from the SecKey. The SecKey must contain the
    /// valid public key.
    func toData() throws -> Data {
        var error: Unmanaged<CFError>?
        guard let representation = SecKeyCopyExternalRepresentation(self, &error) else {
            throw error!.takeRetainedValue()
        }
        let data = representation as Data
        // First is 0x04 to indicate uncompressed representation.
        return data.dropFirst()
    }
    
}
