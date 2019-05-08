//
//  ProvisioningState.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 07/05/2019.
//

import Foundation

public enum ProvisionigState {
    /// Provisioning Invite has been sent.
    case invitationSent
    /// Provisioning Capabilities were received.
    case capabilitiesReceived(_ capabilities: ProvisioningCapabilities)
    /// Provisioning method has been sent.
    case provisioningStarted
    /// The Provisioner has sent its Public Key.
    case publicKeySent
    
    // TODO: finish
}

extension ProvisionigState: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .invitationSent:
            return "Invitation sent"
        case .capabilitiesReceived(let capabilities):
            return "Provisioning Capabilities received:\n\(capabilities)"
        case .provisioningStarted:
            return "Provisioning started"
        case .publicKeySent:
            return "Provisioner's Public Key sent"
        }
    }
    
}
