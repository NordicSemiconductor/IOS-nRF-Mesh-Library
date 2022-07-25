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
    public let tzOffset: Double
    
    public init() {
        self.seconds = 0
        self.subSecond = 0
        self.uncertainty = 0
        self.authority = false
        self.taiDelta = 0
        self.tzOffset = 0
    }
    
    public init(seconds: UInt64, subSecond: UInt8, uncertainty: UInt8, authority: Bool, taiDelta: Int16, tzOffset: Double) {
        self.seconds = seconds
        self.subSecond = subSecond
        self.uncertainty = uncertainty
        self.authority = authority
        self.taiDelta = taiDelta
        self.tzOffset = tzOffset
    }
}

// MARK: - Extensions for encoding and decoding parameters in time messages.
extension UInt64 {
    public func getByte(at offset: Int) -> UInt8 {
        return UInt8(self >> (8 * offset) & 0xFF)
    }
}

extension Double {
    public func encodeToTzOffset() -> UInt8 {
        return UInt8(max(-127, min(128, Int(self * 4) + Int(TZ_START_RANGE))))
    }
}

extension UInt8 {
    public func decodeFromTzOffset() -> Double {
        return Double(Int(self) - Int(TZ_START_RANGE)) / 4;
    }
}

// MARK: - Constants for encoding and decoding parameters in time messages.
let TZ_START_RANGE: UInt8 = 0x40
let TAI_DELTA_START_RANGE: Int16 = 0xFF

// MARK: - Extensions for encoding and decoding TAI time objects.
extension TaiTime {
    public static func unmarshal(_ parameters: Data) -> TaiTime {
        let seconds = parameters.read(numBytes: 5)
        let subSecond: UInt8 = parameters.read(fromOffset: 5)
        let uncertainty: UInt8 = parameters.read(fromOffset: 6)
        let authorityAndTaiDelta: UInt16 = parameters.read(fromOffset: 7)
        let tzOffset: UInt8 = parameters.read(fromOffset: 9)

        let authority = (authorityAndTaiDelta & 0x0001) == 0x0001 ? true : false
        let taiDelta = Int16(authorityAndTaiDelta >> 1)

        return TaiTime(seconds: seconds, subSecond: subSecond, uncertainty: uncertainty, authority: authority, taiDelta: taiDelta - TAI_DELTA_START_RANGE, tzOffset: tzOffset.decodeFromTzOffset())
    }
    
    public static func marshal(_ time: TaiTime) -> Data {
        var data = Data()

        //  Protocol only supports 40 bits of time, strip the rest of the 64-bit value.
        data.append(contentsOf: [time.seconds.getByte(at: 0), time.seconds.getByte(at: 1), time.seconds.getByte(at: 2), time.seconds.getByte(at: 3), time.seconds.getByte(at: 4)])

        data.append(time.subSecond)
        data.append(time.uncertainty)

        // Time authority offset the bytes by one bit, so do some
        // twiddling until we're back in sync.
        let meshDelta = time.taiDelta + TAI_DELTA_START_RANGE
        let octet1: UInt8 = (time.authority ? 0x80 : 0x00) | UInt8(meshDelta & 0x7F)
        let octet2: UInt8 = UInt8((meshDelta >> 7) & 0xFF)

        data.append(contentsOf: [octet1, octet2])
        data.append(time.tzOffset.encodeToTzOffset())
        
        return data
    }
}
