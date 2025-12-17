/*
 * Copyright (c) 2017-2018 Runtime Inc.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import SwiftCBOR

public class LogManager: McuManager {
    
    override class var TAG: McuMgrLogCategory { .log }
    
    // MARK: - IDs
    
    enum LogID: UInt8 {
        case read = 0
        case clear = 1
        case append = 2
        case moduleList = 3
        case levelList = 4
        case logsList = 5
    }
    
    //**************************************************************************
    // MARK: Initializers
    //**************************************************************************

    public init(transport: McuMgrTransport) {
        super.init(group: McuMgrGroup.logs, transport: transport)
    }
    
    //**************************************************************************
    // MARK: Log Commands
    //**************************************************************************

    /// Show logs from a device.
    ///
    /// Logs will be shown from the log name provided, or all if none.
    /// Additionally, logs will only be shown from past the minIndex and
    /// minTimestamp if provided. The minimum timestamp will only be accounted
    /// for if the minIndex is also provided.
    ///
    /// This method will only provide a portion of the logs, and return the next
    /// index to pull the logs from. Therefore, in order to pull all of the logs
    /// from the device, you may have to call this method multiple times.
    ///
    /// - parameter log: The name of the log to read from.
    /// - parameter minIndex: The optional minimum index to pull logs from. If
    ///   not provided, the device will read the oldest log.
    /// - parameter minTimestamp: The minimum timestamp to pull logs from. This
    ///   parameter is only used if a minIndex is also provided.
    /// - parameter callback: The response callback.
    public func show(log: String? = nil, minIndex: UInt64? = nil, minTimestamp: Date? = nil, callback: @escaping McuMgrCallback<McuMgrLogResponse>) {
        var payload: [String:CBOR] = [:]
        if let log = log {
            payload.updateValue(CBOR.utf8String(log), forKey: "log_name")
        }
        if let minIndex = minIndex {
            payload.updateValue(CBOR.unsignedInt(minIndex), forKey: "index")
            if let minTimestamp = minTimestamp {
                payload.updateValue(CBOR.utf8String(McuManager.dateToString(date: minTimestamp)), forKey: "ts")
            }
        }
        send(op: .read, commandId: LogID.read, payload: payload, callback: callback)
    }

    /// Clear the logs on a device.
    ///
    /// - parameter callback: The response callback.
    public func clear(callback: @escaping McuMgrCallback<McuMgrResponse>) {
        send(op: .write, commandId: LogID.clear, payload: nil, callback: callback)
    }

    /// List the log modules on a device.
    ///
    /// - parameter callback: The response callback.
    public func moduleList(callback: @escaping McuMgrCallback<McuMgrResponse>) {
        send(op: .read, commandId: LogID.moduleList, payload: nil, callback: callback)
    }

    /// List the log levels on a device.
    ///
    /// - parameter callback: The response callback.
    public func levelList(callback: @escaping McuMgrCallback<McuMgrLevelListResponse>) {
        send(op: .read, commandId: LogID.levelList, payload: nil, callback: callback)
    }

    /// List the logs on a device.
    ///
    /// - parameter callback: The response callback.
    public func logsList(callback: @escaping McuMgrCallback<McuMgrLogListResponse>) {
        send(op: .read, commandId: LogID.logsList, payload: nil, callback: callback)
    }
}
