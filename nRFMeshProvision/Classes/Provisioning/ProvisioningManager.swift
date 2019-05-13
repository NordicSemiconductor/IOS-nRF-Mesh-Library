//
//  ProvisioningManager.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 09/05/2019.
//

import Foundation
import Security

public protocol ProvisioningDelegate: class {
    
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
    
    private var privateKey: SecKey?
    
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
            print("New state: \(state)")
            switch state {
            case .invalidState, .complete:
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
        
        state = .invitationSent
        try bearer.send(.invite(attentionTimer: attentionTimer))
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
        state = .provisioningStarted
        try bearer.send(.start(algorithm: algorithm, publicKey: publicKey, authenticationMethod: authenticationMethod))
        
        // Send the Public Key of the Provisioner.
        state = .publicKeySent
        try bearer.send(.publicKey(pk.publicKey()))
        
        // If the device's Public Key was obtained OOB, we are now ready to
        // calculate the device's Shared Secret.
        if case let .oobPublicKey(key: key) = publicKey {
            try calculateSharedSecret(publicKey: key)
        }
    }
}

extension ProvisioningManager: BearerDelegate {
    
    public func bearerDidOpen(_ bearer: Bearer) {
        // This method will not be called, as bearer.delegate is restored
        // when is bearer closed.
    }
    
    public func bearer(_ bearer: Bearer, didClose error: Error?) {
        bearerDelegate?.bearer(bearer, didClose: error)
        bearer.delegate = bearerDelegate
        bearerDelegate = nil
        
        // Clear provisioning data. Provisioning will have to start again.
        provisioningCapabilities = nil
    }
    
    public func bearer(_ bearer: Bearer, didDeliverData data: Data, ofType type: MessageType) {
        bearerDelegate?.bearer(bearer, didDeliverData: data, ofType: type)
        
        // Try parsing the response.
        guard let response = ProvisioningResponse(data) else {
            return
        }
        
        guard response.isValid else {
            print("Error: Failed to parse response")
            state = .invalidState
            return
        }
        
        // Act depending on the current state and the response received.
        switch (state, response.type) {
            
        // Provisioning Capabilities have been received.
        case (.invitationSent, .capabilities):
            let capabilities = response.capabilities!
            provisioningCapabilities = capabilities
            
            // Calculate the Unicast Address automatically based on the
            // elements count.
            if unicastAddress == nil, let provisioner = meshNetwork.localProvisioner {
                let count = capabilities.numberOfElements
                unicastAddress = meshNetwork.nextAvailableUnicastAddress(for: count, elementsUsing: provisioner)
                suggestedUnicastAddress = unicastAddress
            }
            state = .capabilitiesReceived(capabilities)
            
        // Device Public Key has been received.
        case (.publicKeySent, .publicKey):
            let publicKey = response.publicKey!
            do {
                try calculateSharedSecret(publicKey: publicKey)
            } catch {
                print("Error: Generating Shared secret failed: \(error)")
                state = .invalidState
            }
            
        default:
            break
        }
    }
    
}

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
            throw ProvisioningError.securityError(status)
        }
        return (privateKey!, publicKey!)
    }
    
    /// Calculates the Shared Secret based on the given Public Key
    /// and the local Private Key.
    ///
    /// - parameter publicKey: The device's Public Key as bytes.
    private func calculateSharedSecret(publicKey: Data) throws {
        // First byte has to be 0x04 to indicate uncompressed representation.
        var devicePublicKeyData = Data([0x04])
        devicePublicKeyData.append(contentsOf: publicKey)
        
        let pubKeyParameters = [kSecAttrKeyType : kSecAttrKeyTypeECSECPrimeRandom,
                                kSecAttrKeyClass: kSecAttrKeyClassPublic] as CFDictionary
        
        var error: Unmanaged<CFError>?
        let devicePublicKey = SecKeyCreateWithData(devicePublicKeyData as CFData,
                                                   pubKeyParameters, &error)
        guard error == nil else {
            privateKey = nil
            throw error!.takeRetainedValue()
        }
        
        let exchangeResultParams = [kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom] as CFDictionary
        
        let shared = SecKeyCopyKeyExchangeResult(privateKey!,
                                                 SecKeyAlgorithm.ecdhKeyExchangeStandardX963SHA256,
                                                 devicePublicKey!, exchangeResultParams, &error)
        guard error == nil else {
            privateKey = nil
            throw error!.takeRetainedValue()
        }
        
        privateKey = nil
        let ecdh = shared! as Data
        print("Key: \(ecdh.hex)")
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
