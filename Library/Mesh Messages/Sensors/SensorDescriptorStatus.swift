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

public struct SensorDescriptorStatus: StaticMeshResponse {
    public static let opCode: UInt32 = 0x51
    
    /// The result returned in Sensor Descriptor Status message.
    public enum Result {
        /// List of sensor descriptors returned in the response.
        ///
        /// If Sensor Descriptor Get was sent with the ``SensorDescriptorGet/property``
        /// parameter set to `nil`, the result will contain a list of all sensor descriptors
        /// found on the target Element. Otherwise, in case the requested property
        /// was found, this list will contain only the requested descriptor.
        case descriptors([SensorDescriptor])
        /// The Propery was not found on the Element.
        ///
        /// This result is returned when a Sensor Descriptor Get was sent with
        /// a ``SensorDescriptorGet/property`` parameter that does not exist on the
        /// target Element.
        case propertyNotFound(DeviceProperty)
    }
    
    /// The result received.
    public let result: Result
    
    public var parameters: Data? {
        switch result {
        case let .propertyNotFound(property):
            return Data() + property.id
        case let .descriptors(descriptors):
            return descriptors.reduce(Data()) { $0 + $1.data }
        }
    }
    
    /// Creates a Sensor Descriptor Status message for a property that has not
    /// been found on the Element.
    ///
    /// - parameter property: The requested property that has not been found.
    public init(propertyNotFound property: DeviceProperty) {
        result = .propertyNotFound(property)
    }
    
    /// Creates a Sensor Descriptor Status message.
    ///
    /// The list shall contain one or more sensor descriptors.
    ///
    /// - parameter descriptors: List of sensor descriptors.
    public init(_ descriptors: [SensorDescriptor]) {
        result = .descriptors(descriptors)
    }
    
    public init?(parameters: Data) {
        switch parameters.count {
        case 2:
            let propertyId: UInt16 = parameters.read(fromOffset: 0)
            let property = DeviceProperty(propertyId)
            result = .propertyNotFound(property)
        case let count where count % 8 == 0:
            var descriptors: [SensorDescriptor] = []
            for offset in stride(from: 0, to: count, by: 8) {
                if let descriptor = SensorDescriptor(from: parameters, at: offset) {
                    descriptors.append(descriptor)
                }
            }
            result = .descriptors(descriptors)
        default:
            return nil
        }
    }
    
}
