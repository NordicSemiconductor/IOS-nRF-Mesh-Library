//
//  ProvisioningManager.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 09/05/2019.
//

import Foundation
import Security

public protocol ProvisioningDelegate: class {
    
    /// Callback called when an authentication action is required
    /// from the user.
    ///
    /// - parameter action: The action to be performed.
    func authenticationActionRequired(_ action: AuthAction)
    
    /// Callback called when the user finished Input Action on the
    /// device.
    func inputComplete()
    
    /// Callback called whenever the provisioning status changes.
    ///
    /// - parameter unprovisionedDevice: The device which state has changed.
    /// - parameter state:               The completed provisioning state.
    func provisioningState(of unprovisionedDevice: UnprovisionedDevice, didChangeTo state: ProvisionigState)
    
}

public class ProvisioningManager {
    private let unprovisionedDevice: UnprovisionedDevice
    private let bearer: ProvisioningBearer
    private let meshNetwork: MeshNetwork
    
    private var authenticationMethod: AuthenticationMethod?
    private var authAction: AuthAction?
    private var privateKey: SecKey?
    private var sharedSecret: Data?
    private var deviceConfirmation: Data?
    private var authValue: Data?
    private var provisionerRandom: Data?
    
    /// The Confirmation Inputs is built over the provisioning process.
    /// It is composed for: Provisioning Invite PDU, Provisioning Capabilities PDU,
    /// Provisioning Start PDU, Provisioner's Public Key and device's Public Key.
    private var confirmationInputs: Data!
    
    /// The original Bearer delegate. It will be notified on bearer state updates.
    private weak var bearerDelegate: BearerDelegate?
    
    // MARK: - Public properties
    
    /// The provisioning capabilities of the device. This information
    /// is retrieved from the remote device during identification process.
    public internal(set) var provisioningCapabilities: ProvisioningCapabilities?
    
    /// The Unicast Address that will be assigned to the device.
    public var unicastAddress: Address?
    
    /// Automatically assigned Unicast Address. This is the first available
    /// Unicast Address from the Provisioner's range with enough free following
    /// addresses to be assigned to the device. This value is available after
    /// the Provisioning Capabilities have been received and such address was found.
    public internal(set) var suggestedUnicastAddress: Address?
    
    /// The Network Key to be sent to the device during provisioning.
    /// Set to `nil` to automatically create a new Network Key.
    public var networkKey: NetworkKey?
    
    /// The provisioning delegate will receive provisioning state updates.
    public weak var delegate: ProvisioningDelegate?
    
    /// The current state of the provisioning process.
    public internal(set) var state: ProvisionigState = .ready {
        didSet {
            switch state {
            case .fail(error: _), .complete:
                // Restore the delegate.
                bearer.delegate = bearerDelegate
                bearerDelegate = nil
            default:
                break
            }
            delegate?.provisioningState(of: unprovisionedDevice, didChangeTo: state)
        }
    }
    
    // MARK: - Computed properties
    
    /// Returns whether the Unicast Address can be used to provision the device.
    /// The Provisioning Capabilities must be obtained proir to using this property,
    /// otherwise the number of device's elements is unknown. Also, the mesh
    /// network must have the local Provisioner set.
    public var isUnicastAddressValid: Bool? {
        guard let provisioner = meshNetwork.localProvisioner,
            let capabilities = provisioningCapabilities,
            let unicastAddress = unicastAddress else {
                // Unknown.
                return nil
        }
        return meshNetwork.isAddressAvailable(unicastAddress, elementsCount: capabilities.numberOfElements) &&
            provisioner.isAddressInAllocatedRange(unicastAddress, elementCount: capabilities.numberOfElements)
    }
    
    /// Returns whether the Unprovisioned Device can be provisioned using this
    /// Provisioner Manager.
    public var isDeviceSupported: Bool? {
        guard let capabilities = provisioningCapabilities else {
                return nil
        }
        return capabilities.algorithms.contains(.fipsP256EllipticCurve)
    }
    
    // MARK: - Implementation
    
    /// Creates the Provisioning Manager that will handle provisioning of the
    /// Unprovisioned Device over the given Provisioning Bearer.
    ///
    /// - parameter unprovisionedDevice: The device to provision into the network.
    /// - parameter bearer:              The Bearer used for sending Provisioning PDUs.
    /// - parameter meshNetwork:         The mesh network to provision the device to.
    public init(for unprovisionedDevice: UnprovisionedDevice, over bearer: ProvisioningBearer, in meshNetwork: MeshNetwork) {
        self.unprovisionedDevice = unprovisionedDevice
        self.bearer = bearer
        self.meshNetwork = meshNetwork
        self.networkKey = meshNetwork.networkKeys.first
    }
    
