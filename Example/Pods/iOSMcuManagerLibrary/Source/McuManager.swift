/*
 * Copyright (c) 2017-2018 Runtime Inc.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import CoreBluetooth
import SwiftCBOR

/**
 Valid values are within the bounds of UInt8 (0...255).
 
 For capabilities such as pipelining, incrementing and wrapping around
 the Sequence Number for every `McuManager command is required.
 */
public typealias McuSequenceNumber = UInt8

extension McuSequenceNumber {
    
    static func random() -> McuSequenceNumber {
        McuSequenceNumber.random(in: UInt8.min...UInt8.max)
    }
}

open class McuManager : NSObject {
    class var TAG: McuMgrLogCategory { .default }
    
    //**************************************************************************
    // MARK: Mcu Manager Constants
    //**************************************************************************
    
    /// Mcu Manager CoAP Resource URI.
    public static let COAP_PATH = "/omgr"
    
    /// Header Key for CoAP Payloads.
    public static let HEADER_KEY = "_h"
    
    /// If a specific Timeout is not set, the number of seconds that will be
    /// allowed to elapse before a send request is considered to have failed
    /// due to a timeout if no response is received.
    public static let DEFAULT_SEND_TIMEOUT_SECONDS = 40
    /// This is the default time to wait for a command to be sent, executed
    /// and received (responded to) by the firmware on the other end.
    public static let FAST_TIMEOUT = 5
    
    //**************************************************************************
    // MARK: Properties
    //**************************************************************************

    /// Handles transporting Mcu Manager commands.
    public let transport: McuMgrTransport
    
    /// The command group used for in the header of commands sent using this Mcu
    /// Manager.
    public let group: McuMgrGroup
    
    /// Logger delegate will receive logs.
    public weak var logDelegate: McuMgrLogDelegate?
    
    // MARK: Private
    
    private var smpVersion: McuMgrVersion = .SMPv2
    
    /// Each 'send' command gets its own Sequence Number to begin with.
    private var nextSequenceNumber: McuSequenceNumber = .random()
    
    /**
     Sequence Number Response ReOrder Buffer
     */
    private var robBuffer = McuMgrROBBuffer<McuSequenceNumber, Any>()
    
    //**************************************************************************
    // MARK: Initializers
    //**************************************************************************

    public init(group: McuMgrGroup, transport: McuMgrTransport) {
        self.group = group
        self.transport = transport
    }
    
    // MARK: - Send
    
    public func send<T: McuMgrResponse, R: RawRepresentable>(op: McuMgrOperation, commandId: R, payload: [String:CBOR]?,
                                                             timeout: Int = DEFAULT_SEND_TIMEOUT_SECONDS,
                                                             callback: @escaping McuMgrCallback<T>) where R.RawValue == UInt8 {
        return send(op: op, flags: 0, commandId: commandId, payload: payload, timeout: timeout,
                    callback: callback)
    }
    
    public func send<T: McuMgrResponse, R: RawRepresentable>(op: McuMgrOperation, flags: UInt8,
                                                             commandId: R, payload: [String:CBOR]?,
                                                             timeout: Int = DEFAULT_SEND_TIMEOUT_SECONDS,
                                                             callback: @escaping McuMgrCallback<T>) where R.RawValue == UInt8 {
        log(msg: "Sending \(op) command (Version: \(smpVersion), Group: \(group), seq: \(nextSequenceNumber), ID: \(commandId)): \(payload?.debugDescription ?? "nil")",
            atLevel: .verbose)
        let packetSequenceNumber = nextSequenceNumber
        let packetData = McuManager.buildPacket(scheme: transport.getScheme(),
                                                version: smpVersion, op: op,
                                                flags: flags, group: group.rawValue,
                                                sequenceNumber: packetSequenceNumber,
                                                commandId: commandId, payload: payload)
        let _callback: McuMgrCallback<T> = { [weak self] (response, error) -> Void in
            guard let self else {
                callback(response, error)
                return
            }
            
            do {
                guard try self.robBuffer.received((response, error), for: packetSequenceNumber) else { return }
                try self.robBuffer.deliver { responseSequenceNumber, response in
                    let responseResult = response as? (T?, (any Error)?)
                    if let response = responseResult?.0 {
                        self.smpVersion = McuMgrVersion(rawValue: response.header.version) ?? .SMPv1
                        self.log(msg: "Response (\(self.smpVersion), group: \(self.group), seq: \(responseSequenceNumber), command: \(commandId)): \(response)",
                                 atLevel: .verbose)
                    } else if let error = responseResult?.1 {
                        self.log(msg: "Request (\(self.smpVersion), group: \(self.group), seq: \(responseSequenceNumber), command: \(commandId)) failed: \(error.localizedDescription)",
                                 atLevel: .error)
                    }
                    callback(responseResult?.0, responseResult?.1)
                }
            } catch let robBufferError {
                DispatchQueue.main.async {
                    callback(response, robBufferError)
                }
            }
        }
        
        robBuffer.logDelegate = logDelegate
        robBuffer.enqueueExpectation(for: packetSequenceNumber)
        send(data: packetData, timeout: timeout, callback: _callback)
        // Use of Overflow operator
        nextSequenceNumber = nextSequenceNumber &+ 1
    }
    
