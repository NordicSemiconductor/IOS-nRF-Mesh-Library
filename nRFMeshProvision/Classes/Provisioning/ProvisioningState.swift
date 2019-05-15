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
    /// Provisioning has been started.
    case provisioning
    /// The provisioning process is complete.
    case complete
    /// The provisioning has failed because of a local error.
    case fail(_ error: Error)
}

public enum ProvisioningError: Error {
    /// Thrown when the ProvisioningManager is in invalid state.
    case invalidState
    /// The received PDU is invalid.
    case invalidPdu
    /// Thrown when an unsupported algorighm has been selected for provisioning.
    case unsupportedAlgorithm
    /// Thrown when the Unprovisioned Device is not supported by the manager.
    case unsupportedDevice
    /// Thrown when the Unprovisioned Device exposes its Public Key via an OOB
    /// mechanism, but the key was not provided.
    case oobPublicKeyRequired
    /// Thrown when the provided alphanumberic value could not be converted into
    /// bytes using ASCII encoding.
    case invalidOobValueFormat
    /// Thrown when the remove device sent a failure indication.
    case remoteError(_ error: RemoteProvisioningError)
    /// Thrown when the key pair generation has failed.
    case keyGenerationFailed(_ error: OSStatus)
}

public enum RemoteProvisioningError: UInt8 {
    /// The provisioning protocol PDU is not recognized by the device.
    case invalidPdu
    /// The arguments of the protocol PDUs are outside expected values
    /// or the length of the PDU is different than expected.
    case invalidFormat
    /// The PDU received was not expected at this moment of the procedure.
    case unexpectedPdu
    /// The computed confirmation value was not successfully verified.
    case confirmationFailed
    /// The provisioning protocol cannot be continued due to insufficient
    /// resources in the device.
    case outOfResources
    /// The Data block was not successfully decrypted.
    case decryptionFailed
    /// An unexpected error occurred that may not be recoverable.
    case unexpectedError
    /// The device cannot assign consecutive unicast addresses to all elements.
    case cannotAcssignAddresses
}

public enum AuthAction {
    /// The user shall provide 16 byte OOB Static Key.
    case provideStaticKey(callback: (Data) -> Void)
    /// The user shall provide a number.
    case provideNumeric(maximumNumberOfDigits: UInt8, outputAction: OutputAction, callback: (Int) -> Void)
    /// The user shall provide an alphanumeric text.
    case provideAlphanumeric(maximumNumberOfCharacters: UInt8, callback: (String) -> Void)
    /// The application should display this number to the user.
    /// User should perform selected action given number of times,
    /// or enter the number on the remote device.
    case displayNumber(_ value: Int, inputAction: InputAction)
    /// The application should display the text to the user.
    /// User should enter the text on the provisioning device.
    case displayAlphanumeric(_ text: String)
}

extension ProvisionigState: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .ready:
            return "Provisioner is ready"
        case .invitationSent:
            return "Provisioning Invitation sent"
        case let .capabilitiesReceived(capabilities):
            return "Provisioning Capabilities received:\n\(capabilities)"
        case .provisioning:
            return "Provisioning started"
        case .complete:
            return "Provisioning complete"
        case let .fail(error):
            return "Provisioning failed: \(error)"
        }
    }
    
}

extension ProvisioningError: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .invalidState:
            return "Invalid state"
        case .invalidPdu:
            return "Invalid PDU"
        case .unsupportedAlgorithm:
            return "Unsupported algorighm"
        case .unsupportedDevice:
            return "Unsupported Device"
        case .oobPublicKeyRequired:
            return "OOB Public Key required"
        case .invalidOobValueFormat:
            return "Invalid value format"
        case let .remoteError(error):
            return "\(error)"
        case let .keyGenerationFailed(status):
            return "Key generation failed with status \(status)"
        }
    }
    
}

extension RemoteProvisioningError: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .invalidPdu:
            return "Invalid PDU"
        case .invalidFormat:
            return "Invalid format"
        case .unexpectedPdu:
            return "Unexpected PDU"
        case .confirmationFailed:
            return "Confirmation failed"
        case .outOfResources:
            return "Out of resources"
        case .decryptionFailed:
            return "Decryption failed"
        case .unexpectedError:
            return "Unexpected error"
        case .cannotAcssignAddresses:
            return "Cannot assign addresses"
        }
    }
    
}
