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


public protocol TimeMessage: StaticMeshMessage {
    var time: TaiTime { get }
}

public struct TaiTime {
    /// The current TAI time in seconds.
    public let seconds: UInt64
    /// The sub-second time in units of 1/256th second.
    public let subSecond: UInt8
    /// The estimated uncertainty in 10-millisecond steps.
    public let uncertainty: UInt8
    /// Whether this time is authorative (from a "known good" source, such as GPS or NTP).
    public let authority: Bool
    /// Current difference between TAI and UTC in seconds (range -255 to 32512).
    public let taiDelta: Int16
    /// The Local time zone offset.
    public let tzOffset: TimeZone
    
    public init() {
        self.seconds = 0
        self.subSecond = 0
        self.uncertainty = 0
        self.authority = false
        self.taiDelta = 0
        self.tzOffset = TimeZone.current
    }
    
    public init(seconds: UInt64, subSecond: UInt8, uncertainty: UInt8, authority: Bool, taiDelta: Int16, tzOffset: TimeZone) {
        self.seconds = seconds
        self.subSecond = subSecond
        self.uncertainty = uncertainty
        self.authority = authority
        self.taiDelta = taiDelta
        self.tzOffset = tzOffset
    }
}

// MARK: - Constants for encoding and decoding parameters in time messages.
let TZ_SECONDS_PER_STEP = 3600 / 4
let TZ_START_RANGE: UInt8 = 0x40
let TAI_DELTA_START_RANGE: Int16 = 0xFF

// MARK: - Extensions for encoding and decoding parameters in time messages.
extension TimeZone {
    public func encodeToTzOffset() -> UInt8 {
        return UInt8(max(-127, min(128, (self.secondsFromGMT() / TZ_SECONDS_PER_STEP) + Int(TZ_START_RANGE))))
    }
}

extension UInt8 {
    public func decodeFromTzOffset() -> TimeZone {
        return TimeZone(secondsFromGMT: (Int(self) - Int(TZ_START_RANGE)) * TZ_SECONDS_PER_STEP)!
    }
}

// MARK: - Extensions for encoding and decoding TAI time objects.
extension TaiTime {
    public static func unmarshal(_ parameters: Data) -> TaiTime {
        let seconds = parameters.readBits(40, fromOffset: 0)
        let subSecond = UInt8(parameters.readBits(8, fromOffset: 40))
        let uncertainty = UInt8(parameters.readBits(8, fromOffset: 48))
        let authority = parameters.readBits(1, fromOffset: 56) == 1 ? true : false
        let taiDelta = Int16(parameters.readBits(15, fromOffset: 57))
        let tzOffset = UInt8(parameters.readBits(8, fromOffset: 72))

        return TaiTime(seconds: seconds, subSecond: subSecond, uncertainty: uncertainty, authority: authority, taiDelta: taiDelta - TAI_DELTA_START_RANGE, tzOffset: tzOffset.decodeFromTzOffset())
    }
    
    public static func marshal(_ time: TaiTime) -> Data {
        var data = Data(count: 10)

        data.writeBits(value: time.seconds, numBits: 40, atOffset: 0)
        data.writeBits(value: time.subSecond, numBits: 8, atOffset: 40)
        data.writeBits(value: time.uncertainty, numBits: 8, atOffset: 48)
        data.writeBits(value: UInt64(time.authority ? 1 : 0), numBits: 1, atOffset: 56)
        data.writeBits(value: UInt16(time.taiDelta + TAI_DELTA_START_RANGE), numBits: 15, atOffset: 57)
        data.writeBits(value: time.tzOffset.encodeToTzOffset(), numBits: 8, atOffset: 72)
        
        return data
    }
}
