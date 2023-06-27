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
import CoreBluetooth

public struct ConfigModelPublicationVirtualAddressSet: AcknowledgedConfigMessage, ConfigAnyModelMessage {
    public static let opCode: UInt32 = 0x801A
    public static let responseType: StaticMeshResponse.Type = ConfigModelPublicationStatus.self
    
    public var parameters: Data? {
        var data = Data() + elementAddress + publish.publicationAddress.virtualLabel!.data
        data += UInt8(publish.index & 0xFF)
        data += UInt8(publish.index >> 8) | UInt8(publish.credentials << 4)
        data += publish.ttl
        data += (publish.period.numberOfSteps & 0x3F) | (publish.period.resolution.rawValue << 6)
        data += (publish.retransmit.count & 0x07) | (publish.retransmit.steps << 3)
        if let companyIdentifier = companyIdentifier {
            return data + companyIdentifier + modelIdentifier
        } else {
            return data + modelIdentifier
        }
    }
    
    public let elementAddress: Address
    public let modelIdentifier: UInt16
    public let companyIdentifier: UInt16?
    /// Publication data.
    public let publish: Publish
    
    public init?(_ publish: Publish, to model: Model) {
        guard publish.publicationAddress.address.isVirtual else {
            // ConfigModelPublicationSet should be used instead.
            return nil
        }
        guard let elementAddress = model.parentElement?.unicastAddress else {
            return nil
        }
        self.publish = publish
        self.elementAddress = elementAddress
        self.modelIdentifier = model.modelIdentifier
        self.companyIdentifier = model.companyIdentifier
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 25 || parameters.count == 27 else {
            return nil
        }
        self.elementAddress = parameters.read(fromOffset: 0)
        
        let label = CBUUID(data: parameters.dropFirst(2).prefix(16)).uuid
        let index: KeyIndex = parameters.read(fromOffset: 18) & 0x0FFF
        let flag = Int((parameters[19] & 0x10) >> 4)
        let ttl = parameters[20]
        let periodSteps = parameters[21] & 0x3F
        let periodResolution = StepResolution(rawValue: parameters[21] >> 6)!
        let period = Publish.Period(steps: periodSteps, resolution: periodResolution)
        let count = parameters[22] & 0x07
        let interval = parameters[22] >> 3
        let retransmit = Publish.Retransmit(publishRetransmitCount: count, intervalSteps: interval)
        
        self.publish = Publish(to: label.hex, withKeyIndex: index,
                               friendshipCredentialsFlag: flag, ttl: ttl,
                               period: period,
                               retransmit: retransmit)
        if parameters.count == 27 {
            self.companyIdentifier = parameters.read(fromOffset: 23)
            self.modelIdentifier = parameters.read(fromOffset: 25)
        } else {
            self.companyIdentifier = nil
            self.modelIdentifier = parameters.read(fromOffset: 23)
        }
    }
}

