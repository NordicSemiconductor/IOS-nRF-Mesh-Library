/*
* Copyright (c) 2022, Nordic Semiconductor
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
public struct FirmwareId: DataConvertible {
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
    
    public static func + (lhs: Data, rhs: FirmwareId) -> Data {
        return lhs + rhs.companyIdentifier + rhs.version
    }
}

/// The status codes for the Firmware Update Server model and the
/// Firmware Update Client model.
public enum FirmwareUpdateStatus: UInt8 {
    /// The message was processed successfully.
    case success = 0x00
    /// Insufficient resources on the Node.
    case insufficientResources = 0x01
    /// The operation cannot be performed while the server is in the current phase.
    case wrongPhase = 0x02
    /// An internal error occurred on the Node.
    case internalError = 0x03
    /// The message contains a firmware index value that is not expected.
    case wrongFirmwareIndex = 0x04
    /// The metadata check failed.
    case metadataCheckFailed = 0x05
    /// The server cannot start a firmware update.
    case temporarilyUnavailable = 0x06
    /// Another BLOB transfer is in progress.
    case blobTransferBusy = 0x07
}

/// The status codes for the Firmware Distribution Server model and the
/// Firmware Distribution Client model.
enum FirmwareDistributionStatus: UInt8 {
    /// The message was processed successfully.
    case success = 0x00
    /// Insufficient resources on the Node.
    case insufficientResources = 0x01
    /// The operation cannot be performed while the server is in the current phase.
    case wrongPhase = 0x02
    /// An internal error occurred on the node.
    case internalError = 0x03
    /// The requested firmware image is not stored on the Distributor.
    case firmwareNotFound = 0x04
    /// The AppKey identified by the AppKey Index is not known to the Node.
    case invalidAppKeyIndex = 0x05
    /// There are no Target nodes in the Distribution Receivers List state.
    case receiversListEmpty = 0x06
    /// Another firmware image distribution is in progress.
    case busyWithDistribution = 0x07
    /// Another upload is in progress.
    case busyWithUpload = 0x08
    /// The URI scheme name indicated by the Update URI is not supported.
    case uriNotSupported = 0x09
    /// The format of the Update URI is invalid.
    case uriMalformed = 0x0A
    /// The URI is unreachable.
    case uriUnreachable = 0x0B
    /// The Check Firmware OOB procedure did not find any new firmware.
    case newFirmwareNotAvailable = 0x0C
    /// The suspension of the Distribute Firmware procedure failed.
    case suspendFailed = 0x0D
}

/// The Firmware Update Additional Information state identifies the Node state after
/// successful application of a verified firmware image.
public struct FirmwareUpdateAdditionalInformation: OptionSet {
    public let rawValue: UInt8

    /// Node’s Composition Data state will change, and remote provisioning is not supported.
    ///
    /// The new Composition Data state value is effective after the Node is reprovisioned.
    static let compositionDataChangedAndRPRUnsupported = FirmwareUpdateAdditionalInformation(rawValue: 0x1)

    /// Node’s Composition Data state will change, and remote provisioning is supported.
    ///
    /// The Node supports remote provisioning and Composition Data Page 128.
    /// The Composition Data Page 128 contains different information than Composition Data Page 0.
    static let compositionDataChangedAndRPRSupported = FirmwareUpdateAdditionalInformation(rawValue: 0x2)

    /// The Node will become unprovisioned after successful application of a verified firmware image.
    static let deviceUnprovisioned = FirmwareUpdateAdditionalInformation(rawValue: 0x3)
    
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
}
