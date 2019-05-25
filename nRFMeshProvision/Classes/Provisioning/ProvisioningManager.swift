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
    private let helper = OpenSSLHelper()
    
    private let unprovisionedDevice: UnprovisionedDevice
    private let bearer: ProvisioningBearer
    private let meshNetwork: MeshNetwork
    
    private var authenticationMethod: AuthenticationMethod!
    private var authAction: AuthAction!
    private var provisioningData: ProvisioningData!
    
    /// The original Bearer delegate. It will be notified on bearer state updates.
    private weak var bearerDelegate: BearerDelegate?
    private weak var bearerDataDelegate: BearerDataDelegate?
    
    // MARK: - Public properties
    
    /// The provisioning capabilities of the device. This information
    /// is retrieved from the remote device during identification process.
    public private(set) var provisioningCapabilities: ProvisioningCapabilities?
    
    /// The Unicast Address that will be assigned to the device.
    /// After device capabilies are received, the address is automatically set to
    /// the first available unicast address from Provisioner's range.
    public var unicastAddress: Address?
    
    /// Automatically assigned Unicast Address. This is the first available
    /// Unicast Address from the Provisioner's range with enough free following
    /// addresses to be assigned to the device. This value is available after
    /// the Provisioning Capabilities have been received and such address was found.
    public private(set) var suggestedUnicastAddress: Address?
    
    /// The Network Key to be sent to the device during provisioning.
    /// Setting this proeprty is mandatory before calling
    /// `provision(usingAlgorithm:publicKey:authenticationMethod)`.
    public var networkKey: NetworkKey?
    
    /// The provisioning delegate will receive provisioning state updates.
    /// It is required if the authentication method is set to other value
    /// than `.noOob`.
    public weak var delegate: ProvisioningDelegate?
    
    /// The current state of the provisioning process.
    public private(set) var state: ProvisionigState = .ready {
        didSet {
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
            throw BearerError.pduTypeNotSupported
        }
        
        // Has the provisioning been restarted?
        if case .fail = state {
            reset()
        }
        
        // Is the Provisioner Manager in the right state?
        guard case .ready = state else {
            throw ProvisioningError.invalidState
        }
        
        // Is the Bearer open?
        guard bearer.isOpen else {
            throw BearerError.bearerClosed
        }
        
        // Assign bearer delegate to self. If one was already set, events
        // will be forwarded. Don't modify Bearer delegate from now on.
        bearerDelegate = bearer.delegate
        bearerDataDelegate = bearer.dataDelegate
        bearer.delegate = self
        bearer.dataDelegate = self
        
        // Initialize provisioning data.
        provisioningData = ProvisioningData()
        
        state = .requestingCapabilities
        try send(.invite(attentionTimer: attentionTimer), andAccumulateTo: provisioningData)
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
        
        // Was the Unicast Address specified?
        if unicastAddress == nil {
            unicastAddress = suggestedUnicastAddress
        }
        guard let unicastAddress = unicastAddress else {
            throw ProvisioningError.addressNotSpecified
        }
        
        // Ensure the Network Key is set.
        guard let networkKey = networkKey else {
            throw ProvisioningError.networkKeyNotSpecified
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
        try provisioningData.generateKeys(usingAlgorithm: algorithm)
        
        // If the device's Public Key was obtained OOB, we are now ready to
        // calculate the device's Shared Secret.
        if case let .oobPublicKey(key: key) = publicKey {
            try provisioningData.provisionerDidObtain(devicePublicKey: key)
        }
        
        // Send Provisioning Start request.
        state = .provisioning
        provisioningData.prepare(for: meshNetwork,
                                 networkKey: networkKey,
                                 unicastAddress: unicastAddress)
        try send(.start(algorithm: algorithm, publicKey: publicKey,
                        authenticationMethod: authenticationMethod),
                 andAccumulateTo: provisioningData)
        self.authenticationMethod = authenticationMethod
        
        // Send the Public Key of the Provisioner.
        try send(.publicKey(provisioningData.provisionerPublicKey), andAccumulateTo: provisioningData)
        
        // If the device's Public Key was obtained OOB, we are now ready to
        // authenticate.
        if case let .oobPublicKey(key: key) = publicKey {
            provisioningData.accumulate(pdu: key)
            obtainAuthValue()
        }
    }
}

extension ProvisioningManager: BearerDelegate, BearerDataDelegate {
    
    /// This method sends the provisioning request to the device
    /// over the Bearer specified in the init.
    ///
    /// - parameter request: The request to be sent.
    private func send(_ request: ProvisioningRequest) throws {
       try bearer.send(request)
    }
    
