/*
* Copyright (c) 2025, Nordic Semiconductor
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

/// The Firmware Distribution Receivers Status message is an unacknowledged message sent by
/// a Firmware Distribution Server to report the size of the Distribution Receivers List state.
///
///A Firmware Distribution Receivers Status message is sent as a response to
///a ``FirmwareDistributionReceiversAdd`` message or
///a ``FirmwareDistributionReceiversDeleteAll`` message.
public struct FirmwareDistributionReceiversStatus: StaticMeshResponse {
    public static let opCode: UInt32 = 0x8313
    
    /// Status for the requesting message.
    public let status: FirmwareDistributionMessageStatus
    /// The number of entries in the Distribution Receivers List state.
    public let totalCount: UInt16
    
    public var parameters: Data? {
        return Data([status.rawValue]) + totalCount
    }
    
    /// Creates the Firmware Distribution Receivers Status message.
    ///
    /// - parameters:
    ///  - status: Status for the requesting message.
    ///  - totalCount: The number of entries in the Distribution Receivers List state.
    public init(status: FirmwareDistributionMessageStatus, totalCount: UInt16) {
        self.status = status
        self.totalCount = totalCount
    }
    
    public init?(parameters: Data) {
        guard parameters.count != 3 else {
            return nil
        }
        guard let status = FirmwareDistributionMessageStatus(rawValue: parameters[0]) else {
            return nil
        }
        self.status = status
        self.totalCount = parameters.read(fromOffset: 1)
    }
}
