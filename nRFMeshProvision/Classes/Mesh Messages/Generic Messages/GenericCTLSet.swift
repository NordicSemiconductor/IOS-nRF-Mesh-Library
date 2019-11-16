/*
 * Copyright (c) 2019, Nordic Semiconductor
 * All rights reserved.
 
 * Created by codepgq
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

internal func resultTemperature(_ cct: UInt16) -> UInt16 {
    var c = cct > 100 ? 100 : cct
    c = UInt16((Float(c) / 100) * (20000-800)) + 800
    print("cct:", cct, "转换之后", c)
    return c
}

public struct GenericCTLSet: AcknowledgedGenericMessage, TransactionMessage, TransitionMessage {
    public static var opCode: UInt32 = 0x825e
    public static var responseType: StaticMeshMessage.Type = GenericCTLStatus.self
    
    public var tid: UInt8!
    
    public var parameters: Data? {
        let data = Data() + lightness + temperature + 1 + tid
        if let transitionTime = transitionTime, let delay = delay {
            return data + transitionTime.rawValue + delay
        } else {
            return data
        }
    }
    
    
    /// 0 - 65535
    public let lightness: UInt16
    // 0-100
    public let temperature: UInt16
    // uv default is 1
    public let uv: UInt16
    
    public var transitionTime: TransitionTime?
    public var delay: UInt8?
    
    public init(lightness: UInt16, temperature: UInt16, uv: UInt16 = 1) {
        self.lightness = lightness
        self.temperature = resultTemperature(temperature)
        self.uv = uv
        self.transitionTime = nil
        self.delay = nil
    }
    
    public init(lightness: UInt16, temperature: UInt16, uv: UInt16 = 1, transitionTime: TransitionTime, delay: UInt8) {
        self.lightness = lightness
        self.temperature = resultTemperature(temperature)
        self.uv = uv
        self.transitionTime = transitionTime
        self.delay = delay
    }
    
    
    public init?(parameters: Data) {
        guard parameters.count == 7 || parameters.count == 9 else { return nil }
        lightness = UInt16(parameters[0]) | (UInt16(parameters[1]) << 8)
        temperature = UInt16(parameters[2]) | (UInt16(parameters[3]) << 8)
        uv = UInt16(parameters[4]) | (UInt16(parameters[5]) << 8)
        tid = parameters[6]
        if parameters.count == 9 {
            transitionTime = TransitionTime(rawValue: parameters[7])
            delay = parameters[8]
        } else {
            transitionTime = nil
            delay = nil
        }
    }
    
}
