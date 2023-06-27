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

public struct SensorGet: StaticAcknowledgedMeshMessage {
    public static let opCode: UInt32 = 0x8231
    public static let responseType: StaticMeshResponse.Type = SensorStatus.self
    
    /// The sensor property to get the value of.
    ///
    /// If set to `nil`, all sensor values found on the Element will be returned.
    public let property: DeviceProperty?
    
    public var parameters: Data? {
        if let property = property {
            return Data() + property.id
        }
        return nil
    }
    
    /// Creates the Sensor Get message.
    ///
    /// - parameter property: An optional property parameter to request only the
    ///                       value of the given property.
    public init(_ property: DeviceProperty? = nil) {
        self.property = property
    }
    
    public init?(parameters: Data) {
        switch parameters.count {
        case 0:
            self.property = nil
        case 2:
            let propertyId: UInt16 = parameters.read(fromOffset: 0)
            self.property = DeviceProperty(propertyId)
        default:
            return nil
        }
    }
    
}