    /// This method initializes the provisioning of the device.
    ///
    /// - parameter attentionTimer: This value determines for how long (in seconds)
    ///                     the device shall remain attracting human's attention by
    ///                     blinking, flashing, buzzing, etc.
    ///                     The value 0 disables Attention Timer.
    /// - throws: This method throws if the Bearer is not ready.
    public func identify(andAttractFor attentionTimer: UInt8) throws {
        // Does the Bearer support provisioning?
        guard bearer.supports(.provisioningPdu) else {
            throw BearerError.messageTypeNotSupported
        }
        
        // Is the Provisioner Manager in the right state?
        guard case .ready = state else {
            throw ProvisioningError.invalidState
        }
        
        // Is the Bearer open?
        guard bearer.isOpen else {
            throw BearerError.bearerClosed
        }
        
        bearerDelegate = bearer.delegate
        bearer.delegate = self
        
        // Clear the Confirmation Inputs buffer.
        confirmationInputs = Data(capacity: 1 + 11 + 5 + 64 + 64)
        state = .invitationSent
        try send(.invite(attentionTimer: attentionTimer), andAccumulateTo: &confirmationInputs)
    }
    
    /// This method starts the provisioning of the device.
    /// `identify(andAttractFor:)` has to be called prior to this to receive
    /// the device capabilities.
    public func provision(usingAlgorithm algorithm: Algorithm,
                          publicKey: PublicKey,
                          authenticationMethod: AuthenticationMethod) throws {
        // Is the Provisioner Manager in the right state?
        guard case .capabilitiesReceived = state,
            let capabilities = provisioningCapabilities else {
            throw ProvisioningError.invalidState
        }
        
        // Can the Unprovisioned Device be provisioned by this manager?
        guard isDeviceSupported == true else {
            throw ProvisioningError.unsupportedDevice
        }
        
        // An OOB Public Key must be given for devices supporting this.
        if capabilities.publicKeyType.contains(.publicKeyOobInformationAvailable) {
            guard case .oobPublicKey(key: _) = publicKey else {
                throw ProvisioningError.oobPublicKeyRequired
            }
        }
        
        // Is the Bearer open?
        guard bearer.isOpen else {
            throw BearerError.bearerClosed
        }
        
        // Try generating Private and Public Keys. This may fail if the given
        // algorithm is not supported.
        let (sk, pk) = try generateKeyPair(algorithm: algorithm)
        privateKey = sk
        
        // Send Provisioning Start request.
        state = .provisioning
        try send(.start(algorithm: algorithm, publicKey: publicKey,
                        authenticationMethod: authenticationMethod),
                 andAccumulateTo: &confirmationInputs)
        self.authenticationMethod = authenticationMethod
        
        // Send the Public Key of the Provisioner.
        try send(.publicKey(pk.publicKey()), andAccumulateTo: &confirmationInputs)
        
        // If the device's Public Key was obtained OOB, we are now ready to
        // calculate the device's Shared Secret.
        if case let .oobPublicKey(key: key) = publicKey {
            confirmationInputs += key
            sharedSecret = try calculateSharedSecret(publicKey: key)
            obtainAuthValue()
        }
    }
}

extension ProvisioningManager: BearerDelegate {
    
    private func send(_ request: ProvisioningRequest) throws {
       try bearer.send(request)
    }
    
    private func send(_ request: ProvisioningRequest, andAccumulateTo inputs: inout Data) throws {
        let data = request.pdu
        // The first byte is the type. We only accumulate payload.
        inputs += data.dropFirst()
        try bearer.send(data, ofType: .provisioningPdu)
    }
    
    public func bearerDidOpen(_ bearer: Bearer) {
        // This method will not be called, as bearer.delegate is restored
        // when is bearer closed.
    }
    
    public func bearer(_ bearer: Bearer, didClose error: Error?) {
        bearerDelegate?.bearer(bearer, didClose: error)
        if let delegate = bearerDelegate {
            bearer.delegate = delegate
            bearerDelegate = nil
        }
        
        // Clear provisioning data. Provisioning will have to start again.
        authenticationMethod = nil
        privateKey = nil
        sharedSecret = nil
        deviceConfirmation = nil
        provisionerRandom = nil
        confirmationInputs = Data()
        provisioningCapabilities = nil
        state = .ready
    }
    
