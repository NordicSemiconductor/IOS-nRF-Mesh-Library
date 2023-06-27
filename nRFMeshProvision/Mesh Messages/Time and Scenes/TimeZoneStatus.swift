/*
* Copyright (c) 2022, Nordic Semiconductor
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

public struct TimeZoneStatus: StaticMeshResponse {
    public static let opCode: UInt32 = 0x823D
    
    public var parameters: Data? {
        var data =  Data(count: 7)

        data.writeBits(value: currentTzOffset.encodeToTzOffset(), numBits: 8, atOffset: 0)
        data.writeBits(value: nextTzOffset.encodeToTzOffset(), numBits: 8, atOffset: 8)
        data.writeBits(value: taiSeconds, numBits: 40, atOffset: 16)

        return data
    }
    
    /// The corrent local time zone offset.
    public let currentTzOffset: TimeZone
    /// The upcoming local time zone offset.
    public let nextTzOffset: TimeZone
    /// The TAI seconds time when the new offset should be applied.
    public let taiSeconds: UInt64

    /// Creates the Time Zone Status message.
    ///
    /// - parameters:
    ///   - currentTzOffset: the current offset.
    ///   - nextTzOffset: the new offset.
    ///   - taiSeconds: the time in TAI seconds when the new offset should be applied.
    public init(currentTzOffset: TimeZone, nextTzOffset: TimeZone, taiSeconds: UInt64) {
        self.currentTzOffset = currentTzOffset
        self.nextTzOffset = nextTzOffset
        self.taiSeconds = taiSeconds
    }

    public init?(parameters: Data) {
        guard parameters.count == 7 else {
            return nil
        }

        currentTzOffset = UInt8(parameters.readBits(8, fromOffset: 0)).decodeFromTzOffset()
        nextTzOffset = UInt8(parameters.readBits(8, fromOffset: 8)).decodeFromTzOffset()
        taiSeconds = parameters.readBits(40, fromOffset: 16)
    }
    
}
