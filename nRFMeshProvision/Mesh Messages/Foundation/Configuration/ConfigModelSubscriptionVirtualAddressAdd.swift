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

public struct ConfigModelSubscriptionVirtualAddressAdd: AcknowledgedConfigMessage, ConfigVirtualLabelMessage, ConfigAnyModelMessage {
    public static let opCode: UInt32 = 0x8020
    public static let responseType: StaticMeshResponse.Type = ConfigModelSubscriptionStatus.self
    
    public var parameters: Data? {
        let data = Data() + elementAddress + virtualLabel.data
        if let companyIdentifier = companyIdentifier {
            return data + companyIdentifier + modelIdentifier
        } else {
            return data + modelIdentifier
        }
    }
    
    public let virtualLabel: UUID
    public let elementAddress: Address
    public let modelIdentifier: UInt16
    public let companyIdentifier: UInt16?
    
    public init?(group: Group, to model: Model) {
        guard let label = group.address.virtualLabel else {
            // ConfigModelSubscriptionAdd should be used instead.
            return nil
        }
        guard let elementAddress = model.parentElement?.unicastAddress else {
            return nil
        }
        self.virtualLabel = label
        self.elementAddress = elementAddress
        self.modelIdentifier = model.modelIdentifier
        self.companyIdentifier = model.companyIdentifier
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 20 || parameters.count == 22 else {
            return nil
        }
        elementAddress = parameters.read(fromOffset: 0)
        virtualLabel = CBUUID(data: parameters.dropFirst(2).prefix(16)).uuid
        if parameters.count == 24 {
            companyIdentifier = parameters.read(fromOffset: 18)
            modelIdentifier = parameters.read(fromOffset: 20)
        } else {
            companyIdentifier = nil
            modelIdentifier = parameters.read(fromOffset: 18)
        }
    }
}