    public func bearer(_ bearer: Bearer, didDeliverData data: Data, ofType type: MessageType) {
        bearerDelegate?.bearer(bearer, didDeliverData: data, ofType: type)
        
        // Try parsing the response.
        guard let response = ProvisioningResponse(data) else {
            return
        }
        
        guard response.isValid else {
            print("Error: Failed to parse response")
            state = .fail(ProvisioningError.invalidPdu)
            return
        }
        
        // Act depending on the current state and the response received.
        switch (state, response.type) {
            
        // Provisioning Capabilities have been received.
        case (.invitationSent, .capabilities):
            let capabilities = response.capabilities!
            provisioningCapabilities = capabilities
            confirmationInputs += data.dropFirst()
            
            // Calculate the Unicast Address automatically based on the
            // elements count.
            if unicastAddress == nil, let provisioner = meshNetwork.localProvisioner {
                let count = capabilities.numberOfElements
                unicastAddress = meshNetwork.nextAvailableUnicastAddress(for: count, elementsUsing: provisioner)
                suggestedUnicastAddress = unicastAddress
            }
            state = .capabilitiesReceived(capabilities)
            
        // Device Public Key has been received.
        case (.provisioning, .publicKey):
            let publicKey = response.publicKey!
            confirmationInputs += data.dropFirst()
            do {
                sharedSecret = try calculateSharedSecret(publicKey: publicKey)
                obtainAuthValue()
            } catch {
                print("Error: Generating Shared secret failed: \(error)")
                state = .fail(error)
            }
            
        // The user has performed the Input Action on the device.
        case (.provisioning, .inputComplete):
            switch authAction! {
            case let .displayNumber(value, inputAction: _):
                var authValue = Data(repeating: 0, count: 16 - MemoryLayout.size(ofValue: value))
                authValue += value.bigEndian
                authValueReceived(authValue)
            case let .displayAlphanumeric(text):
                var authValue = text.data(using: .ascii)!
                authValue += Data(count: 16 - authValue.count)
                authValueReceived(authValue)
            default:
                // The Input Complete should not be received for other actions.
                break
            }
        
        // The Provisioning Confirmation value has been received.
        case (.provisioning, .confirmation):
            deviceConfirmation = response.confirmation!
            do {
                try send(.random(provisionerRandom!))
            } catch {
                print("Error: Sending Provisioner Random failed: \(error)")
                state = .fail(error)
            }
            
        // The device Random value has been received. We may now authenticate the device.
        case (.provisioning, .random):
            let random = response.random!
            let confirmation = calculateConfirmation(random: random, authValue: authValue!)
            print("Received:   \(deviceConfirmation!.hex)")
            print("Calculated: \(confirmation.hex)")
            
        // The provisioned device sent an error.
        case (_, .failed):
            state = .fail(ProvisioningError.remoteError(response.error!))
            
        default:
            break
        }
    }
    
}

private extension ProvisioningManager {
    
    /// This method asks the user to provide a OOB value based on the
    /// authentication method specified in the provisioning process.
    /// For `.noOob` case, the value is automatically set to 0s.
    /// This method will call `authValueReceived(:)` when the value
    /// has been obtained.
    func obtainAuthValue() {
        switch self.authenticationMethod! {
        // For No OOB, the AuthValue is just 16 byte array filled with 0.
        case .noOob:
            let authValue = Data(repeating: 0, count: 16)
            authValueReceived(authValue)
            
        // For Static OOB, the AuthValue is the Key enetered by the user.
        // The key must be 16 bytes long.
        case .staticOob:
            delegate?.authenticationActionRequired(.provideStaticKey(callback: { key in
                self.authValueReceived(key)
            }))
            
        // For Output OOB, the device will blink, beep, vibrate or display a
        // value, and the user must enter the value on the phone. The entered
        // value becomes a part of the AuthValue.
        case let .outputOob(action: action, size: size):
            switch action {
            case .outputAlphanumeric:
                delegate?.authenticationActionRequired(.provideAlphanumeric(maximumNumberOfCharacters: size, callback: { text in
                    guard var authValue = text.data(using: .ascii) else {
                        self.state = .fail(ProvisioningError.invalidOobValueFormat)
                        return
                    }
                    authValue += Data(count: 16 - authValue.count)
                    self.delegate?.inputComplete()
                    self.authValueReceived(authValue)
                }))
            case .blink, .beep, .vibrate, .outputNumeric:
                delegate?.authenticationActionRequired(.provideNumeric(maximumNumberOfDigits: size, outputAction: action, callback: { value in
                    var authValue = Data(count: 16 - MemoryLayout.size(ofValue: value))
                    authValue += value.bigEndian
                    self.delegate?.inputComplete()
                    self.authValueReceived(authValue)
                }))
            }
            
        case let .inputOob(action: action, size: size):
            switch action {
            case .inputAlphanumeric:
                let random = randomString(length: Int(size))
                delegate?.authenticationActionRequired(.displayAlphanumeric(random))
            case .push, .twist, .inputNumeric:
                let random = randomInt(length: Int(size))
                delegate?.authenticationActionRequired(.displayNumber(random, inputAction: action))
            }
        }
    }

