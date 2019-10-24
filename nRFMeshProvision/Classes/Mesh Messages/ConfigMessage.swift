//
//  ConfigMessage.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 09/06/2019.
//

import Foundation


public protocol ConfigMessage: StaticMeshMessage {
    // No additional fields.
}
public protocol AcknowledgedConfigMessage: ConfigMessage, StaticAcknowledgedMeshMessage {
    // No additional fields.
}

/// The status of a Config operation.
public enum ConfigMessageStatus: UInt8 {
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

public protocol ConfigStatusMessage: ConfigMessage, StatusMessage {
    /// Operation status.
    var status: ConfigMessageStatus { get }
}

public protocol ConfigNetKeyMessage: ConfigMessage {
    /// The Network Key Index.
    var networkKeyIndex: KeyIndex { get }
}

public protocol ConfigAppKeyMessage: ConfigMessage {
    /// Application Key Index.
    var applicationKeyIndex: KeyIndex { get }
}

public protocol ConfigNetAndAppKeyMessage: ConfigNetKeyMessage, ConfigAppKeyMessage {
    // No additional fields.
}

public protocol ConfigElementMessage: ConfigMessage {
    /// The Unicast Address of the Model's parent Element.
    var elementAddress: Address { get }
}

public protocol ConfigModelMessage: ConfigElementMessage {
    /// The 16-bit Model identifier.
    var modelIdentifier: UInt16 { get }
    /// The 32-bit Model identifier.
    var modelId: UInt32 { get }
}

public protocol ConfigAnyModelMessage: ConfigModelMessage {
    /// The Company identified, as defined in Assigned Numbers, or `nil`,
    /// if the Model is defined in Bluetooth Mesh Model Specification.
    ///
    /// - seeAlso: https://www.bluetooth.com/specifications/assigned-numbers/company-identifiers/
    var companyIdentifier: UInt16? { get }
}

public protocol ConfigVendorModelMessage: ConfigModelMessage {
    /// The Company identified, as defined in Assigned Numbers.
    ///
    /// - seeAlso: https://www.bluetooth.com/specifications/assigned-numbers/company-identifiers/
    var companyIdentifier: UInt16 { get }
}

public protocol ConfigAddressMessage: ConfigMessage {
    /// Value of the Address.
    var address: Address { get }
}

public protocol ConfigVirtualLabelMessage: ConfigMessage {
    /// Value of the 128-bt Virtual Label UUID.
    var virtualLabel: UUID { get }
}

public protocol ConfigModelAppList: ConfigStatusMessage, ConfigModelMessage {
    /// Application Key Indexes bound to the Model.
    var applicationKeyIndexes: [KeyIndex] { get }
}

public protocol ConfigModelSubscriptionList: ConfigStatusMessage, ConfigModelMessage {
    /// A list of Addresses.
    var addresses: [Address] { get }
}

internal extension ConfigMessage {
    
    /// Encodes given list of Key Indexes into a Data.
    /// As each Key Index is 12 bits long, a pair of them can fit 3 bytes.
    /// This method ensures that they are packed in compliance to the
    /// Bluetooth Mesh specification.
    ///
    /// - parameter limit:  Maximim number of Key Indexes to encode.
    /// - parameter indexes: An array of 12-bit Key Indexes.
    /// - returns: Key Indexes encoded to a Data.
    func encode(_ limit: Int = 10000, indexes: ArraySlice<KeyIndex>) -> Data {
        if limit == 0 || indexes.isEmpty {
            return Data()
        }
        if limit == 1 || indexes.count == 1 {
            // Encode a sigle Key Index into 2 bytes.
            return Data() + indexes.first!.littleEndian
        } else {
            // Encode a pair of Key Indexes into 3 bytes.
            let first  = indexes.first!
            let second = indexes.dropFirst().first!
            let pair: UInt32 = UInt32(first) << 12 | UInt32(second)
            return (Data() + pair.littleEndian).dropLast() + encode(limit - 2, indexes: indexes.dropFirst(2))
        }
    }
    
