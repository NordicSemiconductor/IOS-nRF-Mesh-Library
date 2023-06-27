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

public struct ConfigModelSubscriptionStatus: ConfigResponse, ConfigStatusMessage, ConfigAddressMessage, ConfigAnyModelMessage {
    public static let opCode: UInt32 = 0x801F
    
    public var parameters: Data? {
        let data = Data([status.rawValue]) + elementAddress + address
        if let companyIdentifier = companyIdentifier {
            return data + companyIdentifier + modelIdentifier
        } else {
            return data + modelIdentifier
        }
    }
    
    public let status: ConfigMessageStatus
    public let address: Address
    public let elementAddress: Address
    public let modelIdentifier: UInt16
    public let companyIdentifier: UInt16?
    
    public init<T: ConfigAddressMessage & ConfigAnyModelMessage>(responseTo request: T, with status: ConfigMessageStatus) {
        self.address = request.address
        self.elementAddress = request.elementAddress
        self.modelIdentifier = request.modelIdentifier
        self.companyIdentifier = request.companyIdentifier
        self.status = status
    }
    
    public init<T: ConfigVirtualLabelMessage & ConfigAnyModelMessage>(responseTo request: T, with status: ConfigMessageStatus) {
        self.address = MeshAddress(request.virtualLabel).address
        self.elementAddress = request.elementAddress
        self.modelIdentifier = request.modelIdentifier
        self.companyIdentifier = request.companyIdentifier
        self.status = status
    }
    
    public init(responseTo request: ConfigModelSubscriptionDeleteAll, with status: ConfigMessageStatus) {
        self.address = Address.unassignedAddress
        self.elementAddress = request.elementAddress
        self.modelIdentifier = request.modelIdentifier
        self.companyIdentifier = request.companyIdentifier
        self.status = status
    }
    
    public init?(confirmAdding group: Group, to model: Model) {
        guard let elementAddress = model.parentElement?.unicastAddress else {
            return nil
        }
        self.status = .success
        self.address = group.address.address
        self.elementAddress = elementAddress
        self.modelIdentifier = model.modelIdentifier
        self.companyIdentifier = model.companyIdentifier
    }
    
    public init?(confirmDeleting address: Address, from model: Model) {
        guard let elementAddress = model.parentElement?.unicastAddress else {
            return nil
        }
        self.status = .success
        self.address = address
        self.elementAddress = elementAddress
        self.modelIdentifier = model.modelIdentifier
        self.companyIdentifier = model.companyIdentifier
    }
    
    public init?(confirmDeletingAllFrom model: Model) {
        guard let elementAddress = model.parentElement?.unicastAddress else {
            return nil
        }
        self.status = .success
        self.address = Address.unassignedAddress
        self.elementAddress = elementAddress
        self.modelIdentifier = model.modelIdentifier
        self.companyIdentifier = model.companyIdentifier
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 7 || parameters.count == 9 else {
            return nil
        }
        guard let status = ConfigMessageStatus(rawValue: parameters[0]) else {
            return nil
        }
        self.status = status
        elementAddress = parameters.read(fromOffset: 1)
        address = parameters.read(fromOffset: 3)
        if parameters.count == 9 {
            companyIdentifier = parameters.read(fromOffset: 5)
            modelIdentifier = parameters.read(fromOffset: 7)
        } else {
            companyIdentifier = nil
            modelIdentifier = parameters.read(fromOffset: 5)
        }
    }
}
