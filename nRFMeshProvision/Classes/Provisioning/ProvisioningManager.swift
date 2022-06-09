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

public protocol ProvisioningDelegate: AnyObject {
    
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
    func provisioningState(of unprovisionedDevice: UnprovisionedDevice, didChangeTo state: ProvisioningState)
    
}



open class ProvisioningManager {
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
    /// After device capabilities are received, the address is automatically set to
    /// the first available unicast address from Provisioner's range.
    public var unicastAddress: Address?
    
    /// Automatically assigned Unicast Address. This is the first available
    /// Unicast Address from the Provisioner's range with enough free following
    /// addresses to be assigned to the device. This value is available after
    /// the Provisioning Capabilities have been received and such address was found.
    public private(set) var suggestedUnicastAddress: Address?
    
    /// The Network Key to be sent to the device during provisioning.
    /// Setting this property is mandatory before calling
    /// `provision(usingAlgorithm:publicKey:authenticationMethod)`.
    public var networkKey: NetworkKey?
    
    /// The provisioning delegate will receive provisioning state updates.
    /// It is required if the authentication method is set to other value
    /// than `.noOob`.
    public weak var delegate: ProvisioningDelegate?
    
    /// The logger delegate will be called whenever a new log entry is created.
    public weak var logger: LoggerDelegate?
    
    /// The current state of the provisioning process.
    public private(set) var state: ProvisioningState = .ready {
        didSet {
            if case .fail = state {
                logger?.e(.provisioning, "\(state)")
            } else {
                logger?.i(.provisioning, "\(state)")
            }
            delegate?.provisioningState(of: unprovisionedDevice, didChangeTo: state)
        }
    }
    
    // MARK: - Computed properties
    