    public func send<T: McuMgrResponse>(data: Data, timeout: Int, callback: @escaping McuMgrCallback<T>) {
        transport.send(data: data, timeout: timeout, callback: callback)
    }
    
    //**************************************************************************
    // MARK: Build Request Packet
    //**************************************************************************
    
    /// Build a McuManager request packet based on the transport scheme.
    ///
    /// - parameter scheme: The transport scheme.
    /// - parameter version: The SMP Version.
    /// - parameter op: The McuManagerOperation code.
    /// - parameter flags: The optional flags.
    /// - parameter group: The command group.
    /// - parameter sequenceNumber: The optional sequence number.
    /// - parameter commandId: The command id.
    /// - parameter payload: The request payload.
    ///
    /// - returns: The raw packet data to send to the transport.
    public static func buildPacket<R: RawRepresentable>(scheme: McuMgrScheme,
                                                        version: McuMgrVersion,
                                                        op: McuMgrOperation,
                                                        flags: UInt8, group: UInt16,
                                                        sequenceNumber: McuSequenceNumber,
                                                        commandId: R, payload: [String:CBOR]?) -> Data where R.RawValue == UInt8 {
        // If the payload map is nil, initialize an empty map.
        var payload = (payload == nil ? [:] : payload)!
        
        // Copy the payload map to remove the header key.
        var payloadCopy = payload
        // Remove the header if present (for CoAP schemes).
        payloadCopy.removeValue(forKey: McuManager.HEADER_KEY)
        
        // Get the length.
        let len: UInt16 = UInt16(CBOR.encode(payloadCopy).count)
        
        // Build header.
        let header = McuMgrHeader.build(version: version.rawValue, op: op.rawValue, flags: flags,
                                        len: len, group: group, seq: sequenceNumber,
                                        id: commandId.rawValue)
        
        // Build the packet based on scheme.
        if scheme.isCoap() {
            // CoAP transport schemes puts the header as a key-value pair in the
            // payload.
            if payload[McuManager.HEADER_KEY] == nil {
                payload.updateValue(CBOR.byteString(header), forKey: McuManager.HEADER_KEY)
            }
            return Data(CBOR.encode(payload))
        } else {
            // Standard scheme appends the CBOR payload to the header.
            let cborPayload = CBOR.encode(payload)
            var packet = Data(header)
            packet.append(contentsOf: cborPayload)
            return packet
        }
    }
    
    //**************************************************************************
    // MARK: Utilities
    //**************************************************************************

    /// Converts a date and optional timezone to a string which Mcu Manager on
    /// the device can use.
    ///
    /// The date format used is: "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    ///
    /// - parameter date: The date.
    /// - parameter timeZone: Optional timezone for the given date. If left out
    ///   or nil, the timezone will be set to the system time zone.
    ///
    /// - returns: The date-time string.
    public static func dateToString(date: Date, timeZone: TimeZone? = nil) -> String {
        let RFC3339DateFormatter = DateFormatter()
        RFC3339DateFormatter.locale = Locale(identifier: "en_US_POSIX")
        RFC3339DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        RFC3339DateFormatter.timeZone = (timeZone != nil ? timeZone : TimeZone.current)
        return RFC3339DateFormatter.string(from: date)
    }
    
    static let ValidMTURange = 73...1024
    
    public func setMtu(_ mtu: Int) throws  {
        guard Self.ValidMTURange.contains(mtu) else {
            throw McuManagerError.mtuValueOutsideOfValidRange(mtu)
        }
        guard self.transport.mtu != mtu else {
            throw McuManagerError.mtuValueHasNotChanged(mtu)
        }
        
        self.transport.mtu = mtu
        log(msg: "MTU set to \(mtu)", atLevel: .info)
    }
    
