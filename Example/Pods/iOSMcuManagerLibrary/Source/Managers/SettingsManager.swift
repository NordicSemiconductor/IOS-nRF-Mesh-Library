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
