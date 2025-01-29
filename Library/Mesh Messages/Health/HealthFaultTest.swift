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

/// A Health Fault Test is an acknowledged message used to invoke a self-test procedure of an Element.
///
/// The procedure is implementation specific and may result in changing the Health Fault state of an Element.
public struct HealthFaultTest: StaticAcknowledgedMeshMessage {
    public static let opCode: UInt32 = 0x8032
    public static let responseType: StaticMeshResponse.Type = HealthFaultStatus.self

    /// Identifier of a specific test to be performed.
    public let testId: UInt8
    
    /// 16-bit Bluetooth assigned Company Identifier.
    public let companyIdentifier: UInt16
    
    public var parameters: Data? {
        return Data([testId]) + companyIdentifier
    }
    
    /// Creates the Health Fault Test message.
    ///
    /// - parameters:
    ///   - testId: Identifier of a specific test to be performed.
    ///   - companyIdentifier: 16-bit Bluetooth assigned Company Identifier.
    ///             It shall be used to resolve specific fault codes as specified in Bluetooth assigned
    ///             Health Fault values.
    public init(testId: UInt8, for companyIdentifier: UInt16) {
        self.testId = testId
        self.companyIdentifier = companyIdentifier
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 3 else {
            return nil
        }
        testId = parameters[0]
        companyIdentifier = parameters.read(fromOffset: 1)
    }
    
}