    /// This method should be called when the OOB value has been received
    /// and Auth Value has been calculated.
    /// It computes and sends the Provisioner Confirmation to the device.
    ///
    /// - parameter value: The 16 byte long Auth Value.
    func authValueReceived(_ value: Data) {
        authValue = value
        provisionerRandom = randomData(length: 16)
        
        let confirmationProvisioner = calculateConfirmation(random: provisionerRandom!, authValue: value)
        do {
            try send(.confirmation(confirmationProvisioner))
        } catch {
            print("Error: Sending Provisioning Confirmation failed: \(error)")
            state = .fail(error)
        }
    }
    
}

// MARK: - Helper methods

private extension ProvisioningManager {
    
    /// Generates a pair of Private and Public Keys using P256 Elliptic Curve
    /// algorithm.
    ///
    /// - parameter algorithm: The algorithm for key pair generation.
    /// - returns: The Private and Public Key pair.
    /// - throws: This method throws an error if the key pair generation has failed
    ///           or the given algorithm is not supported.
    func generateKeyPair(algorithm: Algorithm) throws -> (privateKey: SecKey, publicKey: SecKey) {
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
            if #available(iOS 11.3, *) {
                let message = SecCopyErrorMessageString(status, nil)
                print("SecKeyGeneratePair failed with error: \(String(describing: message))")
            } else {
                print("SecKeyGeneratePair failed with error code: \(status)")
            }
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
        
        let ssk = SecKeyCopyKeyExchangeResult(privateKey!,
                                              SecKeyAlgorithm.ecdhKeyExchangeStandardX963SHA256,
                                              devicePublicKey!, exchangeResultParams, &error)
        guard error == nil else {
            throw error!.takeRetainedValue()
        }
        
        return ssk! as Data
    }
    
    /// This method calculates the Provisioning Confirmation based on the
    /// 16-byte Random and 16 byte AuthValue.
    ///
    /// - parameter random:    An array of 16 random bytes.
    /// - parameter authValue: The Auth Value calculated based on the Authentication Method.
    /// - returns: The Provisioning Confirmation value.
    func calculateConfirmation(random: Data, authValue: Data) -> Data {
        let helper = OpenSSLHelper()
        // Calculate the Confirmation Salt = s1(confirmationInputs).
        let confirmationSalt = helper.calculateSalt(confirmationInputs)!
        
        // Calculate the Confirmation Key = k1(ECDH Secret, confirmationSalt, 'prck')
        let confirmationKey  = helper.calculateK1(withN: sharedSecret!,
                                                  salt: confirmationSalt,
                                                  andP: "prck".data(using: .ascii))!
        
        // Calculate the Confirmation Provisioner using CMAC(random + authValue)
        let confirmationData = random + authValue
        return helper.calculateCMAC(confirmationData, andKey: confirmationKey)!
    }
    
    /// Generates a random string of numerics and capital English letters
    /// with given length.
    func randomString(length: Int) -> String {
        let letters = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    /// Generates a random integer with at most `length` digits.
    func randomInt(length: Int) -> Int {
        let upperbound = Int(pow(10.0, Double(length)))
        return Int.random(in: 1...upperbound)
    }
    
    /// Generates an array of cryptographically secure random bytes.
    func randomData(length: Int) -> Data {
        var data = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, length, &data)
        return Data(data)
    }

}

private extension SecKey {
    
    /// Returns the Public Key as Data from the SecKey. The SecKey must contain the
    /// valid public key.
    func publicKey() throws -> Data {
        var error: Unmanaged<CFError>?
        guard let representation = SecKeyCopyExternalRepresentation(self, &error) else {
            throw error!.takeRetainedValue()
        }
        let data = representation as Data
        // First is 0x04 to indicate uncompressed representation.
        return data.dropFirst()
    }
    
}
