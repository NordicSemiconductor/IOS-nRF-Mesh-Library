/*
 * Copyright (c) 2017-2018 Runtime Inc.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import SwiftCBOR

// MARK: - DefaultManager

public class DefaultManager: McuManager {
    override class var TAG: McuMgrLogCategory { .default }
    
    // MARK: Constants

    enum ID: UInt8 {
        case echo = 0
        case consoleEchoControl = 1
        case taskStatistics = 2
        case memoryPoolStatistics = 3
        case dateTimeString = 4
        case reset = 5
        case mcuMgrParameters = 6
        case applicationInfo = 7
        case bootloaderInformation = 8
    }
    
    // MARK: ResetBootMode
    
    public enum ResetBootMode: UInt8, CustomStringConvertible, CaseIterable {
        case normal = 0
        case bootloader = 1
        
        public var description: String {
            switch self {
            case .normal:
                return "Normal"
            case .bootloader:
                return "Bootloader / Firmware Loader"
            }
        }
    }
    
    // MARK: ApplicationInfoFormat
    
    public enum ApplicationInfoFormat: String {
        case kernelName = "s"
        case nodeName = "n"
        case kernelRelease = "r"
        case kernelVersion = "v"
        case buildDateTime = "b"
        case machine = "m"
        case processor = "p"
        case hardwarePlatform = "i"
        case operatingSystem = "o"
        case all = "a"
    }
    
    // MARK: BootloaderInfoQuery
    
    public enum BootloaderInfoQuery: String {
        case name = ""
        case mode = "mode"
        case slot = "active_b0_slot"
    }
    
    //**************************************************************************
    // MARK: Initializers
    //**************************************************************************

    public init(transport: McuMgrTransport) {
        super.init(group: McuMgrGroup.OS, transport: transport)
    }
    
    // MARK: - Commands

    // MARK: Echo
    
    /// Echo a string to the device.
    ///
    /// Used primarily to test Mcu Manager.
    ///
    /// - parameter echo: The string which the device will echo.
    /// - parameter callback: The response callback.
    public func echo(_ echo: String, callback: @escaping McuMgrCallback<McuMgrEchoResponse>) {
        let payload: [String:CBOR] = ["d": CBOR.utf8String(echo)]
        
        let echoPacket = McuManager.buildPacket(scheme: transport.getScheme(),
                                                version: .SMPv2, op: .write,
                                                flags: 0, group: McuMgrGroup.OS.rawValue,
                                                sequenceNumber: 0, commandId: ID.echo, payload: payload)
        
        guard echoPacket.count <= BasicManager.MAX_ECHO_MESSAGE_SIZE_BYTES else {
            callback(nil, EchoError.echoMessageOverTheLimit(echoPacket.count))
            return
        }
        send(op: .write, commandId: ID.echo, payload: payload, callback: callback)
    }
    
    // MARK: (Console) Echo
    
    /// Set console echoing on the device.
    ///
    /// - parameter echoOn: Value to set console echo to.
    /// - parameter callback: The response callback.
    public func consoleEcho(_ echoOn: Bool, callback: @escaping McuMgrCallback<McuMgrResponse>) {
        let payload: [String:CBOR] = ["echo": CBOR.init(integerLiteral: echoOn ? 1 : 0)]
        send(op: .write, commandId: ID.consoleEchoControl, payload: payload, callback: callback)
    }
    
    // MARK: Task
    
    /// Read the task statistics for the device.
    ///
    /// - parameter callback: The response callback.
    public func taskStats(callback: @escaping McuMgrCallback<McuMgrTaskStatsResponse>) {
        send(op: .read, commandId: ID.taskStatistics, payload: nil, callback: callback)
    }
    
    // MARK: Memory Pool
    
    /// Read the memory pool statistics for the device.
    ///
    /// - parameter callback: The response callback.
    public func memoryPoolStats(callback: @escaping McuMgrCallback<McuMgrMemoryPoolStatsResponse>) {
        send(op: .read, commandId: ID.memoryPoolStatistics, payload: nil, callback: callback)
    }
    
    // MARK: Read/Write DateTime
    
    /// Read the date and time on the device.
    ///
    /// - parameter callback: The response callback.
    public func readDatetime(callback: @escaping McuMgrCallback<McuMgrDateTimeResponse>) {
        send(op: .read, commandId: ID.dateTimeString, payload: nil, callback: callback)
    }
    
    /// Set the date and time on the device.
    ///
    /// - parameter date: The date and time to set the device's clock to. If
    ///   this parameter is left out, the device will be set to the current date
    ///   and time.
    /// - parameter timeZone: The time zone for the given date. If left out, the
    ///   timezone will be set to the iOS system time zone.
    /// - parameter callback: The response callback.
    public func writeDatetime(date: Date = Date(), timeZone: TimeZone? = nil,
                              callback: @escaping McuMgrCallback<McuMgrResponse>) {
        let payload: [String:CBOR] = [
            "datetime": CBOR.utf8String(McuManager.dateToString(date: date, timeZone: timeZone))
        ]
        send(op: .write, commandId: ID.dateTimeString, payload: payload, callback: callback)
    }
    
    // MARK: Reset
    
    /// Trigger the device to soft reset.
    ///
    /// - parameter bootMode: The boot mode to use for the reset, defaults to `normal`.
    /// - parameter force: Force reset on the firmware so it's not rejected. Defaults to `false`.
    /// - parameter callback: The response callback.
    public func reset(bootMode: ResetBootMode = .normal, force: Bool = false,
                      callback: @escaping McuMgrCallback<McuMgrResponse>) {
        var payload: [String:CBOR]?
        if bootMode != .normal || force {
            payload = [:]
            if bootMode != .normal {
                payload?["boot_mode"] = CBOR.unsignedInt(UInt64(bootMode.rawValue))
            }
            if force {
                payload?["force"] = CBOR.boolean(true)
            }
        }
        send(op: .write, commandId: ID.reset, payload: payload, callback: callback)
    }
    
    // MARK: McuMgr Parameters
    
    /// Reads McuMgr Parameters
    ///
    /// - parameter callback: The response callback.
    public func params(callback: @escaping McuMgrCallback<McuMgrParametersResponse>) {
        send(op: .read, commandId: ID.mcuMgrParameters, payload: nil, timeout: McuManager.FAST_TIMEOUT, callback: callback)
    }
    
    // MARK: Application Info
    
    /// Reads Application Info
    ///
    /// - parameter callback: The response callback.
    public func applicationInfo(format: Set<ApplicationInfoFormat>,
                                callback: @escaping McuMgrCallback<AppInfoResponse>) {
        let payload: [String:CBOR]
        if format.contains(.all) {
            payload = ["format": CBOR.utf8String(ApplicationInfoFormat.all.rawValue)]
        } else {
            payload = ["format": CBOR.utf8String(format.map({$0.rawValue}).joined(separator: ""))]
        }
        send(op: .read, commandId: ID.applicationInfo, payload: payload,
             timeout: McuManager.FAST_TIMEOUT, callback: callback)
    }
    
    // MARK: Bootloader Info
    
    /// Reads Bootloader Info
    ///
    /// - parameter query: The specific Bootloader Information you'd like to request.
    /// - parameter callback: The response callback.
    public func bootloaderInfo(query: BootloaderInfoQuery,
                               callback: @escaping McuMgrCallback<BootloaderInfoResponse>) {
        let payload: [String: CBOR]?
        switch query {
        case .name:
            payload = nil
        case .mode, .slot:
            payload = ["query": CBOR.utf8String(query.rawValue)]
        }
        send(op: .read, commandId: ID.bootloaderInformation, payload: payload,
             timeout: McuManager.FAST_TIMEOUT, callback: callback)
    }
}

// MARK: - EchoError

enum EchoError: Hashable, Error, LocalizedError {
    case echoMessageOverTheLimit(_ messageSize: Int)

    var errorDescription: String? {
        switch self {
        case .echoMessageOverTheLimit(let messageSize):
            return "Echo Message of \(messageSize) bytes in size is over the limit of \(BasicManager.MAX_ECHO_MESSAGE_SIZE_BYTES) bytes."
        }
    }
}

// MARK: - OSManagerError

public enum OSManagerError: UInt64, Error, LocalizedError {
    case noError = 0
    case unknown = 1
    case invalidFormat = 2
    case queryNotRecognized = 3
    case rtcNotSet = 4
    case rtcCommandFailed = 5
    case queryNoValidResponse = 6
    
    public var errorDescription: String? {
        switch self {
        case .noError:
            return "Success"
        case .unknown:
            return "Unknown Error"
        case .invalidFormat:
            return "Provided format value is not valid"
        case .queryNotRecognized:
            return "Query was not recognized"
        case .rtcNotSet:
            return "RTC (Real-Time Clock) not set"
        case .rtcCommandFailed:
            return "RTC Command Failed"
        case .queryNoValidResponse:
            return "Query was recognized, but no valid response value is available"
        }
    }
}
