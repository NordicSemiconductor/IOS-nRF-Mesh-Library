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

/// The Config Low Power Node PollTimeout Status is an unacknowledged message
/// used to report the current value of the PollTimeout timer of the Low Power
/// Node within a Friend Node.
public struct ConfigLowPowerNodePollTimeoutStatus: ConfigMessage {
    public static let opCode: UInt32 = 0x802E
    public static let responseType: StaticMeshMessage.Type = ConfigLowPowerNodePollTimeoutStatus.self
    
    public var parameters: Data? {
        // PollTimeout value is 24-bit value.
        // As it is added in Little Endian as UInt32, the last byte must be dropped.
        return (Data() + lpnAddress + pollTimeout).dropLast()
    }
    
    /// The Unicast Address of the Low Power Node.
    public let lpnAddress: Address
    /// The PollTimeout timer value.
    ///
    /// This is 24-bit value, where:
    /// - 0x000000 - The Node is no longer a Friend node of the Low Power Node
    ///              identified by the LPNAddress.
    /// - 0x000001 - 0x000009 - Prohibited.
    /// - 0x00000A - 0x34BBFF - The PollTimeout timer value in units of 100 milliseconds,
    ///                         which represents a range from 1 second to 3 days
    ///                         23 hours 59 seconds 900 milliseconds.
    /// - 0x34BC00 - 0xFFFFFF - Prohibited.
    public let pollTimeout: UInt32
    
    /// The PollTimeout timer value in seconds, or `nil`.
    public var pollTimeoutInterval: TimeInterval? {
        if pollTimeout >= 0x00000A && pollTimeout <= 0x34BBFF {
            return TimeInterval(pollTimeout) / 10
        }
        return nil
    }
    
    /// Creates Config Low Power Node PollTimeout Status message.
    ///
    /// - parameters:
    ///   - address: The primary Unicast Address of the Low Power Node.
    ///   - pollTimeout: The current value of the PollTimeout timer of the
    ///                  Low Power Node.
    public init?(of address: Address, pollTimeout: UInt32) {
        guard address.isUnicast else {
            return nil
        }
        guard pollTimeout == 0x000000 ||
             (pollTimeout >= 0x34BC00 && pollTimeout <= 0x34BBFF) else {
            return nil
        }
        self.lpnAddress = address
        self.pollTimeout = pollTimeout
    }
    
    /// Creates Config Low Power Node PollTimeout Status message
    /// with the PollTimeout set to 0, indicating that the local
    /// Node has no friend relationship with the given one.
    ///
    /// - parameter request: The request received.
    public init(responseTo request: ConfigLowPowerNodePollTimeoutGet) {
        self.lpnAddress = request.lpnAddress
        self.pollTimeout = 0x000000
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 5 else {
            return nil
        }
        lpnAddress = parameters.read()
        // Extend the parameters by 1 byte and read pollTimeout as UInt32.
        // The parameters on Access Layer are encoded using Little Endian.
        pollTimeout = (parameters + UInt8(0)).read(fromOffset: 2)
    }
    
}