    /// Get the default MTU which should be used for a transport scheme. If the
    /// scheme is BLE, the iOS version is used to determine the MTU. If the
    /// scheme is UDP, the MTU returned is always 1024.
    ///
    /// - parameter scheme: the transport's scheme.
    public static func getDefaultMtu(scheme: McuMgrScheme) -> Int {
        switch scheme {
        // BLE MTU is determined by the version of iOS running on the device
        case .ble:
            /// Return the maximum BLE ATT MTU for this iOS device.
            if #available(iOS 11.0, *) {
                // For iOS 11.0+ (527 - 3)
                return 524
            }
            if #available(iOS 10.0, *) {
                // For iOS 10.0 (185 - 3)
                return 182
            } else {
                // For iOS 9.0 (158 - 3)
                return 155
            }
        case .coapBle, .coapUdp:
            return 1024
        }
    }
}

extension McuManager {
    
    func log(msg: @autoclosure () -> String, atLevel level: McuMgrLogLevel) {
        if let logDelegate, level >= logDelegate.minLogLevel() {
            logDelegate.log(msg(), ofCategory: Self.TAG, atLevel: level)
        }
    }
}

// MARK: - McuManagerCallback

public typealias McuMgrCallback<T: McuMgrResponse> = (T?, Error?) -> Void

// MARK: - McuManagerError

public enum McuManagerError: Error, LocalizedError {
    
    case mtuValueOutsideOfValidRange(_ newValue: Int)
    case mtuValueHasNotChanged(_ newValue: Int)
    case returnCode(_ rc: McuMgrReturnCode)
    case returnCodeValue(_ rc: UInt64)
    
    public var errorDescription: String? {
        switch self {
        case .mtuValueOutsideOfValidRange(let newMtu):
            return "New MTU Value \(newMtu) is outside valid range of \(McuManager.ValidMTURange.lowerBound)...\(McuManager.ValidMTURange.upperBound)"
        case .mtuValueHasNotChanged(let newMtu):
            return "MTU Value already set to \(newMtu)"
        case .returnCode(let rc):
            return "Remote Error: \(rc)"
        case .returnCodeValue(let code):
            return "Remote Error: \(code)"
        }
    }
}

// MARK: - McuMgrGroup

/// The defined groups for Mcu Manager commands.
///
/// Each group has its own manager class which contains the specific subcommands
/// and functions. The default are contained within the McuManager class.
public enum McuMgrGroup: UInt16 {
    /// Default command group (DefaultManager).
    case OS = 0
    /// Image command group (ImageManager).
    case image = 1
    /// Statistics command group (StatsManager).
    case statistics = 2
    /// System configuration command group (SettingsManager).
    case settings = 3
    /// Log command group (LogManager).
    case logs = 4
    /// Crash command group (CrashManager).
    case crash = 5
    /// Split image command group (Not implemented).
    case split = 6
    /// Run test command group (RunManager).
    case run = 7
    /// File System command group (FileSystemManager).
    case filesystem = 8
    /// Shell Command Group (ShellManager).
    case shell = 9
    /// Per user command group, value must be >= 64.
    case perUser = 64
    /// SUIT Command Group (SuitManager).
    case suit = 66
    
    /** 
     * Basic command group (BasicManager).
     *
     * Zephyr-specific groups decrease from PERUSER to avoid collision with upstream and
     * user-defined groups.
     */
    case basic = 63 // PerUser - 1
}

// MARK: - McuMgrVersion

/// The mcu manager operation defines whether the packet sent is a read/write
/// and request/response.
public enum McuMgrVersion: UInt8, CustomDebugStringConvertible {
    case SMPv1 = 0
    case SMPv2 = 1
    
    public var debugDescription: String {
        switch self {
        case .SMPv1:
            return "SMPv1"
        case .SMPv2:
            return "SMPv2"
        }
    }
}

// MARK: - McuMgrOperation

/// The mcu manager operation defines whether the packet sent is a read/write
/// and request/response.
public enum McuMgrOperation: UInt8 {
    case read           = 0
    case readResponse   = 1
    case write          = 2
    case writeResponse  = 3
}

public enum McuMgrError: Error, LocalizedError {
    case returnCode(_ rc: McuMgrReturnCode)
    case groupCode(_ group: McuMgrGroupReturnCode)
    
