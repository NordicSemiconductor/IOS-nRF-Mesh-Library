/*
* Copyright (c) 2025, Nordic Semiconductor
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

/// The Firmware ID state identifies a firmware image on the Node or on any subsystem
/// within the Node.
///
/// The Firmware ID consists of a Company Identifier and an optional vendor-specific version identifier
/// and is used to identify the firmware image on a Node.
///
/// The Firmware ID is used by the Firmware Distribution Server to query new firmware image
/// based on the current Firmware ID. If should identify the device type and firmware version.
public struct FirmwareId: Sendable, Equatable {
    /// The 16-bit Company Identifier (CID) assigned by the Bluetooth SIG.
    ///
    /// Company Identifiers are published in
    /// [Assigned Numbers](https://www.bluetooth.com/specifications/assigned-numbers/).
    public let companyIdentifier: UInt16
    /// Vendor-specific information describing the firmware binary package.
    ///
    /// The version information shall be 0-106 bytes long.
    public let version: Data
    
    public init(companyIdentifier: UInt16, version: Data) {
        self.companyIdentifier = companyIdentifier
        self.version = version
    }
    
    public static func == (lhs: FirmwareId, rhs: FirmwareId) -> Bool {
        return lhs.companyIdentifier == rhs.companyIdentifier &&
               lhs.version == rhs.version
    }
}

/// The status codes for the Firmware Update Server model and the
/// Firmware Update Client model.
public enum FirmwareUpdateMessageStatus: UInt8, Sendable {
    /// The message was processed successfully.
    case success                 = 0x00
    /// Insufficient resources on the Node.
    case insufficientResources   = 0x01
    /// The operation cannot be performed while the server is in the current phase.
    case wrongPhase              = 0x02
    /// An internal error occurred on the Node.
    case internalError           = 0x03
    /// The message contains a firmware index value that is not expected.
    case wrongFirmwareIndex      = 0x04
    /// The metadata check failed.
    case metadataCheckFailed     = 0x05
    /// The server cannot start a firmware update.
    case temporarilyUnavailable  = 0x06
    /// Another BLOB transfer is in progress.
    case blobTransferBusy        = 0x07
}

/// The status codes for the Firmware Distribution Server model and the
/// Firmware Distribution Client model.
public enum FirmwareDistributionMessageStatus: UInt8, Sendable {
    /// The message was processed successfully.
    case success                 = 0x00
    /// Insufficient resources on the Node.
    case insufficientResources   = 0x01
    /// The operation cannot be performed while the server is in the current phase.
    case wrongPhase              = 0x02
    /// An internal error occurred on the node.
    case internalError           = 0x03
    /// The requested firmware image is not stored on the Distributor.
    case firmwareNotFound        = 0x04
    /// The AppKey identified by the AppKey Index is not known to the Node.
    case invalidAppKeyIndex      = 0x05
    /// There are no Target nodes in the Distribution Receivers List state.
    case receiversListEmpty      = 0x06
    /// Another firmware image distribution is in progress.
    case busyWithDistribution    = 0x07
    /// Another upload is in progress.
    case busyWithUpload          = 0x08
    /// The URI scheme name indicated by the Update URI is not supported.
    case uriNotSupported         = 0x09
    /// The format of the Update URI is invalid.
    case uriMalformed            = 0x0A
    /// The URI is unreachable.
    case uriUnreachable          = 0x0B
    /// The Check Firmware OOB procedure did not find any new firmware.
    case newFirmwareNotAvailable = 0x0C
    /// The suspension of the Distribute Firmware procedure failed.
    case suspendFailed           = 0x0D
}

/// The Update Phase state identifies the firmware update phase of the
/// Firmware Update Server.
public enum FirmwareUpdatePhase: UInt8, Sendable {
    /// Ready to start a Receive Firmware procedure.
    case idle = 0x0
    /// The Transfer BLOB procedure failed.
    case transferError = 0x1
    /// The Receive Firmware procedure is being executed.
    case transferActive = 0x2
    /// The Verify Firmware procedure is being executed.
    case verifyingUpdate = 0x3
    /// The Verify Firmware procedure completed successfully.
    case verificationSucceeded = 0x4
    /// The Verify Firmware procedure failed.
    case verificationFailed = 0x5
    /// The Apply New Firmware procedure is being executed.
    case applyingUpdate = 0x6
}

/// The Retrieved Update Phase field identifies the phase of the firmware update
/// on the Firmware Update Server.
///
/// The value of the Retrieved Update Phase field is either the retrieved value of
/// the Update Phase state or a value set by the client.
public enum RetrievedUpdatePhase: UInt8, Sendable {
    /// No firmware transfer is in progress.
    case idle = 0x0
    /// Firmware transfer was not completed.
    case transferError = 0x1
    /// Firmware transfer is in progress.
    case transferActive = 0x2
    /// Verification of the firmware image is in progress.
    case verifyingUpdate = 0x3
    /// Firmware image verification succeeded.
    case verificationSucceeded = 0x4
    /// Firmware image verification failed.
    case verificationFailed = 0x5
    /// Firmware applying is in progress.
    case applyingUpdate = 0x6
    /// Firmware transfer has been canceled.
    case transferCanceled = 0x7
    /// Firmware applying succeeded.
    case applySuccess = 0x8
    /// Firmware applying failed.
    case applyFailed = 0x9
    /// Phase of a Node was not yet retrieved.
    ///
    /// This phase should never be reported by a Node.
    case unknown = 0xA
}

/// The Distribution Phase state indicates the phase of a firmware image distribution
/// being performed by the Firmware Distribution Server.
public enum FirmwareDistributionPhase: UInt8, Sendable {
    /// No firmware distribution is in progress.
    case idle              = 0x00
    /// Firmware distribution is in progress.
    case transferActive    = 0x01
    /// The Transfer BLOB procedure has completed successfully.
    case transferSuccess   = 0x02
    /// The Apply Firmware On Target Nodes procedure is being executed.
    case applyingUpdate    = 0x03
    /// The Distribute Firmware procedure has completed successfully.
    case completed         = 0x04
    /// The Distribute Firmware procedure has failed.
    case failed            = 0x05
    /// The Cancel Firmware Update procedure is being executed.
    case cancelingUpdate   = 0x06
    /// The Transfer BLOB procedure is suspended.
    case transferSuspended = 0x07
}

/// The Firmware Update Additional Information state identifies the Node state after
/// successful application of a verified firmware image.
public struct FirmwareUpdateAdditionalInformation: OptionSet, Sendable {
    public let rawValue: UInt8

    /// Node’s Composition Data state will change, and Remote Provisioning is not supported.
    ///
    /// The new Composition Data state value is effective after the Node is reprovisioned.
    static let compositionDataChangedAndRPRUnsupported = FirmwareUpdateAdditionalInformation(rawValue: 0x1)

    /// Node’s Composition Data state will change, and Remote Provisioning is supported.
    ///
    /// The Node supports remote provisioning and Composition Data Page 128.
    /// The Composition Data Page 128 contains different information than Composition Data Page 0.
    static let compositionDataChangedAndRPRSupported = FirmwareUpdateAdditionalInformation(rawValue: 0x2)

    /// The Node will become unprovisioned after successful application of a verified
    /// firmware image.
    static let deviceUnprovisioned = FirmwareUpdateAdditionalInformation(rawValue: 0x3)
    
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
}

/// The Update Policy state indicates when to apply a new firmware image.
public enum FirmwareUpdatePolicy: UInt8, Sendable {
    /// The Firmware Distribution Server verifies that firmware image distribution completed
    /// successfully but does not apply the update. The Initiator (the Firmware Distribution Client)
    /// initiates firmware image application.
    case verifyOnly = 0x00
    /// The Firmware Distribution Server verifies that firmware image distribution completed
    /// successfully and then applies the firmware update.
    case verifyAndApply = 0x01
}
