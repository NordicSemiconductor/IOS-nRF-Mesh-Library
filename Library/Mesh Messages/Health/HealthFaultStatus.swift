/*
* Copyright (c) 2024, Nordic Semiconductor
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
*
* Created by Jules DOMMARTIN on 04/11/2024.
*/

import Foundation


public struct HealthFaultStatus: StaticMeshResponse {
    public static var opCode: UInt32 = 0x0005
    
    public var parameters: Data? {
        return Data() + testId
    }
    
    /// Test id
    public let testId: UInt8

    /// Company id
    public let companyIdentifier: UInt16
    
    /// List of faults
    /// If no Fault fields are present (nil), it means no registered fault condition exists on an element.
    public let faultArray: [HealthFault]?
    
    public init(testId: UInt8, companyIdentifier: UInt16) {
        self.testId = testId
        self.companyIdentifier = companyIdentifier
        self.faultArray = nil
    }
    
    public init(testId: UInt8, companyIdentifier: UInt16, faultArray: [HealthFault]) {
        self.testId = testId
        self.companyIdentifier = companyIdentifier
        self.faultArray = faultArray
    }
    
    public init?(parameters: Data) {
        guard parameters.count >= 3 else {
            return nil
        }
        testId = parameters.read(fromOffset: 0)
        companyIdentifier = parameters.read(fromOffset: 1)
        if parameters.count > 3 {
            faultArray = parameters
                .subdata(in: 3 ..< parameters.count - 3)
                .bytes
                .compactMap { HealthFault(rawValue: $0) }
        } else {
            faultArray = nil
        }
    }
}
