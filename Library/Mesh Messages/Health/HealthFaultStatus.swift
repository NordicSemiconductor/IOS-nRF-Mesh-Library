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

/// A Health Fault Status is an unacknowledged message used to report the current Registered Fault
/// state of an Element.
///
/// The message may contain several Fault fields, depending on the number of concurrently present
/// fault conditions. If no Fault fields are present, it means no registered fault condition exists on an Element.
public struct HealthFaultStatus: StaticMeshResponse {
    public static var opCode: UInt32 = 0x0005
    
    public var parameters: Data? {
        var data = Data([testId]) + companyIdentifier
        if !faults.isEmpty {
            data += Data(faults.map { $0.id })
        }
        return data
    }

    /// Identifier of a most recently performed test.
    public let testId: UInt8
    /// 16-bit Bluetooth assigned Company Identifier.
    public let companyIdentifier: UInt16
    /// List of faults.
    ///
    /// If no Fault fields are present, it means no registered fault condition exists on an Element.
    public let faults: [HealthFault]
    
    /// Creates a Health Fault Status message.
    ///
    /// - parameters:
    ///   - testId: Identifier of a most recently performed test.
    ///   - companyIdentifier: 16-bit Bluetooth assigned Company Identifier.
    ///   - faults: List of faults.
    public init(testId: UInt8, companyIdentifier: UInt16, faults: [HealthFault] = []) {
        self.testId = testId
        self.companyIdentifier = companyIdentifier
        self.faults = faults
    }
    
    public init?(parameters: Data) {
        guard parameters.count >= 3 else {
            return nil
        }
        testId = parameters[0]
        companyIdentifier = parameters.read(fromOffset: 1)
        if parameters.count > 3 {
            faults = parameters
                .subdata(in: 3..<parameters.count)
                .compactMap { HealthFault.fromId($0) }
        } else {
            faults = []
        }
    }
}