    public var errorDescription: String? {
        switch self {
        case .returnCode(let rc):
            return rc.description
        case .groupCode(let groupCode):
            return groupCode.groupError()?.errorDescription
        }
    }
}

// MARK: - McuMgrGroupReturnCode

public class McuMgrGroupReturnCode: CBORMappable {
    
    public var group: UInt64 = 0
    
    public var rc: McuMgrReturnCode = .ok
    
    public required init(cbor: CBOR?) throws {
        try super.init(cbor: cbor)
        if case let CBOR.unsignedInt(group)? = cbor?["group"] {
            self.group = group
        }
        if case let CBOR.unsignedInt(rc)? = cbor?["rc"] {
            self.rc = McuMgrReturnCode(rawValue: rc) ?? .ok
        }
    }
    
    public init(map: [CBOR: CBOR]) throws {
        try super.init(cbor: nil)
        if case let CBOR.unsignedInt(group)? = map["group"] {
            self.group = group
        }
        if case let CBOR.unsignedInt(rc)? = map["rc"] {
            self.rc = McuMgrReturnCode(rawValue: rc) ?? .ok
        }
    }
    
    public func groupError() -> LocalizedError? {
        guard rc != .ok else { return nil }
        
        let error: LocalizedError?
        switch McuMgrGroup(rawValue: UInt16(group)) {
        case .OS:
            error = OSManagerError(rawValue: rc.rawValue)
        case .image:
            error = ImageManagerError(rawValue: rc.rawValue)
        case .statistics:
            error = StatsManagerError(rawValue: rc.rawValue)
        case .settings:
            error = SettingsManagerError(rawValue: rc.rawValue)
        case .filesystem:
            error = FileSystemManagerError(rawValue: rc.rawValue)
        case .basic:
            error = BasicManagerError(rawValue: rc.rawValue)
        default:
            // Passthrough to McuMgr 'RC' Errors for Unknown
            // or Unsupported values.
            error = McuManagerError.returnCodeValue(rc.rawValue)
        }
        return error ?? McuManagerError.returnCodeValue(rc.rawValue)
    }
}

// MARK: - McuMgrReturnCode

/**
 Return codes for `McuMgrResponse`.
 
 All Mcu Manager responses contain a "rc" key with a return code. If
 they don't, `.ok` is assumed.
 */
public enum McuMgrReturnCode: UInt64, Error {
    case ok                = 0
    case unknown           = 1
    case noMemory          = 2
    case inValue           = 3
    case timeout           = 4
    case noEntry           = 5
    case badState          = 6
    case responseIsTooLong = 7
    case unsupported       = 8
    case corruptPayload    = 9
    case busy              = 10
    case accessDenied      = 11
    case unsupportedTooOld = 12
    case unsupportedTooNew = 13
    case userDefinedError  = 256
    
    case unrecognized
    
    public func isSuccess() -> Bool {
        return self == .ok
    }
    
    public func isSupported() -> Bool {
        switch self {
        case .unsupported, .unsupportedTooOld, .unsupportedTooNew:
            return false
        default:
            return true
        }
    }
    
    public func isError() -> Bool {
        return self != .ok
    }
}

extension McuMgrReturnCode: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .ok:
            return "OK"
        case .unknown:
            return "Unknown error"
        case .noMemory:
            return "No memory"
        case .inValue:
            return "Invalid value"
        case .timeout:
            return "Timeout"
        case .noEntry:
            return "No entry" // For Filesystem Operations, Does Your Mounting Point Match Your Target Firmware / Device?
        case .badState:
            return "Bad state"
        case .responseIsTooLong:
            return "Response is too long"
        case .unsupported:
            return "Not supported"
        case .corruptPayload:
            return "Corrupt payload"
        case .busy:
            return "Busy, try again later" // Busy processing previous SMP Request
        case .accessDenied:
            return "Access denied" // Are You Trying to Downgrade to a Lower Image Version?
        case .unsupportedTooOld:
            return "Requested SMP McuMgr protocol version is too old"
        case .unsupportedTooNew:
            return "Requested SMP McuMgr protocol version is too new"
        case .userDefinedError:
            return "User-Defined Error"
        default:
            if rawValue >= McuMgrReturnCode.userDefinedError.rawValue {
                return "User-Defined Error (Code: \(rawValue))"
            } else {
                return "Unrecognized (RC: \(rawValue))"
            }
        }
    }
}

extension McuMgrReturnCode: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        if case .unrecognized = self {
            return description
        }
        return "\(description) (RC: \(rawValue))"
    }
    
}
