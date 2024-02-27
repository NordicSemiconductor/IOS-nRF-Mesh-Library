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

public struct SensorSettingsStatus: StaticMeshResponse, SensorPropertyMessage {
    public static let opCode: UInt32 = 0x58
    
    public let property: DeviceProperty
    /// If present, the Sensor Setting Properties field contains a sequence
    /// of all Sensor Setting Property states of a sensor.
    public let settingsProperties: [DeviceProperty]?
    
    public var parameters: Data? {
        return settingsProperties?
            .reduce(Data() + property.id) { $0 + $1.id } ??
            Data() + property.id
    }
    
    /// Creates the Sensor Settings Status message.
    ///
    /// - parameters:
    ///   - property: The Sensor Property field identifies a Sensor Property
    ///               state of a sensor.
    ///   - settingsProperties: If present, the Sensor Setting Properties
    ///                         contains a sequence of all Sensor Setting Property
    ///                         states of a sensor.
    public init(of property: DeviceProperty, settingsProperties: [DeviceProperty]?) {
        self.property = property
        self.settingsProperties = settingsProperties
    }
    
    public init?(parameters: Data) {
        guard parameters.count >= 2 && parameters.count % 2 == 0 else {
            return nil
        }
        let propertyId: UInt16 = parameters.read(fromOffset: 0)
        self.property = DeviceProperty(propertyId)
        if parameters.count == 2 {
            self.settingsProperties = nil
        } else {
            var settingsProperties: [DeviceProperty] = []
            for i in stride(from: 2, to: parameters.count, by: 2) {
                let propertyId: UInt16 = parameters.read(fromOffset: i)
                let property = DeviceProperty(propertyId)
                settingsProperties.append(property)
            }
            self.settingsProperties = settingsProperties
        }
    }
    
}