    /// Decodes number of Key Indexes from the given Data from the given offset.
    /// This will decode as many Indexes as possible, until the end of data is
    /// reached.
    ///
    /// - parameter limit:  Maximum number of Key Indexes to decode.
    /// - parameter data:   The data from where the indexes should be read.
    /// - parameter offset: The offset from where to read the indexes.
    /// - returns: Decoded Key Indexes.
    static func decode(_ limit: Int = 10000, indexesFrom data: Data, at offset: Int) -> [KeyIndex] {
        let size = data.count - offset
        guard limit > 0 && size >= 2 else {
            return []
        }
        if limit == 1 || size == 2 {
            // Decode a sigle Key Index from 2 bytes.
            let index: KeyIndex = UInt16(data[offset + 1]) << 8 | UInt16(data[offset])
            return [index]
        } else {
            // Decode a pair of Key Indexes from 3 bytes.
            let first:  KeyIndex = UInt16(data[offset + 2]) << 4 | UInt16(data[offset + 1] >> 4)
            let second: KeyIndex = UInt16(data[offset + 1] & 0x0F) << 8 | UInt16(data[offset])
            return [first, second] + decode(limit - 2, indexesFrom: data, at: offset + 3)
        }
    }
    
}

public extension ConfigStatusMessage {
    
    var isSuccess: Bool {
        return status == .success
    }
    
    var message: String {
        return "\(status)"
    }
    
}

internal extension ConfigNetKeyMessage {
    
    /// Encodes Network Key Index in 2 bytes using Little Endian.
    ///
    /// - returns: Key Index encoded in 2 bytes.
    func encodeNetKeyIndex() -> Data {
        return encode(indexes: [networkKeyIndex])
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
        return decode(1, indexesFrom: data, at: offset).first!
    }
    
}

internal extension ConfigNetAndAppKeyMessage {
    
    /// Encodes Network Key Index and Application Key Index in 3 bytes
    /// using Little Endian.
    ///
    /// - returns: Key Indexes encoded in 3 bytes.
    func encodeNetAndAppKeyIndex() -> Data {
        return encode(indexes: [applicationKeyIndex, networkKeyIndex])
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
    static func decodeNetAndAppKeyIndex(from data: Data, at offset: Int) -> (networkKeyIndex: KeyIndex, applicationKeyIndex: KeyIndex) {
        let indexes = decode(2, indexesFrom: data, at: offset)
        return (indexes[1], indexes[0])
    }
    
}

public extension ConfigModelMessage {
    
    var modelId: UInt32 {
        return UInt32(modelIdentifier)
    }
    
}

public extension ConfigAnyModelMessage {
    
    /// Returns `true` for Models with identifiers assigned by Bluetooth SIG,
    /// `false` otherwise.
    var isBluetoothSIGAssigned: Bool {
        return companyIdentifier == nil
    }
    
    var modelId: UInt32 {
        if let companyIdentifier = companyIdentifier {
            return (UInt32(companyIdentifier) << 16) | UInt32(modelIdentifier)
        } else {
            return UInt32(modelIdentifier)
        }
    }
    
}

public extension ConfigVendorModelMessage {
    
    var modelId: UInt32 {
        return (UInt32(companyIdentifier) << 16) | UInt32(modelIdentifier)
    }
    
}

public extension Array where Element == ConfigMessage.Type {
    
    /// A helper method that can create a map of message types required
    /// by the `ModelDelegate` from a list of `ConfigMessage`s.
    ///
    /// - returns: A map of message types.
    func toMap() -> [UInt32 : MeshMessage.Type] {
        return (self as [StaticMeshMessage.Type]).toMap()
    }
    
}

extension ConfigMessageStatus: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .success:                        return "Success"
        case .invalidAddress:                 return "Invalid Address"
        case .invalidModel:                   return "Invalid Model"
        case .invalidAppKeyIndex:             return "Invalid Application Key Index"
        case .invalidNetKeyIndex:             return "Invalid Network Key Index"
        case .insufficientResources:          return "Insufficient resources"
        case .keyIndexAlreadyStored:          return "Key Index already stored"
        case .invalidPublishParameters:       return "Invalid publish parameters"
        case .notASubscribeModel:             return "Not a Subscribe Model"
        case .storageFailure:                 return "Storage failure"
        case .featureNotSupported:            return "Feature not supported"
        case .cannotUpdate:                   return "Cannot update"
        case .cannotRemove:                   return "Cannot remove"
        case .cannotBind:                     return "Cannot bind"
        case .temporarilyUnableToChangeState: return "Temporarily unable to change state"
        case .cannotSet:                      return "Cannot set"
        case .unspecifiedError:               return "Unspecified error"
        case .invalidBinding:                 return "Invalid binding"
        }
    }
    
}
