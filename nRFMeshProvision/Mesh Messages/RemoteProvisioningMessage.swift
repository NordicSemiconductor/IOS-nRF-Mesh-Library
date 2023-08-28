/*
* Copyright (c) 2023, Nordic Semiconductor
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

/// A base protocol for all Remote Provisioning messages.
public protocol RemoteProvisioningMessage: ConfigMessage {
    // No additional fields.
}

/// A base protocol for unacknowledged Remote Provisioning messages.
public protocol UnacknowledgedRemoteProvisioningMessage: RemoteProvisioningMessage, UnacknowledgedConfigMessage {
    // No additional fields.
}

/// A base protocol for unacknowledged Remote Provisioning messages.
public protocol RemoteProvisioningResponse: ConfigResponse, UnacknowledgedRemoteProvisioningMessage {
    // No additional fields.
}

/// A base protocol for acknowledged Remote Provisioning messages.
///
/// Acknowledged messages will be responded with a status message.
public protocol AcknowledgedRemoteProvisioningMessage: RemoteProvisioningMessage, AcknowledgedConfigMessage {
    // No additional fields.
}

/// The status of a Config operation.
public enum RemoteProvisioningMessageStatus: UInt8 {
    /// Success.
    case success                            = 0x00
    /// Scanning Cannot Start.
    case scanningCannotStart                = 0x01
    /// Invalid State.
    case invalidState                       = 0x02
    /// Limited Resources.
    case limitedResources                   = 0x03
    /// Link Cannot Open.
    case linkCannotOpen                     = 0x04
    /// Link Open Failed.
    case linkOpenFailed                     = 0x05
    /// Link Closed by Device.
    case linkClosedByDevice                 = 0x06
    /// Link Closed by Server.
    case linkClosedByServer                 = 0x07
    /// Link Closed by Client.
    case linkClosedByClient                 = 0x08
    /// Link Closed as Cannot Receive PDU.
    case linkClosedAsCannotReceivePDU       = 0x09
    /// Link Closed as Cannot Send PDU.
    case linkClosedAsCannotSendPDU          = 0x0A
    /// Link Closed as Cannot Deliver PDU Report.
    case linkClosedAsCannotDeliverPDUReport = 0x0B
}

/// A base protocol for config status messages.
///
/// Remote Provisioning status message may come as a response to an acknowledged
/// message, or sent as a Report message.
public protocol RemoteProvisioningStatusMessage: RemoteProvisioningMessage, StatusMessage {
    /// Status for the requesting message.
    var status: RemoteProvisioningMessageStatus { get }
}

/// A base protocol for Remote Provisioning messages reporting link state.
public protocol RemoteProvisioningLinkStateMessage: RemoteProvisioningMessage {
    /// Remote Provisioning Link state.
    var linkState: RemoteProvisioningLinkState { get }
}

public extension RemoteProvisioningStatusMessage {
    
    /// Whether the operation was successful or not.
    var isSuccess: Bool {
        return status == .success
    }
    
    /// String representation of the status.
    var message: String {
        return "\(status)"
    }
    
}

/// The Remote Provisioning Scan state describes the state of the Remote Provisioning
/// Scan procedure in the Remote Provisioning Server model.
public enum RemoteProvisioningScanState: UInt8 {
    /// Idle.
    case idle               = 0x00
    /// Remote Provisioning Multiple Devices Scan (not limited to one device).
    case multipleDeviceScan = 0x01
    /// Remote Provisioning Single Device Scan (limited to one device).
    case singleDeviceScan   = 0x02
}

/// The Remote Provisioning Link describe the state of the Remote Provisioning Server
/// model.
///
/// During the execution of any of the Node Provisioning Protocol Interface procedures,
/// the Link Opening, Outbound Packet Transfer, and Link Closing values are not used.
public enum RemoteProvisioningLinkState: UInt8 {
    /// Idle.
    case idle                   = 0x00
    /// Link Opening.
    case linkOpening            = 0x01
    /// Link Active.
    case linkActive             = 0x02
    /// Outbound Packet Transfer.
    case outboundPacketTransfer = 0x03
    /// Link Closing.
    case linkClosing            = 0x04
}

/// Provisioning bearer link close reason.
public enum RemoteProvisioningLinkCloseReason: UInt8 {
    /// Success.
    case success      = 0x00
    // Value 0x01 is prohibited.
    /// Fail.
    case fail         = 0x02
    /// Unrecognized reason that may be defined in the future.
    case unrecognized = 0xFF
}

/// The Node Provisioning Protocol Interface is an interface used by the Node
/// to route the Provisioning PDUs between the Provisioner and the layer that
/// is executing the provisioning protocol.
public enum NodeProvisioningProtocolInterfaceProcedure: UInt8 {
    /// The Device Key Refresh procedure is used to change the Device Key
    /// without reprovisioning a Node and without a need to reconfigure the Node.
    ///
    /// The Device Key Refresh procedure does not transfer a device key to the
    /// device over the air; instead, it uses the provisioning protocol to
    /// compute the Device Key Candidate.
    ///
    /// The device key value change that results from this procedure is thus
    /// performed at the same security level as is provisioning of the
    /// unprovisioned device. The Unicast Address, Network Key, Network Key Index,
    /// and IV Index are not affected by this procedure.
    case deviceKeyRefresh       = 0x00
    /// The Node Address efresh procedure is used to change the Node’s Device Key
    /// and Unicast Address without reprovisioning.
    ///
    /// This procedure will terminate all friendships, if applicable, and will
    /// copy Composition Page 128 to Composition Page 0.
    case nodeAddressRefresh     = 0x01
    /// The Node Composition Refresh procedure is used to change the Device Key
    /// of the Node and to add or delete models or features of the Node
    /// without reprovisioning.
    ///
    /// Almost all states of the node do not change during this procedure.
    ///
    /// This procedure copies Composition Page 128 to Composition Page 0.
    case nodeCompositionRefresh = 0x02
}

/// An enumeration of a subset of AD Types defined by Bluetooth SIG and specified
/// in Assigned Numbers document under Common Data Types.
///
/// This list is not complete and contains only subset of AT Types supported by iOS.
///
/// - note: This list does not contain Incomplete Lists of Service Class UUIDs and
///         Shortened Local Name AD Types, as those are not supported in
///         ``RemoteProvisioningExtendedScanStart`` message.
internal enum AdType: UInt8 {
    case localName     = 0x09
    case txPowerLevel  = 0x0A
    case uri           = 0x24
    // Service Data
    case serviceData16bitUUID  = 0x16
    case serviceData32bitUUID  = 0x20
    case serviceData128bitUUID = 0x21
    // List of Service Solicitation UUIDs
    case listOf16­bitServiceSolicitationUUIDs  = 0x14
    case listOf32bitServiceSolicitationUUIDs  = 0x1F
    case listOf128bitServiceSolicitationUUIDs = 0x15
    // Complete List of Service Class UUIDs
    case completeListOf16­bitServiceClassUUIDs  = 0x03
    case completeListOf32bitServiceClassUUIDs  = 0x05
    case completeListOf128bitServiceClassUUIDs = 0x07
    // Manufacturer data.
    case manufacturerData = 0xFF
    
    var length: Int {
        switch self {
        case .serviceData16bitUUID,
             .listOf16­bitServiceSolicitationUUIDs,
             .completeListOf16­bitServiceClassUUIDs:
            return 2
        case .serviceData32bitUUID,
             .listOf32bitServiceSolicitationUUIDs,
             .completeListOf32bitServiceClassUUIDs:
            return 4
        case .serviceData128bitUUID,
             .listOf128bitServiceSolicitationUUIDs,
             .completeListOf128bitServiceClassUUIDs:
            return 16
        default:
            fatalError("This should never be called")
        }
    }
}

/// A subset of AD Types defined by Bluetooth SIG and specified
/// in Assigned Numbers document under Common Data Types, which can be requested
/// using ``RemoteProvisioningExtendedScanStart`` message.
///
/// This list is not complete and contains only subset of AT Types supported by iOS.
///
/// If the filter contains the ``AdTypes/localName`` AD Type, the client is
/// requesting either the Complete Local Name or the Shortened Local Name.
public struct AdTypes {
    internal let adTypes: [AdType]
    
    public static let localName = AdTypes(.localName)
    public static let txPowerLevel = AdTypes(.txPowerLevel)
    public static let uri = AdTypes(.uri)
    public static let serviceDataUUID = AdTypes([
        .serviceData16bitUUID,
        .serviceData32bitUUID,
        .serviceData128bitUUID
    ])
    public static let listOfServiceSolicitationUUIDs = AdTypes([
        .listOf16­bitServiceSolicitationUUIDs,
        .listOf32bitServiceSolicitationUUIDs,
        .listOf128bitServiceSolicitationUUIDs
    ])
    public static let completeListOfServiceUUIDs = AdTypes([
        .completeListOf16­bitServiceClassUUIDs,
        .completeListOf32bitServiceClassUUIDs,
        .completeListOf128bitServiceClassUUIDs
    ])
    public static let manufacturerData = AdTypes(.manufacturerData)
    
    internal init(_ type: AdType) {
        self.adTypes = [type]
    }
    
    internal init(_ types: [AdType]) {
        // Make sure there are no duplicates.
        var set = Set<AdType>()
        self.adTypes = types.filter { set.insert($0).inserted }
    }
}

/// An Advertising Structure.
public struct AdStructure {
    /// The AD Type associated with the value.
    public let type: UInt8
    /// The value.
    public let value: Data
    
    /// The AD Type for supported types, or `nil` for other.
    var adType: AdType? {
        return AdType(rawValue: type)
    }
}

extension RemoteProvisioningMessageStatus: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .success:                            return "Success"
        case .scanningCannotStart:                return "Scanning Cannot Start"
        case .invalidState:                       return "Invalid State"
        case .limitedResources:                   return "Limited Resources"
        case .linkCannotOpen:                     return "Link Cannot Open"
        case .linkOpenFailed:                     return "Link Open Failed"
        case .linkClosedByDevice:                 return "Link Closed by Device"
        case .linkClosedByServer:                 return "Link Closed by Server"
        case .linkClosedByClient:                 return "Link Closed by Client"
        case .linkClosedAsCannotReceivePDU:       return "Link Closed as Cannot Receive PDU"
        case .linkClosedAsCannotSendPDU:          return "Link Closed as Cannot Send PDU"
        case .linkClosedAsCannotDeliverPDUReport: return "Link Closed as Cannot Deliver PDU Report"
        }
    }
    
}

extension RemoteProvisioningScanState: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .idle:               return "Idle"
        case .multipleDeviceScan: return "Multiple Device Scan"
        case .singleDeviceScan:   return "Sindle Device Scan"
        }
    }
    
}

extension RemoteProvisioningLinkCloseReason: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .success:      return "Success"
        case .fail:         return "Fail"
        case .unrecognized: return "Unrecognized"
        }
    }
    
}

extension RemoteProvisioningLinkState: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .idle: return "Idle"
        case .linkOpening: return "Link Opening"
        case .linkActive: return "Link Active"
        case .outboundPacketTransfer: return "Outbound Packet Transfer"
        case .linkClosing: return "Link Closing"
        }
    }
    
}

extension NodeProvisioningProtocolInterfaceProcedure: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .deviceKeyRefresh: return "Device Key Refresh"
        case .nodeAddressRefresh: return "Node Address Refresh"
        case .nodeCompositionRefresh: return "Node Composition Refresh"
        }
    }
    
}
