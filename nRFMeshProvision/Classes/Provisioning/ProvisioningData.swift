/*
* Copyright (c) 2019, Nordic Semiconductor
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

internal class ProvisioningData {    
    private(set) var networkKey: NetworkKey!
    private(set) var ivIndex: IvIndex!
    private(set) var unicastAddress: Address!
    
    private var privateKey: SecKey!
    private var publicKey: SecKey!
    private var sharedSecret: Data!
    private var authValue: Data!
    private var deviceConfirmation: Data!
    private var deviceRandom: Data!
    private var oobPublicKey: Bool!
    
    private(set) var algorithm: Algorithm!
    private(set) var deviceKey: Data!
    private(set) var provisionerRandom: Data!
    private(set) var provisionerPublicKey: Data!
    
    /// The Confirmation Inputs is built over the provisioning process.
    ///
    /// It is composed of (in that order):
    /// - Provisioning Invite PDU,
    /// - Provisioning Capabilities PDU,
    /// - Provisioning Start PDU,
    /// - Provisioner's Public Key,
    /// - Provisionee's Public Key.
    private var confirmationInputs: Data = Data(capacity: 1 + 11 + 5 + 64 + 64)
    
    func prepare(for network: MeshNetwork, networkKey: NetworkKey, unicastAddress: Address) {
        self.networkKey     = networkKey
        self.ivIndex        = network.ivIndex
        self.unicastAddress = unicastAddress
    }
    
    func generateKeys(usingAlgorithm algorithm: Algorithm) throws {
        // Generate Private and Public Keys.
        let (sk, pk) = try Crypto.generateKeyPair(using: algorithm)
        privateKey = sk
        publicKey  = pk
        try provisionerPublicKey = pk.toData()
        
        self.algorithm = algorithm
        
        // Generate Provisioner Random.
        provisionerRandom = Crypto.generateRandom(sizeInBits: algorithm.length)
    }
    
}

internal extension ProvisioningData {
    
    /// This method adds the given PDU to the Provisioning Inputs.
    /// Provisioning Inputs are used for authenticating the Provisioner
    /// and the Unprovisioned Device.
    ///
    /// This method must be called (in order) for:
    /// * Provisioning Invite,
    /// * Provisioning Capabilities,
    /// * Provisioning Start,
    /// * Provisioner's Public Key,
    /// * Provisionee's Public Key.
    func accumulate(pdu: Data) {
        confirmationInputs += pdu
    }
    
    /// Call this method when the Provisionee's Public Key has been
    /// obtained.
    ///
    /// This must be called after generating keys.
    ///
    /// - parameters:
    ///   - key: The Provisionee's Public Key.
    ///   - oob: A flag indicating whether the Public Key was obtained Out-Of-Band.
    /// - throws: This method throws when generating ECDH Secure
    ///           Secret failed.
    func provisionerDidObtain(devicePublicKey key: Data, usingOob oob: Bool) throws {
        guard let _ = privateKey else {
            throw ProvisioningError.invalidState
        }
        do {
            sharedSecret = try Crypto.calculateSharedSecret(privateKey: privateKey, publicKey: key)
            oobPublicKey = oob
        } catch {
            throw ProvisioningError.invalidPublicKey
        }
    }
    
    /// Call this method when the Auth Value has been obtained.
    func provisionerDidObtain(authValue data: Data) {
        authValue = data
    }
    
    /// Call this method when the device Provisioning Confirmation
    /// has been obtained.
    func provisionerDidObtain(deviceConfirmation data: Data) {
        deviceConfirmation = data
    }
    
    /// Call this method when the device Provisioning Random
    /// has been obtained.
    func provisionerDidObtain(deviceRandom data: Data) {
        deviceRandom = data
    }
    
    /// This method validates the received Provisioning Confirmation and
    /// matches it with one calculated locally based on the Provisioning
    /// Random received from the device and Auth Value.
    ///
    /// - throws: The method throws when the validation failed, or
    ///           it was called before all data were ready.
    func validateConfirmation() throws {
        guard let deviceRandom = deviceRandom,
              let authValue = authValue,
              let sharedSecret = sharedSecret else {
            throw ProvisioningError.invalidState
        }
        let confirmation = Crypto.calculateConfirmation(confirmationInputs: confirmationInputs,
                                                        sharedSecret: sharedSecret,
                                                        random: deviceRandom, authValue: authValue,
                                                        using: algorithm)
        guard deviceConfirmation == confirmation else {
            throw ProvisioningError.confirmationFailed
        }
    }
    
    /// Returns the Provisioner Confirmation value.
    ///
    /// The Auth Value must be set prior to calling this method.
    var provisionerConfirmation: Data {
        return Crypto.calculateConfirmation(confirmationInputs: confirmationInputs,
                                            sharedSecret: sharedSecret!,
                                            random: provisionerRandom, authValue: authValue,
                                            using: algorithm)
    }
    
    /// Returns the encrypted Provisioning Data together with MIC.
    ///
    /// Data will be encrypted using Session Key and Session Nonce.
    /// For that, all properties should be set when this method is called.
    /// Returned value is 25 + 8 bytes long, where the MIC is the last 8 bytes.
    var encryptedProvisioningDataWithMic: Data {
        let keys = Crypto.calculateKeys(confirmationInputs: confirmationInputs,
                                        sharedSecret: sharedSecret!,
                                        provisionerRandom: provisionerRandom,
                                        deviceRandom: deviceRandom,
                                        using: algorithm)
        deviceKey = keys.deviceKey
        
        let flags = Flags(ivIndex: ivIndex, networkKey: networkKey)
        let key   = networkKey.phase == .keyDistribution ? networkKey.oldKey! : networkKey.key
        let data  = key + networkKey.index.bigEndian + flags.rawValue
                        + ivIndex.index.bigEndian + unicastAddress.bigEndian
        return Crypto.encrypt(provisioningData: data,
                              usingSessionKey: keys.sessionKey, andNonce: keys.sessionNonce)
    }
    
    /// Returns the Node's security level based on the provisioning method.
    var security: Security {
        return oobPublicKey ? .secure : .insecure
    }
    
}

// MARK: - Helper methods

private struct Flags: OptionSet {
    let rawValue: UInt8
    
    static let useNewKeys     = Flags(rawValue: 1 << 0)
    static let ivUpdateActive = Flags(rawValue: 1 << 1)
    
    init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    
    init(ivIndex: IvIndex, networkKey: NetworkKey) {
        var value: UInt8 = 0
        if case .usingNewKeys = networkKey.phase {
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