    /// This method sends the provisioning request to the device
    /// over the Bearer specified in the init. Additionally, it
    /// adds the request payload to given inputs. Inputs are
    /// required in device authorization.
    ///
    /// - parameter request: The request to be sent.
    /// - parameter inputs:  The Provisioning Inputs.
    private func send(_ request: ProvisioningRequest, andAccumulateTo data: ProvisioningData) throws {
        let pdu = request.pdu
        // The first byte is the type. We only accumulate payload.
        data.accumulate(pdu: pdu.dropFirst())
        try bearer.send(pdu, ofType: .provisioningPdu)
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
        if let dataDelegate = bearerDataDelegate {
            bearer.dataDelegate = dataDelegate
            bearerDataDelegate = nil
        }
        
        reset()
    }
    
    public func bearer(_ bearer: Bearer, didDeliverData data: Data, ofType type: PduType) {
        bearerDataDelegate?.bearer(bearer, didDeliverData: data, ofType: type)
        
        // Try parsing the response.
        guard let response = ProvisioningResponse(data) else {
            return
        }
        
        guard response.isValid else {
            state = .fail(ProvisioningError.invalidPdu)
            return
        }
        
        // Act depending on the current state and the response received.
        switch (state, response.type) {
            
        // Provisioning Capabilities have been received.
        case (.requestingCapabilities, .capabilities):
            let capabilities = response.capabilities!
            provisioningCapabilities = capabilities
            provisioningData.accumulate(pdu: data.dropFirst())
            
            // Calculate the Unicast Address automatically based on the
            // elements count.
            if unicastAddress == nil, let provisioner = meshNetwork.localProvisioner {
                let count = capabilities.numberOfElements
                unicastAddress = meshNetwork.nextAvailableUnicastAddress(for: count, elementsUsing: provisioner)
                suggestedUnicastAddress = unicastAddress
            }
            state = .capabilitiesReceived(capabilities)
            if unicastAddress == nil {
                state = .fail(ProvisioningError.noAddressAvailable)
            }
            
        // Device Public Key has been received.
        case (.provisioning, .publicKey):
            let publicKey = response.publicKey!
            provisioningData.accumulate(pdu: data.dropFirst())
            do {
                try provisioningData.provisionerDidObtain(devicePublicKey: publicKey)
                obtainAuthValue()
            } catch {
                state = .fail(error)
            }
            
        // The user has performed the Input Action on the device.
        case (.provisioning, .inputComplete):
            delegate?.inputComplete()
            switch authAction! {
            case let .displayNumber(value, inputAction: _):
                var authValue = Data(count: 16 - MemoryLayout.size(ofValue: value))
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
            provisioningData.provisionerDidObtain(deviceConfirmation: response.confirmation!)
            do {
                try send(.random(provisioningData.provisionerRandom))
            } catch {
                state = .fail(error)
            }
            
        // The device Random value has been received. We may now authenticate the device.
        case (.provisioning, .random):
            provisioningData.provisionerDidObtain(deviceRandom: response.random!)
            do {
                try provisioningData.validateConfirmation()
                try send(.data(provisioningData.encryptedProvisioningDataWithMic))
            } catch {
                state = .fail(error)
                return
            }
            
        // The provisioning process is complete.
        case (.provisioning, .complete):
            let deviceKey = provisioningData.deviceKey!
            let node = Node(for: unprovisionedDevice, withDeviceKey: deviceKey,
                            andAssignedNetworkKey: provisioningData.networkKey,
                            andAddress: provisioningData.unicastAddress)
            meshNetwork.add(node: node)
            state = .complete
            
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
            let authValue = Data(count: 16)
            authValueReceived(authValue)
            
        // For Static OOB, the AuthValue is the Key enetered by the user.
        // The key must be 16 bytes long.
        case .staticOob:
            delegate?.authenticationActionRequired(.provideStaticKey(callback: { key in
                self.delegate?.inputComplete()
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
                let random = randomString(length: UInt(size))
                authAction = .displayAlphanumeric(random)
            case .push, .twist, .inputNumeric:
                let random = randomInt(length: UInt(size))
                authAction = .displayNumber(random, inputAction: action)
            }
            delegate?.authenticationActionRequired(authAction!)
        }
    }

    /// This method should be called when the OOB value has been received
    /// and Auth Value has been calculated.
    /// It computes and sends the Provisioner Confirmation to the device.
    ///
    /// - parameter value: The 16 byte long Auth Value.
    func authValueReceived(_ value: Data) {
        authAction = nil
        provisioningData.provisionerDidObtain(authValue: value)
        do {
            try send(.confirmation(provisioningData.provisionerConfirmation))
        } catch {
            state = .fail(error)
        }
    }
    
    func reset() {
        authenticationMethod = nil
        provisioningCapabilities = nil
        provisioningData = nil
        state = .ready
    }
    
}

// MARK: - Helper methods

private extension ProvisioningManager {
    
    /// Generates a random string of numerics and capital English letters
    /// with given length.
    func randomString(length: UInt) -> String {
        let letters = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    /// Generates a random integer with at most `length` digits.
    func randomInt(length: UInt) -> UInt {
        let upperbound = UInt(pow(10.0, Double(length)))
        return UInt.random(in: 1..<upperbound)
    }

}
