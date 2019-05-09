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
    /// The Provisioner has sent its Public Key.
    case publicKeySent
    
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
}

extension ProvisionigState: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .ready:
            return "Provisioner is ready"
        case .invitationSent:
            return "Invitation sent"
        case .capabilitiesReceived(let capabilities):
            return "Provisioning Capabilities received:\n\(capabilities)"
        case .provisioningStarted:
            return "Provisioning started"
        case .publicKeySent:
            return "Provisioner's Public Key sent"
        case .complete:
            return "Provisioning complete"
        case .invalidState:
            return "Invalid state"
        }
    }
    
}
