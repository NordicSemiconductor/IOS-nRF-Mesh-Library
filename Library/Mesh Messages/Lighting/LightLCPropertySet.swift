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

/// The Light LC Property Set is an acknowledged message used to set the
/// Light LC Property state of an Element.
///
/// The property can be one of:
/// * ``DeviceProperty/lightControlAmbientLuxLevelOn``
/// * ``DeviceProperty/lightControlAmbientLuxLevelProlong``
/// * ``DeviceProperty/lightControlAmbientLuxLevelStandby``
/// * ``DeviceProperty/lightControlLightnessOn``
/// * ``DeviceProperty/lightControlLightnessProlong``
/// * ``DeviceProperty/lightControlLightnessStandby``
/// * ``DeviceProperty/lightControlRegulatorAccuracy``
/// * ``DeviceProperty/lightControlRegulatorKid``
/// * ``DeviceProperty/lightControlRegulatorKiu``
/// * ``DeviceProperty/lightControlRegulatorKpd``
/// * ``DeviceProperty/lightControlRegulatorKpu``
/// * ``DeviceProperty/lightControlTimeFade``
/// * ``DeviceProperty/lightControlTimeFadeOn``
/// * ``DeviceProperty/lightControlTimeFadeStandbyAuto``
/// * ``DeviceProperty/lightControlTimeFadeStandbyManual``
/// * ``DeviceProperty/lightControlTimeOccupancyDelay``
/// * ``DeviceProperty/lightControlTimeProlong``
/// * ``DeviceProperty/lightControlTimeRunOn``
///
/// The response to the Light LC Property Set message is a ``LightLCPropertyStatus``
/// message.
public struct LightLCPropertySet: StaticAcknowledgedMeshMessage, SensorPropertyMessage {
    public static let opCode: UInt32 = 0x62
    public static let responseType: StaticMeshResponse.Type = LightLCPropertyStatus.self
    
    public let property: DeviceProperty
    /// Value of the Light LC Property.
    public let propertyValue: DevicePropertyCharacteristic
    
    public var parameters: Data? {
        return Data() + property.id + propertyValue.data
    }
    
    /// Creates a Light LC Property Set message.
    ///
    /// The property can be one of:
    /// * ``DeviceProperty/lightControlAmbientLuxLevelOn``
    /// * ``DeviceProperty/lightControlAmbientLuxLevelProlong``
    /// * ``DeviceProperty/lightControlAmbientLuxLevelStandby``
    /// * ``DeviceProperty/lightControlLightnessOn``
    /// * ``DeviceProperty/lightControlLightnessProlong``
    /// * ``DeviceProperty/lightControlLightnessStandby``
    /// * ``DeviceProperty/lightControlRegulatorAccuracy``
    /// * ``DeviceProperty/lightControlRegulatorKid``
    /// * ``DeviceProperty/lightControlRegulatorKiu``
    /// * ``DeviceProperty/lightControlRegulatorKpd``
    /// * ``DeviceProperty/lightControlRegulatorKpu``
    /// * ``DeviceProperty/lightControlTimeFade``
    /// * ``DeviceProperty/lightControlTimeFadeOn``
    /// * ``DeviceProperty/lightControlTimeFadeStandbyAuto``
    /// * ``DeviceProperty/lightControlTimeFadeStandbyManual``
    /// * ``DeviceProperty/lightControlTimeOccupancyDelay``
    /// * ``DeviceProperty/lightControlTimeProlong``
    /// * ``DeviceProperty/lightControlTimeRunOn``
    ///
    /// - parameters:
    ///   - property: The Light LC Property.
    ///   - value: The new value of the property.
    public init(of property: DeviceProperty, value: DevicePropertyCharacteristic) {
        self.property = property
        self.propertyValue = value
    }
    
    public init?(parameters: Data) {
        guard parameters.count >= 2 else {
            return nil
        }
        let propertyId: UInt16 = parameters.read(fromOffset: 0)
        self.property = DeviceProperty(propertyId)
        self.propertyValue = property.read(from: parameters, at: 2, length: parameters.count - 2)
    }
    
}
