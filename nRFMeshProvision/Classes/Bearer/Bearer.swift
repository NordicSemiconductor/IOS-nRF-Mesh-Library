//
//  Bearer.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 02/05/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation

/// The Message Type identifies the type of the message.
/// Bearers may use this type to set the proper value in the
/// payload. For ADV beared it will be a proper AD Type (see Assigned
/// Numbers / Generic Access Profile), for GATT bearer the correct
/// Message type in the Proxy PDU.
///
/// Some message types are handled only by some bearers,
/// for example the provisioning PDU type must be sent using a
/// Provisioning Bearer (PB type of bearer).
public enum MessageType: UInt8 {
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

public struct MessageTypes: OptionSet {    
    public let rawValue: UInt8
        
    public static let networkPdu         = MessageTypes(rawValue: 1 << 0)
    public static let meshBeacon         = MessageTypes(rawValue: 1 << 1)
    public static let proxyConfiguration = MessageTypes(rawValue: 1 << 2)
    public static let provisioningPdu    = MessageTypes(rawValue: 1 << 3)
    
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    
}

/// The Bearer object is responsible for sending and receiving the data
/// to the mesh network.
public protocol Bearer: class {
    /// The Bearer delegate object will receive callbacks whenever the
    /// Bearer state changes or a message is received from the Bearer.
    var delegate: BearerDelegate? { get set }
    /// Returns the message types supported by this bearer.
    var supportedMesasgeTypes: MessageTypes { get }
    /// This property returns `true` if the Bearer is open, otherwise `false`.
    var isOpen: Bool { get }
    
    /// This method opens the Bearer.
    func open()
    
    /// This method closes the Bearer.
    func close()
    
    /// This method sends the given data over the bearer.
    /// Data longer than MTU will automatically be segmented
    /// using the bearer protocol if bearer implements segmentation.
    ///
    /// - parameter data: The data to be sent over the Bearer.
    /// - parameter type: The message type.
    /// - throws: This method throws an error if the message type
    ///           is not supported, or data could not be sent for
    ///           some other reason.
    func send(_ data: Data, ofType type: MessageType) throws
}

public extension Bearer {
    
    /// Returns whether the Bearer supports the given message type.
    func supports(_ messageType: MessageType) -> Bool {
        return supportedMesasgeTypes.contains(MessageTypes(rawValue: messageType.mask))
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
    /// - throws: This method throws an error if the message type
    ///           is not supported, or data could not be sent for
    ///           some other reason.
    func send(_ request: ProvisioningRequest) throws {
        print("Sending \(request)")
        try send(request.pdu, ofType: .provisioningPdu)
    }
    
}
