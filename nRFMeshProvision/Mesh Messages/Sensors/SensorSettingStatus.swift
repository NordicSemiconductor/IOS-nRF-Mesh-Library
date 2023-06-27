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

public struct SensorSettingStatus: StaticMeshResponse, SensorPropertyMessage {
    public static let opCode: UInt32 = 0x5B
    
    /// The Sensor Setting Access field is an enumeration indicating whether
    /// the device property can be read or written.
    public enum SensorSettingAccess: UInt8 {
        /// The device property can be read.
        case readonly  = 0x01
        /// The device property can be read and written.
        case readwrite = 0x03
    }
    
    public let property: DeviceProperty
    /// Setting Property identifying a setting within a sensor.
    public let settingProperty: DeviceProperty
    /// Read / Write access rights for the setting.
    ///
    /// This property is `nil` when requested setting property was not found.
    public let settingAccess: SensorSettingAccess?
    /// The value of the setting.
    ///
    /// This property is `nil` when requested setting property was not found,
    /// or the setting is read-only and was tried to be set.
    public let settingValue: DevicePropertyCharacteristic?
    
    public var parameters: Data? {
        let data = Data() + property.id + settingProperty.id
        if let access = settingAccess,
           let setting = settingValue {
            return data + access.rawValue + setting.data
        } else {
            return data
        }
    }
    
    /// Creates the Sensor Setting Status message for a setting that does not
    /// exist.
    ///
    /// - parameters:
    ///   - setting:  Setting Property identifying a setting within a sensor.
    ///   - property: Property identifying a sensor.
    public init(settingNotFound setting: DeviceProperty, for property: DeviceProperty) {
        self.property = property
        self.settingProperty = setting
        self.settingAccess = nil
        self.settingValue = nil
    }
    
    /// Creates the Sensor Setting Status message.
    ///
    /// - parameters:
    ///   - setting:  Setting Property identifying a setting within a sensor.
    ///   - property: Property identifying a sensor.
    ///   - access:   Read / Write access rights for the setting.
    ///   - value:    The value of the setting.
    public init(_ setting: DeviceProperty, of property: DeviceProperty,
                access: SensorSettingAccess, value: DevicePropertyCharacteristic) {
        self.property = property
        self.settingProperty = setting
        self.settingAccess = access
        self.settingValue = value
    }
    
    public init?(parameters: Data) {
        guard parameters.count >= 4 else {
            return nil
        }
        let propertyId: UInt16 = parameters.read(fromOffset: 0)
        self.property = DeviceProperty(propertyId)
        
        let settingPropertyId: UInt16 = parameters.read(fromOffset: 2)
        self.settingProperty = DeviceProperty(settingPropertyId)
        
        // Sensor Setting Access and Setting Raw are optional.
        if parameters.count == 4 {
            self.settingAccess = nil
            self.settingValue = nil
            return
        }
        let accessId: UInt8 = parameters[4]
        guard let access = SensorSettingAccess(rawValue: accessId) else {
            return nil
        }
        self.settingAccess = access
        
        // If Sensor Setting Set message was sent, and the sensor value is read-only,
        // the Status should have the Access state field set to `SensorSettingAccess.readonly`
        // and the value field shall be omitted.
        if parameters.count == 5 {
            self.settingValue = nil
            return
        }
        self.settingValue = settingProperty.read(from: parameters, at: 5, length: parameters.count - 5)
    }
    
}
