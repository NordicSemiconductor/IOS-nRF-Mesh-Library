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

public struct GenericPowerRangeStatus: StaticMeshResponse, RangeStatusMessage {
    public static let opCode: UInt32 = 0x821E
    
    public var parameters: Data? {
        return Data([status.rawValue]) + range.lowerBound + range.upperBound
    }
    
    public let status: RangeMessageStatus
    /// The value of the Generic Power Range state.
    public let range: ClosedRange<UInt16>
    
    /// Creates the Generic Power Range Status message.
    ///
    /// - parameter range: The value of the Generic Power Range state.
    public init(report range: ClosedRange<UInt16>) {
        self.status = .success
        self.range = range
    }
    
    /// Creates the Generic Power Range Status message.
    ///
    /// - parameter status: Status Code for the requesting message.
    /// - parameter request: The request received.
    public init(_ status: RangeMessageStatus, for request: GenericPowerRangeSet) {
        self.status = status
        self.range = request.range
    }
    
    /// Creates the Generic Power Range Status message.
    ///
    /// - parameter status: Status Code for the requesting message.
    /// - parameter request: The request received.
    public init(_ status: RangeMessageStatus, for request: GenericPowerRangeSetUnacknowledged) {
        self.status = status
        self.range = request.range
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 5 else {
            return nil
        }
        guard let status = RangeMessageStatus(rawValue: parameters[0]) else {
            return nil
        }
        self.status = status
        range = parameters.read(fromOffset: 1)...parameters.read(fromOffset: 3)
    }
    
}

