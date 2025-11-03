/*
 * Copyright (c) 2017-2018 Runtime Inc.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import SwiftCBOR

// MARK: - SettingsManager

public class SettingsManager: McuManager {
    override class var TAG: McuMgrLogCategory { .settings }
    
    // MARK: IDs
    
    enum ConfigID: UInt8 {
        case zero = 0
        case one = 1
        case two = 2
        case three = 3
    }
    
    // MARK: Initializers

    public init(transport: McuMgrTransport) {
        super.init(group: McuMgrGroup.settings, transport: transport)
    }
    
    // MARK: Commands

    /// Read a system configuration variable from a device.
    ///
    /// - parameter name: The name of the system configuration variable to read.
    /// - parameter callback: The response callback.
    public func read(name: String, callback: @escaping McuMgrCallback<McuMgrConfigResponse>) {
        let payload: [String:CBOR] = ["name": CBOR.utf8String(name)]
        send(op: .read, commandId: ConfigID.zero, payload: payload, callback: callback)
    }

    /// Write a system configuration variable on a device.
    ///
    /// - parameter name: The name of the sys config variable to write.
    /// - parameter value: The value of the sys config variable to write.
    /// - parameter callback: The response callback.
    public func write(name: String, value: [UInt8], callback: @escaping McuMgrCallback<McuMgrResponse>) {
        let payload: [String:CBOR] = ["name": CBOR.utf8String(name),
                                      "val":  CBOR.byteString(value)]
        send(op: .write, commandId: ConfigID.zero, payload: payload, callback: callback)
    }
    
    /// Delete setting command allows deleting a setting on a device.
    ///
    /// - parameter name: The name of the sys config variable to write.
    /// - parameter callback: The response callback.
    public func delete(name: String, callback: @escaping McuMgrCallback<McuMgrResponse>) {
        let payload: [String:CBOR] = ["name": CBOR.utf8String(name)]
        send(op: .write, commandId: ConfigID.one, payload: payload, callback: callback)
    }
    
    /// Commit settings command allows committing all settings that have been set but not yet applied on a device.
    ///
    /// - parameter callback: The response callback.
    public func commit(callback: @escaping McuMgrCallback<McuMgrResponse>) {
        send(op: .write, commandId: ConfigID.two, payload: nil, callback: callback)
    }
    
    /// Load settings command allows loading all serialized items from persistent storage on a device.
    ///
    /// - parameter callback: The response callback.
    public func load(callback: @escaping McuMgrCallback<McuMgrResponse>) {
        send(op: .read, commandId: ConfigID.three, payload: nil, callback: callback)
    }
    
    /// Save settings command allows saving all serialized items to persistent storage on a device.
    ///
    /// - parameter callback: The response callback.
    public func save(callback: @escaping McuMgrCallback<McuMgrResponse>) {
        send(op: .write, commandId: ConfigID.three, payload: nil, callback: callback)
    }
}

// MARK: - SettingsManagerError

public enum SettingsManagerError: UInt64, Error, LocalizedError {
    case noError = 0
    case unknown = 1
    case keyTooLong = 2
    case keyNotFound = 3
    case readNotSupported = 4
    case rootKeyNotFound = 5
    case writeNotSupported = 6
    case deleteNotSupported = 7
    
    public var errorDescription: String? {
        switch self {
        case .noError:
            return "Success"
        case .unknown:
            return "Unknown error"
        case .keyTooLong:
            return "Provided key name is too long to be used"
        case .keyNotFound:
            return "Provided key name does not exist"
        case .readNotSupported:
            return "Provided key name does not support being read"
        case .rootKeyNotFound:
            return "Provided root key name does not exist"
        case .writeNotSupported:
            return "Provided key name does not support write operation"
        case .deleteNotSupported:
            return "Provided key name does not support delete operation"
        }
    }
}
