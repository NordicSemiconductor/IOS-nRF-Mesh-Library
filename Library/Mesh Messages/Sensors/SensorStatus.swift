/*
* Copyright (c) 2021, Nordic Semiconductor
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

/// A Device Property with corresponding characteristic.
public typealias SensorValue = (property: DeviceProperty, value: DevicePropertyCharacteristic)

public struct SensorStatus: StaticMeshResponse {
    public static let opCode: UInt32 = 0x52
    
    /// The sensor values.
    public let values: [SensorValue]
    
    public var parameters: Data? {
        return values.reduce(Data()) { $0 + Self.marshal($1) }
    }
    
    /// Creates the Sensor Status message.
    ///
    /// - parameter value: A single property values. Maximum data length is 128 octets.
    public init(_ value: SensorValue) {
        self.init([value])
    }
    
    /// Creates the Sensor Status message.
    ///
    /// - parameter values: A list of property values. Maximum data length for each value
    ///                     is 128 octets.
    public init(_ values: [SensorValue]) {
        self.values = values
    }
    
    public init?(parameters: Data) {
        values = Self.unmarshall(parameters)
    }
    
}

private extension SensorStatus {
    
    /// Marshalls the given property value to format A or B, depending on the
    /// Property ID and data length.
    ///
    /// - parameter value: The property value to be marshalled.
    /// - returns: The marshalled data.
    static func marshal(_ value: SensorValue) -> Data {
        let data = value.value.data.prefix(128)
        let length: UInt8 = UInt8(data.count)
        
        // Can the data be encoded using Format A?
        // - Property ID must be less than 2048
        // - Value length must be in range 1-16
        // Otherwise, use Format B.
        if value.property.id < 2048 && length >= 1 && length <= 16 {
            // Format A
            let len = length - 1
            let octet0 = 0b00 | (len << 1) | UInt8((value.property.id & 0x07) << 5)
            let octet1 = UInt8(value.property.id >> 3)
            return Data([octet0, octet1]) + data
        } else {
            // Format B
            let len = length == 0 ? 0x7F : length - 1
            let octet0 = 0b01 | (len << 1)
            return Data([octet0]) + value.property.id.bigEndian + data
        }
    }
    
    /// Unmarshalls the received data.
    ///
    /// - parameter data: The received data.
    /// - returns: List of sensor values.
    static func unmarshall(_ data: Data) -> [SensorValue] {
        var result: [SensorValue] = []
        var offset = 0
        while offset < data.count {
            // At least 3 bytes per MPID + Raw Value.
            // In Format A the data must be at least 1 byte long, which gives min 3 bytes.
            // In Format B the data can be 0 octets long, but the MPID is 3 bytes.
            // Decode Format field.
            let type = data[offset] & 0b1
            if type == 0b0 {
                // Format A
                let length = Int((data[offset] >> 1) & 0xF) + 1
                guard data.count >= offset + 2 + length else {
                    // Skip this TLV as invalid
                    offset += 2 + length
                    continue
                }
                let propertyId = UInt16(data[offset]) >> 5 | (UInt16(data[offset + 1]) << 3)
                let property = DeviceProperty(propertyId)
                guard property.valueLength == nil || property.valueLength == length else {
                    // Skip this TLV as invalid
                    offset += 2 + length
                    continue
                }
                let value = property.read(from: data, at: offset + 2, length: length)
                result.append((property, value))
                offset += 2 + length
            } else {
                // Format B
                let len = Int(data[offset] >> 1)
                let length = len == 0x7F ? 0 : len + 1
                guard data.count >= offset + 3 + length else {
                    // Skip this TLV as invalid
                    offset += 3 + length
                    continue
                }
                let propertyId: UInt16 = data.read(fromOffset: offset + 1)
                let property = DeviceProperty(propertyId)
                guard property.valueLength == nil || property.valueLength == length || length == 0 else {
                    // Skip this TLV as invalid
                    offset += 3 + length
                    continue
                }
                let value = property.read(from: data, at: offset + 3, length: length)
                result.append((property, value))
                offset += 3 + length
            }
        }
        return result
    }
    
}
