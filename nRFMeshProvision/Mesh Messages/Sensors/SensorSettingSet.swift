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

public struct SensorSettingSet: StaticAcknowledgedMeshMessage, SensorPropertyMessage {
    public static let opCode: UInt32 = 0x59
    public static let responseType: StaticMeshResponse.Type = SensorSettingStatus.self
    
    public let property: DeviceProperty
    /// Setting Property identifying a setting within a sensor.
    public let settingProperty: DeviceProperty
    /// The value of the setting.
    public let settingValue: DevicePropertyCharacteristic
    
    public var parameters: Data? {
        return Data() + property.id + settingProperty.id + settingValue.data
    }
    
    /// Creates the Sensor Setting Set message.
    ///
    /// - parameters:
    ///   - setting:  Setting Property identifying a setting within a sensor.
    ///   - property: Property identifying a sensor.
    ///   - value:    The value of the setting.
    public init(_ setting: DeviceProperty, of property: DeviceProperty,
                to value: DevicePropertyCharacteristic) {
        self.property = property
        self.settingProperty = setting
        self.settingValue = value
    }
    
    public init?(parameters: Data) {
        guard parameters.count >= 5 else {
            return nil
        }
        let propertyId: UInt16 = parameters.read(fromOffset: 0)
        self.property = DeviceProperty(propertyId)
        
        let settingPropertyId: UInt16 = parameters.read(fromOffset: 2)
        self.settingProperty = DeviceProperty(settingPropertyId)
        
        // For known properties, make sure we have enough of data to parse value from.
        if let expectedValueLength = settingProperty.valueLength {
            guard expectedValueLength == parameters.count - 4 else {
                return nil
            }
        }
        self.settingValue = settingProperty.read(from: parameters, at: 4, length: parameters.count - 4)
    }
    
}
