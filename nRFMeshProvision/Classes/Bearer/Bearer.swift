//
//  Bearer.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 02/05/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation

/// The PDU Type identifies the type of the message.
/// Bearers may use this type to set the proper value in the
/// payload. For ADV beared it will be a proper AD Type (see Assigned
/// Numbers / Generic Access Profile), for GATT bearer the correct
/// Message type in the Proxy PDU.
///
/// Some message types are handled only by some bearers,
/// for example the provisioning PDU type must be sent using a
/// Provisioning Bearer (PB type of bearer).
public enum PduType: UInt8 {
    /// The message is a Network PDU.
    /// See: Section 3.4.4 of Bluetooth Mesh Specification 1.0.1.
    case networkPdu         = 0
    /// See: Section 3.9 of Bluetooth Mesh Specification 1.0.1.
    case meshBeacon         = 1
    /// The message is a proxy configuration message.
    /// This message type may be used only for GATT Bearer.
    /// See: Section 6.5 of Bluetooth Mesh Specification 1.0.1.
    case proxyConfiguration = 2
    /// The message is a Provisioning PDU.
    /// This message type may be used only in Provisioning Bearers (PB).
    /// See: Section 5.4.1 of Bluetooth Mesh Specification 1.0.1.
    case provisioningPdu    = 3
    
    var mask: UInt8 {
        return 1 << rawValue
    }
}

public struct PduTypes: OptionSet {    
    public let rawValue: UInt8
        
    public static let networkPdu         = PduTypes(rawValue: 1 << 0)
    public static let meshBeacon         = PduTypes(rawValue: 1 << 1)
    public static let proxyConfiguration = PduTypes(rawValue: 1 << 2)
    public static let provisioningPdu    = PduTypes(rawValue: 1 << 3)
    
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    
}

public protocol Transmitter: class {
    
    /// This method sends the given data over the bearer.
    /// Data longer than MTU will automatically be segmented
    /// using the bearer protocol if bearer implements segmentation.
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
    /// The Maximum Transmission Unit (MTU) is the maximum size of payload
    /// that the bearer can send in a single packet.
    var mtu: Int { get }
    
    /// This method opens the Bearer.
    func open()
    
    /// This method closes the Bearer.
    func close()
    
}

public extension Bearer {
    
    /// Returns whether the Bearer supports the given message type.
    func supports(_ pduType: PduType) -> Bool {
        return supportedPduTypes.contains(PduTypes(rawValue: pduType.mask))
    }
    
}

public protocol MeshBearer: Bearer {
    // Empty.
}

public protocol ProvisioningBearer: Bearer {
    // Empty.
}

extension ProvisioningBearer {
    
    /// This method sends the given Provisioning Request over the bearer.
    /// Data longer than MTU will automatically be segmented
    /// using the bearer protocol if bearer implements segmentation.
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
