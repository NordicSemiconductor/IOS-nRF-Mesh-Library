//
//  ProvisioningManager.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 09/05/2019.
//

import Foundation

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
    
    /// The original Bearer delegate. It will be notified on bearer state updates.
    private weak var bearerDelegate: BearerDelegate?
    
    /// The provisioning delegate will receive provisioning state updates.
    public weak var delegate: ProvisioningDelegate?
    /// The provisioning capabilities of the device. This information
    /// is retrieved from the remote device during identification process.
    public internal(set) var provisioningCapabilities: ProvisioningCapabilities?
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
        
        // Is the Bearer open?
        guard bearer.isOpen else {
            throw BearerError.bearerClosed
        }
        
        // Is the Provisioner Manager in the right state?
        guard case .ready = state else {
            throw ProvisioningError.invalidState
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
                          authenticationMethod: AuthenticationMethod,
                          action: OobAction, size: UInt8) throws {
        
    }
    
}

extension ProvisioningManager: BearerDelegate {
    
    public func bearerDidOpen(_ bearer: Bearer) {
        bearerDelegate?.bearerDidOpen(bearer)
        state = .ready
    }
    
    public func bearer(_ bearer: Bearer, didClose error: Error?) {
        bearerDelegate?.bearer(bearer, didClose: error)
        
        // Unprovisioned device got disconnected. We will have to start again.
        state = .invalidState
        provisioningCapabilities = nil
    }
    
    public func bearer(_ bearer: Bearer, didDeliverData data: Data, ofType type: MessageType) {
        bearerDelegate?.bearer(bearer, didDeliverData: data, ofType: type)
        
        switch state {
        case .invitationSent:
            guard let provisioningCapabilities = ProvisioningCapabilities(data) else {
                print("Error: Failed to parse Provisioning Capabilities")
                state = .invalidState
                return
            }
            self.provisioningCapabilities = provisioningCapabilities
            state = .capabilitiesReceived(provisioningCapabilities)
        default:
            break
        }
    }
    
}
