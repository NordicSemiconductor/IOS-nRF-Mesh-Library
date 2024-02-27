/*
* Copyright (c) 2019, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

import Foundation

/// A base protocol for all Configuration messages.
///
/// Configuration messages are used to configure Nodes. They are sent between
/// Configuration Client model on the Configuration Manager and Configuration Server
/// model on the device, which is being configured. All Config messages are encrypted
/// using target Node's Device Key.
public protocol ConfigMessage: StaticMeshMessage {
    // No additional fields.
}

/// A base protocol for unacknowledged Configuration messages.
///
/// Unacknowledged configuration messages are sent as replies to acknowledged messages.
public protocol UnacknowledgedConfigMessage: ConfigMessage, UnacknowledgedMeshMessage {
    // No additional fields.
}

/// The base class for response messages.
public protocol ConfigResponse: StaticMeshResponse, UnacknowledgedConfigMessage {
    // No additional fields.
}

/// A base protocol for acknowledged Configuration messages.
///
/// Acknowledged messages will be responded with a status message.
public protocol AcknowledgedConfigMessage: ConfigMessage, StaticAcknowledgedMeshMessage {
    // No additional fields.
}

/// The status of a Config operation.
public enum ConfigMessageStatus: UInt8 {
    /// Success.
    case success                        = 0x00
    /// Invalid Address.
    case invalidAddress                 = 0x01
    // Invalid Model.
    case invalidModel                   = 0x02
    // Invalid AppKey Index.
    case invalidAppKeyIndex             = 0x03
    // Invalid NetKey Index.
    case invalidNetKeyIndex             = 0x04
    // Insufficient Resources.
    case insufficientResources          = 0x05
    // Key Index Already Stored.
    case keyIndexAlreadyStored          = 0x06
    // Invalid Publish Parameters.
    case invalidPublishParameters       = 0x07
    // Not a Subscribe Model.
    case notASubscribeModel             = 0x08
    // Storage Failure.
    case storageFailure                 = 0x09
    // Feature Not Supported.
    case featureNotSupported            = 0x0A
    // Cannot Update.
    case cannotUpdate                   = 0x0B
    // Cannot Remove.
    case cannotRemove                   = 0x0C
    // Cannot Bind.
    case cannotBind                     = 0x0D
    // Temporarily Unable to Change State.
    case temporarilyUnableToChangeState = 0x0E
    // Cannot Set.
    case cannotSet                      = 0x0F
    // Unspecified Error.
    case unspecifiedError               = 0x10
    // Invalid Binding.
    case invalidBinding                 = 0x11
}

/// A base protocol for config status messages.
public protocol ConfigStatusMessage: ConfigMessage, StatusMessage {
    /// Operation status.
    var status: ConfigMessageStatus { get }
}

/// A base protocol for config messages related to Network Keys.
public protocol ConfigNetKeyMessage: ConfigMessage {
    /// The Network Key Index.
    var networkKeyIndex: KeyIndex { get }
}

/// A base protocol for config messages related to Application Keys.
public protocol ConfigAppKeyMessage: ConfigMessage {
    /// Application Key Index.
    var applicationKeyIndex: KeyIndex { get }
}

/// A base protocol for config messages related to Network Key and Application Key.
public protocol ConfigNetAndAppKeyMessage: ConfigNetKeyMessage, ConfigAppKeyMessage {
    // No additional fields.
}

/// A base protocol for config messages related to Elements.
public protocol ConfigElementMessage: ConfigMessage {
    /// The Unicast Address of the Model's parent Element.
    var elementAddress: Address { get }
}

/// A base protocol for config messages related to Models.
public protocol ConfigModelMessage: ConfigElementMessage {
    /// The 16-bit Model identifier.
    var modelIdentifier: UInt16 { get }
    /// The 32-bit Model identifier.
    var modelId: UInt32 { get }
}

/// A base protocol for config messages related to Models, where the Model can be
/// a vendor model.
public protocol ConfigAnyModelMessage: ConfigModelMessage {
    /// The Company identified, as defined in Assigned Numbers, or `nil`,
    /// if the Model is defined in Bluetooth Mesh Model Specification.
    ///
    /// - seeAlso: https://www.bluetooth.com/specifications/assigned-numbers/company-identifiers/
    var companyIdentifier: UInt16? { get }
}

/// A base protocol for config messages related to vendor Models.
public protocol ConfigVendorModelMessage: ConfigModelMessage {
    /// The Company identified, as defined in Assigned Numbers.
    ///
    /// - seeAlso: https://www.bluetooth.com/specifications/assigned-numbers/company-identifiers/
    var companyIdentifier: UInt16 { get }
}

/// A base protocol for config messages with an Address property.
public protocol ConfigAddressMessage: ConfigMessage {
    /// Value of the Address.
    var address: Address { get }
}

/// A base protocol for config messages with Virtual Label property.
public protocol ConfigVirtualLabelMessage: ConfigMessage {
    /// Value of the 128-bt Virtual Label UUID.
    var virtualLabel: UUID { get }
}

/// A base protocol for config messages with list of Application Keys.
public protocol ConfigModelAppList: ConfigModelMessage {
    /// Application Key Indexes bound to the Model.
    var applicationKeyIndexes: [KeyIndex] { get }
}

/// A base protocol for config messages with list of Model subscription addresses.
public protocol ConfigModelSubscriptionList: ConfigModelMessage {
    /// A list of Addresses.
    var addresses: [Address] { get }
}

/// This enum represents number of periodic Heartbeat messages remaining to be sent.
@frozen public enum RemainingHeartbeatPublicationCount {
    /// Periodic Heartbeat messages are not published.
    case disabled
    /// Periodic Heartbeat messages are published indefinitely.
    case indefinitely
    /// Exact remaining count of periodic Heartbeat messages.
    ///
    /// Exact count is only available when the count goes down to 2 and 1;
    /// otherwise a range is returned.
    case exact(_ value: UInt16)
    /// Remaining count of periodic Heartbeat messages represented as range.
    case range(_ range: ClosedRange<UInt16>)
    /// Unsupported CountLog value sent.
    case invalid(countLog: UInt8)
}

/// This enum represents remaining period for processing Heartbeat messages, in seconds.
@frozen public enum RemainingHeartbeatSubscriptionPeriod {
    /// Heartbeat messages are not processed.
    case disabled
    /// Exact remaining period for processing Heartbeat messages, in seconds.
    ///
    /// Exact period is only available when the count goes down to 1 or when is maximum;
    /// otherwise a range is returned.
    case exact(_ value: UInt16)
    /// Remaining period for processing Heartbeat messages as range, in seconds.
    case range(_ range: ClosedRange<UInt16>)
    /// Unsupported PeriodLog value sent.
    case invalid(periodLog: UInt8)
}

/// This enum represents the number of Heartbeat messages received.
@frozen public enum HeartbeatSubscriptionCount {
    /// Number of Heartbeat messages received.
    ///
    /// Exact count is only available when there was none, or only one Heartbeat message
    /// received.
    case exact(_ value: UInt16)
    /// Number of Heartbeat messages received as range.
    case range(_ range: ClosedRange<UInt16>)
    /// More than 0xFFFE messages have been received.
    case reallyALot
    /// Unsupported CountLog value sent.
    case invalid(countLog: UInt8)
}

/// The Random Update Interval Steps state determines the cadence of updates to the
/// Random field in the Mesh Private beacon.
///
/// The Random Update Interval Steps are defined in units of 10 seconds, with an
/// approximate maximum value of 42 minutes.
///
/// The default value of this state shall be ``RandomUpdateIntervalSteps/interval(n:)``
/// with value n = 60 (0x3C) (i.e., 10 minutes).
@frozen public enum RandomUpdateIntervalSteps {
    /// Random field is updated for every Mesh Private beacon.
    case everyTime
    /// Random field is updated at an interval (in 10 seconds steps).
    case interval(n: UInt8)
}

internal extension ConfigMessage {
    
    /// Encodes given list of Key Indexes into a Data.
    /// As each Key Index is 12 bits long, a pair of them can fit 3 bytes.
    /// This method ensures that they are packed in compliance to the
    /// Bluetooth Mesh specification.
    ///
    /// - parameter limit:  Maximum number of Key Indexes to encode.
    /// - parameter indexes: An array of 12-bit Key Indexes.
    /// - returns: Key Indexes encoded to a Data.
    func encode(_ limit: Int = 10000, indexes: ArraySlice<KeyIndex>) -> Data {
        if limit == 0 || indexes.isEmpty {
            return Data()
        }
        if limit == 1 || indexes.count == 1 {
            // Encode a single Key Index into 2 bytes.
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
            // Decode a single Key Index from 2 bytes.
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
    
    /// Whether the operation was successful or not.
    var isSuccess: Bool {
        return status == .success
    }
    
    /// String representation of the status.
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
    /// by the ``ModelDelegate`` from a list of ``ConfigMessage``s.
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

extension RemainingHeartbeatPublicationCount: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .disabled:
            return "Disabled"
        case .indefinitely:
            return "Indefinitely"
        case .invalid(let value):
            return "Invalid: \(value.hex)"
        case .range(let range):
            return range.description
        case .exact(let value):
            return "\(value)"
        }
    }
    
}

extension RemainingHeartbeatSubscriptionPeriod: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .disabled:
            return "Disabled"
        case .invalid(let value):
            return "Invalid: \(value.hex)"
        case .range(let range):
            return "\(range.description) sec"
        case .exact(let value):
            return "\(value) sec"
        }
    }
    
}

extension HeartbeatSubscriptionCount: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .invalid(let value):
            return "Invalid: \(value.hex)"
        case .range(let range):
            return range.description
        case .exact(let value):
            return "\(value)"
        case .reallyALot:
            return "More than 65534"
        }
    }
    
}

extension RandomUpdateIntervalSteps: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .everyTime:
            return "Random field is updated for every Mesh Private beacon"
        case .interval(n: let n):
            return "Random field is updated every \(n * 10) sec."
        }
    }
    
}
