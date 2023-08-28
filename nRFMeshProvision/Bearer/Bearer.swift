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

/// The PDU Type identifies the type of the message.
/// 
/// Bearers may use this type to set the proper value in the
/// payload. For ADV bearer it will be a proper AD Type (see Assigned
/// Numbers / Generic Access Profile), for GATT bearer the correct
/// Message type in the Proxy PDU.
///
/// Some message types are handled only by some bearers,
/// for example the provisioning PDU type must be sent using a
/// Provisioning Bearer (PB type of bearer).
public enum PduType: UInt8 {
    /// The message is a Network PDU.
    ///
    /// See: Section 3.4.4 of Bluetooth Mesh Specification 1.0.1.
    case networkPdu         = 0
    /// The message is a mesh beacon.
    ///
    /// See: Section 3.9 of Bluetooth Mesh Specification 1.0.1.
    case meshBeacon         = 1
    /// The message is a proxy configuration message.
    ///
    /// This message type may be used only for GATT Bearer.
    ///
    /// See: Section 6.5 of Bluetooth Mesh Specification 1.0.1.
    case proxyConfiguration = 2
    /// The message is a Provisioning PDU.
    ///
    /// This message type may be used only in Provisioning Bearers (PB).
    ///
    /// See: Section 5.4.1 of Bluetooth Mesh Specification 1.0.1.
    case provisioningPdu    = 3
    
    internal var mask: UInt8 {
        return 1 << rawValue
    }
}

/// A set of supported PDU types by the bearer object.
public struct PduTypes: OptionSet {    
    public let rawValue: UInt8
        
    /// Set, if the bearer supports Network PDUs.
    public static let networkPdu         = PduTypes(rawValue: 1 << 0)
    /// Set, if the bearer supports Mesh Beacons.
    public static let meshBeacon         = PduTypes(rawValue: 1 << 1)
    /// Set, if the bearer supports proxy filter configuration.
    public static let proxyConfiguration = PduTypes(rawValue: 1 << 2)
    /// Set, if the bearer supports Provisioning PDUs.
    public static let provisioningPdu    = PduTypes(rawValue: 1 << 3)
    
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    
}

/// A transmitter is responsible for delivering messages to the mesh network.
public protocol Transmitter: AnyObject {
    
    /// This method sends the given data over the bearer.
    ///
    /// Data longer than MTU will automatically be segmented if bearer
    /// implements segmentation.
    ///
    /// - parameter data: The data to be sent over the Bearer.
    /// - parameter type: The PDU type.
    /// - throws: This method throws an error if the PDU type
    ///           is not supported, or data could not be sent for
    ///           some other reason.
    func send(_ data: Data, ofType type: PduType) throws
    
}

/// The Bearer object is responsible for sending and receiving the data
/// to the mesh network.
public protocol Bearer: Transmitter {
    
    /// The Bearer delegate object will receive callbacks whenever the
    /// Bearer state changes.
    var delegate: BearerDelegate? { get set }
    /// The data delegate will receive callbacks whenever a message is
    /// received from the Bearer.
    var dataDelegate: BearerDataDelegate? { get set }
    /// Returns the PDU types supported by this bearer.
    var supportedPduTypes: PduTypes { get }
    /// This property returns `true` if the Bearer is open, otherwise `false`.
    var isOpen: Bool { get }
    
    /// This method opens the Bearer.
    func open() throws
    
    /// This method closes the Bearer.
    func close() throws
    
}

public extension Bearer {
    
    /// Returns whether the Bearer supports the given message type.
    func supports(_ pduType: PduType) -> Bool {
        return supportedPduTypes.contains(PduTypes(rawValue: pduType.mask))
    }
    
}

/// A mesh bearer is used to send mesh messages to provisioned nodes.
public protocol MeshBearer: Bearer {
    // Empty.
}

/// A provisioning bearer is used to send provisioning PDUs to unprovisioned
/// devices.
public protocol ProvisioningBearer: Bearer {
    // Empty.
}

extension ProvisioningBearer {
    
    /// This method sends the given Provisioning Request over the bearer.
    ///
    /// Data longer than MTU will automatically be segmented if bearer
    /// implements segmentation.
    ///
    /// - parameter request: The Provisioning request to be sent over
    ///                      the Bearer.
    /// - throws: This method throws an error if the PDU type
    ///           is not supported, or data could not be sent for
    ///           some other reason.
    func send(_ request: ProvisioningRequest) throws {
        try send(request.pdu, ofType: .provisioningPdu)
    }
    
}
