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

public struct SensorSeriesStatus: StaticMeshResponse, SensorPropertyMessage {
    public static let opCode: UInt32 = 0x54
    
    public let property: DeviceProperty
    /// A sequence of Sensor Series Column states.
    ///
    /// Each serie consists of:
    ///  - Raw Value X,
    ///  - Column Width,
    ///  - Raw Value Y
    ///
    /// The series are returned as a single `Data` object, as their lenghts
    /// and types may differ depending on the sensor implementation.
    public let seriesRawData: Data?
    
    public var parameters: Data? {
        return Data() + property.id + seriesRawData
    }
    
    /// Creates the Sensor Series Status message.
    ///
    /// - parameters:
    ///   - property: Property identifying a sensor and the Y axis.
    ///   - seriesRawData: Series of Raw Value X, Column Width and Raw Value Y
    ///                    marshalled into a single `Data` object.
    ///                    Little Endian should be used for marshalling
    ///                    multi-octed values.
    public init(of property: DeviceProperty, seriesRawData: Data?) {
        self.property = property
        self.seriesRawData = seriesRawData
    }
    
    public init?(parameters: Data) {
        guard parameters.count >= 2 else {
            return nil
        }
        let propertyId: UInt16 = parameters.read(fromOffset: 0)
        self.property = DeviceProperty(propertyId)
        if parameters.count > 2 {
            self.seriesRawData = parameters.dropFirst(2)
        } else {
            self.seriesRawData = nil
        }
    }
    
}