    /// Returns whether the Unicast Address can be used to provision the device.
    /// The Provisioning Capabilities must be obtained prior to using this property,
    /// otherwise the number of device's elements is unknown. Also, the mesh
    /// network must have the local Provisioner set.
    public var isUnicastAddressValid: Bool? {
        guard let provisioner = meshNetwork.localProvisioner,
              let capabilities = provisioningCapabilities,
              let unicastAddress = unicastAddress else {
                // Unknown.
                return nil
        }
        return meshNetwork.isAddressRangeAvailable(unicastAddress,
                                                   elementsCount: capabilities.numberOfElements) &&
               provisioner.isAddressInAllocatedRange(unicastAddress,
                                                     elementCount: capabilities.numberOfElements)
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
    public init(for unprovisionedDevice: UnprovisionedDevice,
                over bearer: ProvisioningBearer, in meshNetwork: MeshNetwork) {
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
            logger?.e(.provisioning, "Bearer does not support provisioning PDU")
            throw BearerError.pduTypeNotSupported
        }
        
        // Has the provisioning been restarted?
        if case .fail = state {
            reset()
        }
        
        // Is the Provisioner Manager in the right state?
        guard case .ready = state else {
            logger?.e(.provisioning, "Provisioning manager is in invalid state")
            throw ProvisioningError.invalidState
        }
        
        // Is the Bearer open?
        guard bearer.isOpen else {
            logger?.e(.provisioning, "Bearer closed")
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
        let provisioningInvite = ProvisioningRequest.invite(attentionTimer: attentionTimer)
        logger?.v(.provisioning, "Sending \(provisioningInvite)")
        try send(provisioningInvite, andAccumulateTo: provisioningData)
    }
    
    /// This method starts the provisioning of the device.
    /// `identify(andAttractFor:)` has to be called prior to this to receive
    /// the device capabilities.
    public func provision(usingAlgorithm algorithm: Algorithm,
                          publicKey: PublicKey,
                          authenticationMethod: AuthenticationMethod) throws {
        // Is the Provisioner Manager in the right state?
        guard case .capabilitiesReceived = state,
            let _ = provisioningCapabilities else {
                logger?.e(.provisioning, "Provisioning manager is in invalid state")
            throw ProvisioningError.invalidState
        }
        
        // Can the Unprovisioned Device be provisioned by this manager?
        guard isDeviceSupported == true else {
            logger?.e(.provisioning, "Device not supported")
            throw ProvisioningError.unsupportedDevice
        }
        
        // Was the Unicast Address specified?
        if unicastAddress == nil {
            unicastAddress = suggestedUnicastAddress
        }
        guard let unicastAddress = unicastAddress else {
            logger?.e(.provisioning, "Unicast Address not specified")
            throw ProvisioningError.addressNotSpecified
        }
        
        // Ensure the Network Key is set.
        guard let networkKey = networkKey else {
            logger?.e(.provisioning, "Network Key not specified")
            throw ProvisioningError.networkKeyNotSpecified
        }
        
        // Is the Bearer open?
        guard bearer.isOpen else {
            logger?.e(.provisioning, "Bearer closed")
            throw BearerError.bearerClosed
        }
        
        // Try generating Private and Public Keys. This may fail if the given
        // algorithm is not supported.
        try provisioningData.generateKeys(usingAlgorithm: algorithm)
        
        // If the device's Public Key was obtained OOB, we are now ready to
        // calculate the device's Shared Secret.
        if case let .oobPublicKey(key: key) = publicKey {
            do {
                try provisioningData.provisionerDidObtain(devicePublicKey: key)
            } catch {
                state = .fail(error)
                return
            }
        }
        
        // Send Provisioning Start request.
        state = .provisioning
        provisioningData.prepare(for: meshNetwork,
                                 networkKey: networkKey,
                                 unicastAddress: unicastAddress)
        let provisioningStart = ProvisioningRequest.start(algorithm: algorithm, publicKey: publicKey,
                                                          authenticationMethod: authenticationMethod)
        logger?.v(.provisioning, "Sending \(provisioningStart)")
        try send(provisioningStart, andAccumulateTo: provisioningData)
        self.authenticationMethod = authenticationMethod
        
        // Send the Public Key of the Provisioner.
        let provisioningPublicKey = ProvisioningRequest.publicKey(provisioningData.provisionerPublicKey)
        logger?.v(.provisioning, "Sending \(provisioningPublicKey)")
        try send(provisioningPublicKey, andAccumulateTo: provisioningData)
        
        // If the device's Public Key was obtained OOB, we are now ready to
        // authenticate.
        if case let .oobPublicKey(key: key) = publicKey {
            provisioningData.accumulate(pdu: key)
            obtainAuthValue()
        }
    }
    
    open func generateOobString(size: UInt) -> String {
        return String.randomAlphanumeric(length: UInt(size))
    }
    
    open func generateOobInt(size: UInt) -> UInt {
        return UInt.random(length: UInt(size))
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
        
        // Restore original delegates.
        bearer.delegate = bearerDelegate
        bearer.dataDelegate = bearerDataDelegate
        bearerDelegate = nil
        bearerDataDelegate = nil
        
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
        logger?.v(.provisioning, "\(response) received")
        
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
                let provisioningRandom = ProvisioningRequest.random(provisioningData.provisionerRandom)
                logger?.v(.provisioning, "Sending \(provisioningRandom)")
                try send(provisioningRandom)
            } catch {
                state = .fail(error)
            }
            
        // The device Random value has been received. We may now authenticate the device.
        case (.provisioning, .random):
            provisioningData.provisionerDidObtain(deviceRandom: response.random!)
            do {
                try provisioningData.validateConfirmation()
                let encryptedData = ProvisioningRequest.data(provisioningData.encryptedProvisioningDataWithMic)
                logger?.v(.provisioning, "Sending \(encryptedData)")
                try send(encryptedData)
            } catch {
                state = .fail(error)
            }
            
        // The provisioning process is complete.
        case (.provisioning, .complete):
            let deviceKey = provisioningData.deviceKey!
            let n = provisioningCapabilities!.numberOfElements
            let node = Node(for: unprovisionedDevice, with: n, elementsDeviceKey: deviceKey,
                            andAssignedNetworkKey: provisioningData.networkKey,
                            andAddress: provisioningData.unicastAddress)
            do {
                try meshNetwork.add(node: node)
                state = .complete
            } catch {
                state = .fail(error)
            }
            
        // The provisioned device sent an error.
        case (_, .failed):
            state = .fail(ProvisioningError.remoteError(response.error!))
            
        default:
            state = .fail(ProvisioningError.invalidState)
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
            
        // For Static OOB, the AuthValue is the Key entered by the user.
        // The key must be 16 bytes long.
        case .staticOob:
            delegate?.authenticationActionRequired(.provideStaticKey(callback: { key in
                guard self.bearer.isOpen else {
                    self.state = .fail(BearerError.bearerClosed)
                    return
                }
                guard case .provisioning = self.state, let _ = self.provisioningData else {
                    self.state = .fail(ProvisioningError.invalidState)
                    return
                }
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
                    guard self.bearer.isOpen else {
                        self.state = .fail(BearerError.bearerClosed)
                        return
                    }
                    guard case .provisioning = self.state, let _ = self.provisioningData else {
                        self.state = .fail(ProvisioningError.invalidState)
                        return
                    }
                    authValue += Data(count: 16 - authValue.count)
                    self.delegate?.inputComplete()
                    self.authValueReceived(authValue)
                }))
            case .blink, .beep, .vibrate, .outputNumeric:
                delegate?.authenticationActionRequired(.provideNumeric(maximumNumberOfDigits: size, outputAction: action, callback: { value in
                    guard self.bearer.isOpen else {
                        self.state = .fail(BearerError.bearerClosed)
                        return
                    }
                    guard case .provisioning = self.state, let _ = self.provisioningData else {
                        self.state = .fail(ProvisioningError.invalidState)
                        return
                    }
                    var authValue = Data(count: 16 - MemoryLayout.size(ofValue: value))
                    authValue += value.bigEndian
                    self.delegate?.inputComplete()
                    self.authValueReceived(authValue)
                }))
            }
            
        case let .inputOob(action: action, size: size):
            switch action {
            case .inputAlphanumeric:
                authAction = .displayAlphanumeric(generateOobString(size: UInt(size)))
            case .push, .twist, .inputNumeric:
                authAction = .displayNumber(generateOobInt(size: UInt(size)), inputAction: action)
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
            let provisioningConfirmation = ProvisioningRequest.confirmation(provisioningData.provisionerConfirmation)
            logger?.v(.provisioning, "Sending \(provisioningConfirmation)")
            try send(provisioningConfirmation)
        } catch {
            state = .fail(error)
        }
    }
    
    /// Resets the provisioning properties and state.
    func reset() {
        authenticationMethod = nil
        provisioningCapabilities = nil
        provisioningData = nil
        state = .ready
    }
    
}

// MARK: - Helper methods

private extension String {
    /// Generates a random string of numerics and capital English letters
    /// with given length.
    static func randomAlphanumeric(length: UInt) -> Self {
        let letters = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        return Self((0..<length).lazy.map{ _ in letters.randomElement()! })
    }
}

private extension UInt {
    /// Generates a random integer with at most `length` digits.
    static func random(length digits: UInt) -> UInt {
        let upperbound = UInt(pow(10.0, Double(digits)))
        return Self.random(in: 1..<upperbound)
    }
}
