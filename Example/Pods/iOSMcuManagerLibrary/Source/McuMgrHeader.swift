/*
 * Copyright (c) 2017-2018 Runtime Inc.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

/// Represents an 8-byte McuManager header.
public class McuMgrHeader {
    
    /// Header length.
    public static let HEADER_LENGTH = 8
    
    public let version: UInt8!
    public let op: UInt8!
    public let flags: UInt8!
    public let length: UInt16!
    public let groupId: UInt16!
    public let sequenceNumber: McuSequenceNumber!
    public let commandId: UInt8!
    
    /// Initialize the header with raw data. Because this method only parses the
    /// first eight bytes of the input data, the data's count must be greater or
    /// equal than eight.
    ///
    /// - parameter data: The data to parse. Data count must be greater than or
    ///   equal to eight.
    /// - throws: McuMgrHeaderParseException.invalidSize(Int) if the data count
    ///   is too small.
    public init(data: Data) throws {
        if (data.count < McuMgrHeader.HEADER_LENGTH) {
            throw McuMgrHeaderParseError.invalidSize(data.count)
        }
        // First Byte: 7 6 5     4 3      2 1 0
        //             Reserved  Version  Op
        version = (data[0] >> 3) & 0b11
        op = data[0] & 0b11
        flags = data[1]
        length = data.readBigEndian(offset: 2)
        groupId = data.readBigEndian(offset: 4)
        sequenceNumber = data[6]
        commandId = data[7]
    }
    
    public init(version: UInt8, op: UInt8, flags: UInt8, length: UInt16,
                groupId: UInt16, sequenceNumber: McuSequenceNumber,
                commandId: UInt8) {
        self.version = version
        self.op = op
        self.flags = flags
        self.length = length
        self.groupId = groupId
        self.sequenceNumber = sequenceNumber
        self.commandId = commandId
    }
    
    public func toData() -> Data {
        var data = Data(count: McuMgrHeader.HEADER_LENGTH)
        // First Byte: 7 6 5     4 3      2 1 0
        //             Reserved  Version  Op
        let firstByte: UInt8 = (version << 3) + op
        data.append(firstByte)
        data.append(flags)
        data.append(Data(from: length))
        data.append(Data(from: groupId))
        data.append(sequenceNumber)
        data.append(commandId)
        return data
    }
    
    /// Helper function to build a raw mcu manager header.
    ///
    /// - parameter version: The SMP Protocol version.
    /// - parameter op: The Mcu Manager operation.
    /// - parameter flags: Optional flags.
    /// - parameter len: Optional length.
    /// - parameter group: The group id for this command.
    /// - parameter seq: Optional sequence number.
    /// - parameter id: The subcommand id for the given group.
    public static func build(version: UInt8, op: UInt8, flags: UInt8, len: UInt16, group: UInt16,
                             seq: McuSequenceNumber, id: UInt8) -> [UInt8] {
        // First Byte: 7 6 5     4 3      2 1 0
        //             Reserved  Version  Op
        let firstByte: UInt8 = ((version & 0b11) << 3) + op
        return [firstByte, flags, UInt8(len >> 8), UInt8(len & 0xFF), UInt8(group >> 8), UInt8(group & 0xFF), seq, id]
    }
}

// MARK: - CustomDebugStringConvertible

extension McuMgrHeader: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return "{\"version\": \"\(version!)\", \"op\": \"\(op!)\", \"flags\": \(flags!), \"length\": \(length!), \"group\": \(groupId!), \"seqNum\": \(sequenceNumber!), \"commandId\": \(commandId!)}"
    }
}

// MARK: - McuMgrHeaderParseError

public enum McuMgrHeaderParseError: Error, LocalizedError {
    case invalidSize(Int)

    public var errorDescription: String? {
        switch self {
        case .invalidSize(let size):
            return "Invalid header size: \(size) (expected: \(McuMgrHeader.HEADER_LENGTH))."
        }
    }
}

// MARK: - Data Extension

internal extension Data {
    
    func readMcuMgrHeaderSequenceNumber() -> McuSequenceNumber? {
        guard count >= McuMgrHeader.HEADER_LENGTH else { return nil }
        return read(offset: 6) as McuSequenceNumber
    }
}
