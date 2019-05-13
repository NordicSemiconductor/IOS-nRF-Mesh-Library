//
//  ProvisioningState.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 07/05/2019.
//

import Foundation

public enum ProvisionigState {
    /// Provisioning has not been started.
    case ready
    /// Provisioning Invite has been sent.
    case invitationSent
    /// Provisioning Capabilities were received.
    case capabilitiesReceived(_ capabilities: ProvisioningCapabilities)
    /// Provisioning method has been sent.
    case provisioningStarted
    /// The Provisioner and Unprovisioned Device have exchanged Public Keys
    /// and have calculated ECDH Shared Secret.
    case sharedSecretCalculated
    
    // TODO: finish
    
    /// The provisioning process is complete.
    case complete
    /// Set when the device is in invalid state or sent invalida data.
    /// For example, when the Provisioning Invite has been send and
    /// is sent for the second time.
    case invalidState
}

public enum ProvisioningError: Error {
    /// Thrown when the ProvisioningManager is in invalid state.
    case invalidState
    /// Thrown when an unsupported algorighm has been selected for provisioning.
    case unsupportedAlgorithm
    /// Thrown when the Unprovisioned Device is not supported by the manager.
    case unsupportedDevice
    /// Thrown when the Unprovisioned Device exposes its Public Key via an OOB
    /// mechanism, but the key was not provided.
    case oobPublicKeyRequired
    /// Thrown when a security error occured during key pair generation.
    case securityError(_ errorCode: OSStatus)
}

extension ProvisionigState: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .ready:
            return "Provisioner is ready"
        case .invitationSent:
            return "Provisioning Invitation sent"
        case .capabilitiesReceived(let capabilities):
            return "Provisioning Capabilities received:\n\(capabilities)"
        case .provisioningStarted:
            return "Provisioning started"
        case .sharedSecretCalculated:
            return "ECDH Shared Secret calculated"
        case .complete:
            return "Provisioning complete"
        case .invalidState:
            return "Invalid state"
        }
    }
    
}
