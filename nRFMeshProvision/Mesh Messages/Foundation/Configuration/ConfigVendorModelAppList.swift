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

public struct ConfigVendorModelAppList: ConfigResponse, ConfigStatusMessage, ConfigModelAppList, ConfigVendorModelMessage {
    public static let opCode: UInt32 = 0x804E
    
    public var parameters: Data? {
        let data = Data([status.rawValue]) + elementAddress + companyIdentifier + modelIdentifier
        return data + encode(indexes: applicationKeyIndexes[...])
    }
    
    public let status: ConfigMessageStatus
    public let elementAddress: Address
    public let modelIdentifier: UInt16
    public let companyIdentifier: UInt16
    public let applicationKeyIndexes: [KeyIndex]
    
    public init(responseTo request: ConfigVendorModelAppGet, with applicationKeys: [ApplicationKey]) {
        self.elementAddress = request.elementAddress
        self.modelIdentifier = request.modelIdentifier
        self.companyIdentifier = request.companyIdentifier
        self.applicationKeyIndexes = applicationKeys.map { return $0.index }
        self.status = .success
    }
    
    public init(responseTo request: ConfigVendorModelAppGet, with status: ConfigMessageStatus) {
        self.elementAddress = request.elementAddress
        self.modelIdentifier = request.modelIdentifier
        self.companyIdentifier = request.companyIdentifier
        self.applicationKeyIndexes = []
        self.status = status
    }
    
    public init?(parameters: Data) {
        guard parameters.count >= 7 else {
            return nil
        }
        guard let status = ConfigMessageStatus(rawValue: 0) else {
            return nil
        }
        self.status = status
        elementAddress = parameters.read(fromOffset: 1)
        companyIdentifier = parameters.read(fromOffset: 3)
        modelIdentifier = parameters.read(fromOffset: 5)
        applicationKeyIndexes = ConfigSIGModelAppList.decode(indexesFrom: parameters, at: 7)
    }
}
