//
//  ConfigMessage.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 09/06/2019.
//

import Foundation

public protocol ConfigMessage: MeshMessage {
    // Empty
}

// The status of App or Net Key operation.
public enum ConfigKeyStatus: UInt8 {
    case success                        = 0x00
    case invalidAddress                 = 0x01
    case invalidModel                   = 0x02
    case invalidAppKeyIndex             = 0x03
    case invalidNetKeyIndex             = 0x04
    case insufficientResources          = 0x05
    case keyIndexAlreadyStored          = 0x06
    case invalidPublishParameters       = 0x07
    case notASubscribeModel             = 0x08
    case storageFailure                 = 0x09
    case featureNotSupported            = 0x0A
    case cannotUpdate                   = 0x0B
    case cannotRemove                   = 0x0C
    case cannotBind                     = 0x0D
    case temporarilyUnableToChangeState = 0x0E
    case cannotSet                      = 0x0F
    case unspecifiedError               = 0x10
    case invalidBinding                 = 0x11
}

public protocol ConfigNetKeyMessage: ConfigMessage {
    /// The Network Key Index.
    var networkKeyIndex: KeyIndex { get }
}

public protocol ConfigAppKeyMessage: ConfigNetKeyMessage {
    /// Application Key Index.
    var applicationKeyIndex: KeyIndex { get }
}

internal extension ConfigMessage {
    
    /// Encodes given list of Key Indexes into a Data.
    /// As each Key Index is 12 bits long, a pair of them can fit 3 bytes.
    /// This method ensures that they are packed in compliance to the
    /// Bluetooth Mesh specification.
    ///
    /// - parameter indexes: An array of 12-bit Key Indexes.
    /// - returns: Key Indexes encoded to a Data.
    func encodeIndexes(_ indexes: ArraySlice<KeyIndex>) -> Data {
        if indexes.isEmpty {
            return Data()
        }
        if indexes.count == 1 {
            // Encode a sigle Key Index into 2 bytes.
            return Data() + indexes.first!.littleEndian
        } else {
            // Encode a pair of Key Indexes into 3 bytes.
            let first  = indexes.first!
            let second = indexes.dropFirst().first!
            let pair: UInt32 = UInt32(first) << 12 | UInt32(second)
            return (Data() + pair.littleEndian).dropLast() + encodeIndexes(indexes.dropFirst(2))
        }
    }
    
    /// Decodes number of Key Indexes from the given Data from the given offset.
    /// This will decode as many Indexes as possible, until the end of data is
    /// reached.
    ///
    /// - parameter data: The data from where the indexes should be read.
    /// - parameter offset: The offset from where to read the indexes.
    /// - returns: Decoded Key Indexes.
    static func decodeIndexes(from data: Data, at offset: Int) -> [KeyIndex] {
        let size = data.count - offset
        guard size >= 2 else {
            return []
        }
        if size == 2 {
            // Decode a sigle Key Index from 2 bytes.
            let index: KeyIndex = UInt16(data[offset + 1]) << 8 | UInt16(data[offset])
            return [index]
        } else {
            // Decode a pair of Key Indexes from 3 bytes.
            let first:  KeyIndex = UInt16(data[offset + 2]) << 4 | UInt16(data[offset + 1] >> 4)
            let second: KeyIndex = UInt16(data[offset + 1] & 0x0F) << 8 | UInt16(data[offset])
            return [first, second] + decodeIndexes(from: data, at: offset + 3)
        }
    }
    
}

internal extension ConfigNetKeyMessage {
    
    /// Encodes Network Key Index in 2 bytes using Little Endian.
    ///
    /// - returns: Key Index encoded in 2 bytes.
    func encodeNetKeyIndex() -> Data {
        return encodeIndexes([networkKeyIndex])
    }
    
    /// Decodes the Network Key Index from 2 bytes at given offset.
    ///
    /// There are no any checks whether the data at the given offset
    /// are valid, or even if the offset is not outside of the data range.
    ///
    /// - parameter data: The data from where the indexes should be read.
    /// - parameter offset: The offset from where to read the indexes.
    /// - returns: Decoded Key Index.
    static func decodeNetKeyIndex(from data: Data, at offset: Int) -> KeyIndex {
        return decodeIndexes(from: data, at: offset).first!
    }
    
}

internal extension ConfigAppKeyMessage {
    
    /// Encodes Network Key Index and Application Key Index in 3 bytes
    /// using Little Endian.
    ///
    /// - returns: Key Indexes encoded in 3 bytes.
    func encodeNetKeyAndAppKeyIndex() -> Data {
        return encodeIndexes([networkKeyIndex, applicationKeyIndex])
    }
    
    /// Decodes the Network Key Index and Application Key Index from
    /// 3 bytes at given offset.
    ///
    /// There are no any checks whether the data at the given offset
    /// are valid, or even if the offset is not outside of the data range.
    ///
    /// - parameter data: The data from where the indexes should be read.
    /// - parameter offset: The offset from where to read the indexes.
    /// - returns: Decoded Key Indexes.
    static func decodeNetKeyAndAppKeyIndex(from data: Data, at offset: Int) -> (networkKeyIndex: KeyIndex, applicationKeyIndex: KeyIndex) {
        let indexes = decodeIndexes(from: data, at: offset)
        return (indexes[0], indexes[1])
    }
    
}

extension ConfigKeyStatus: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .success:
            return "Success"
        case .invalidAddress:
            return "Invalid Address"
        case .invalidModel:
            return "Invalid Model"
        case .invalidAppKeyIndex:
            return "Invalid Application Key Index"
        case .invalidNetKeyIndex:
            return "Invalid Network Key Index"
        case .insufficientResources:
            return "Insufficient resources"
        case .keyIndexAlreadyStored:
            return "Key Index already stored"
        case .invalidPublishParameters:
            return "Invalid publish parameters"
        case .notASubscribeModel:
            return "Not a Subscribe Model"
        case .storageFailure:
            return "Storage failure"
        case .featureNotSupported:
            return "Feature not supported"
        case .cannotUpdate:
            return "Cannot update"
        case .cannotRemove:
            return "Cannot remove"
        case .cannotBind:
            return "Cannot bind"
        case .temporarilyUnableToChangeState:
            return "Temporarily unable to change state"
        case .cannotSet:
            return "Cannot set"
        case .unspecifiedError:
            return "Unspecified error"
        case .invalidBinding:
            return "Invalid binding"            
        }
    }
    
}
