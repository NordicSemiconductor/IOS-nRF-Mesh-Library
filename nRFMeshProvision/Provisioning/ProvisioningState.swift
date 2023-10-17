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

/// The enum defines possible state of provisioning process.
public enum ProvisioningState {
    /// Provisioning Manager is ready to start.
    case ready
    /// The manager is requesting Provisioning Capabilities from the device.
    case requestingCapabilities
    /// Provisioning Capabilities were received.
    case capabilitiesReceived(_ capabilities: ProvisioningCapabilities)
    /// Provisioning has been started.
    case provisioning
    /// The provisioning process is complete.
    case complete
    /// The provisioning has failed because of a local error.
    case failed(_ error: Error)
}

/// Set of errors which may be thrown during provisioning a device.
public enum ProvisioningError: Error {
    /// Thrown when the ProvisioningManager is in invalid state.
    case invalidState
    /// The received PDU is invalid.
    case invalidPdu
    /// The received Public Key is invalid or equal to Provisioner's Public Key.
    case invalidPublicKey
    /// Thrown when an unsupported algorithm has been selected for provisioning.
    case unsupportedAlgorithm
    /// Thrown when the Unprovisioned Device is not supported by the manager.
    case unsupportedDevice
    /// Thrown when the provided alphanumeric value could not be converted into
    /// bytes using ASCII encoding.
    case invalidOobValueFormat
    /// Thrown when no available Unicast Address was found in the Provisioner's
    /// range that could be allocated for the device.
    case noAddressAvailable
    /// Throws when the Unicast Address has not been set.
    case addressNotSpecified
    /// Throws when the Network Key has not been set.
    case networkKeyNotSpecified
    /// Thrown when confirmation value received from the device does not match
    /// calculated value. Authentication failed.
    case confirmationFailed
    /// Thrown when the remove device sent a failure indication.
    case remoteError(_ error: RemoteProvisioningError)
    /// Thrown when the key pair generation has failed.
    case keyGenerationFailed(_ error: Error)
}

/// Set of errors which may be reported by an unprovisioned device
/// during provisioning process.
public enum RemoteProvisioningError: UInt8 {
    /// The provisioning protocol PDU is not recognized by the device.
    case invalidPdu            = 1
    /// The arguments of the protocol PDUs are outside expected values
    /// or the length of the PDU is different than expected.
    case invalidFormat         = 2
    /// The PDU received was not expected at this moment of the procedure.
    case unexpectedPdu         = 3
    /// The computed confirmation value was not successfully verified.
    case confirmationFailed    = 4
    /// The provisioning protocol cannot be continued due to insufficient
    /// resources in the device.
    case outOfResources        = 5
    /// The Data block was not successfully decrypted.
    case decryptionFailed      = 6
    /// An unexpected error occurred that may not be recoverable.
    case unexpectedError       = 7
    /// The device cannot assign consecutive unicast addresses to all elements.
    case cannotAssignAddresses = 8
    /// The Data block contains values that cannot be accepted because of
    /// general constraints.
    case invalidData           = 9
}

/// A set of authentication actions aiming to strengthen device provisioning
/// security.
public enum AuthAction {
    /// The user shall provide 16 byte OOB Static Key.
    case provideStaticKey(callback: (Data) -> Void)
    /// The user shall provide a number.
    case provideNumeric(maximumNumberOfDigits: UInt8, outputAction: OutputAction, callback: (UInt) -> Void)
    /// The user shall provide an alphanumeric text.
    case provideAlphanumeric(maximumNumberOfCharacters: UInt8, callback: (String) -> Void)
    /// The application should display this number to the user.
    /// User should perform selected action given number of times,
    /// or enter the number on the remote device.
    case displayNumber(_ value: UInt, inputAction: InputAction)
    /// The application should display the text to the user.
    /// User should enter the text on the provisioning device.
    case displayAlphanumeric(_ text: String)
}

extension ProvisioningState: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .ready:
            return "Provisioner is ready"
        case .requestingCapabilities:
            return "Requesting Provisioning Capabilities"
        case .capabilitiesReceived(_):
            return "Provisioning Capabilities received"
        case .provisioning:
            return "Provisioning started"
        case .complete:
            return "Provisioning complete"
        case let .failed(error):
            return "Provisioning failed: \(error.localizedDescription)"
        }
    }
    
}

extension ProvisioningError: LocalizedError {
    
    public var errorDescription: String? {
        switch self {
        case .invalidState:
            return NSLocalizedString("Invalid state", comment: "provisioning")
        case .invalidPdu:
            return NSLocalizedString("Invalid PDU", comment: "provisioning")
        case .invalidPublicKey:
            return NSLocalizedString("Invalid or equal Public Key", comment: "provisioning")
        case .unsupportedAlgorithm:
            return NSLocalizedString("Unsupported algorithm", comment: "provisioning")
        case .unsupportedDevice:
            return NSLocalizedString("Unsupported device", comment: "provisioning")
        case .invalidOobValueFormat:
            return NSLocalizedString("Invalid value format", comment: "provisioning")
        case .noAddressAvailable:
            return NSLocalizedString("No address available in Provisioner's range", comment: "provisioning")
        case .addressNotSpecified:
            return NSLocalizedString("Address not specified", comment: "provisioning")
        case .networkKeyNotSpecified:
            return NSLocalizedString("Network Key not specified", comment: "provisioning")
        case .confirmationFailed:
            return NSLocalizedString("Confirmation failed", comment: "provisioning")
        case let .remoteError(error):
            return NSLocalizedString(error.debugDescription, comment: "provisioning")
        case let .keyGenerationFailed(error):
            return NSLocalizedString("Key generation failed: \(error)", comment: "provisioning")
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
        case .cannotAssignAddresses:
            return "Cannot assign addresses"
        case .invalidData:
            return "Invalid data"
        }
    }
    
}
