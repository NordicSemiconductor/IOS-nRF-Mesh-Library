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

public enum BatteryPresence: UInt8 {
    case notPresent    = 0b00
    case removable     = 0b01
    case notRemovable  = 0b10
    case unknown       = 0b11
}

public enum BatteryIndicator: UInt8 {
    case criticallyLow = 0b00
    case low           = 0b01
    case good          = 0b10
    case unknown       = 0b11
}

public enum BatteryChargingState: UInt8 {
    case notChargeable = 0b00
    case notCharging   = 0b01
    case charging      = 0b10
    case unknown       = 0b11
}

public enum BatteryServiceability: UInt8 {
    case reserved           = 0b00
    case serviceNotRequired = 0b01
    case serviceRequired    = 0b10
    case unknown            = 0b11
}

public struct GenericBatteryStatus: StaticMeshResponse {
    public static let opCode: UInt32 = 0x8224
    
    public var parameters: Data? {
        let timeToDischargeBytes = (Data() + timeToDischarge).prefix(3)
        let timeToChargeBytes = (Data() + timeToCharge).prefix(3)
        return Data() + batteryLevel + timeToDischargeBytes + timeToChargeBytes + flags
    }
    
    /// Battery level state in percentage. Only values 0...100 and 0xFF are allowed.
    ///
    /// Value 0xFF means that the battery state is unknown.
    public let batteryLevel: UInt8
    /// Time to discharge, in minutes. Value 0xFFFFFF means unknown time.
    public let timeToDischarge: UInt32
    /// Time to charge, in minutes. Value 0xFFFFFF means unknown time.
    public let timeToCharge: UInt32
    /// Flags.
    public let flags: UInt8
    
    /// Whether the battery level is known.
    public var isBatteryLevelKnown: Bool {
        return batteryLevel != 0xFF
    }
    /// Whether the time to discharge is known.
    public var isTimeToDischargeKnown: Bool {
        return timeToDischarge != 0xFFFFFF
    }
    /// Whether the time to charge is known.
    public var isTimeToChargeKnown: Bool {
        return timeToCharge != 0xFFFFFF
    }
    /// Presence of the battery.
    public var batteryPresence: BatteryPresence {
        return BatteryPresence(rawValue: flags & 0x03)!
    }
    /// Charge level of the battery.
    public var batteryIndicator: BatteryIndicator {
        return BatteryIndicator(rawValue: (flags >> 2) & 0x03)!
    }
    /// Whether the battery is charging.
    public var batteryChargingState: BatteryChargingState {
        return BatteryChargingState(rawValue: (flags >> 4) & 0x03)!
    }
    /// The serviceability of the battery.
    public var batteryServiceability: BatteryServiceability {
        return BatteryServiceability(rawValue: (flags >> 6) & 0x03)!
    }
    
    public init(level batteryLevel: UInt8,
                timeToDischarge: UInt32, andCharge timeToCharge: UInt32,
                battery batteryPresence: BatteryPresence,
                state batteryIndicator: BatteryIndicator,
                charging batteryChargingState: BatteryChargingState,
                service batteryServiceability: BatteryServiceability) {
        self.batteryLevel = batteryLevel != 0xFF ? min(batteryLevel, 100) : 0xFF
        self.timeToDischarge = timeToDischarge != 0xFFFFFF ? min(timeToDischarge, 0xFFFFFE) : 0xFFFFFF
        self.timeToCharge = timeToCharge != 0xFFFFFF ? min(timeToCharge, 0xFFFFFE) : 0xFFFFFF
        self.flags = (batteryServiceability.rawValue << 6) |
                     (batteryChargingState.rawValue << 4) |
                     (batteryIndicator.rawValue << 2) |
                     (batteryPresence.rawValue)
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 8 else {
            return nil
        }
        batteryLevel = parameters[0]
        timeToDischarge = UInt32(parameters[1]) | (UInt32(parameters[2]) << 8) | (UInt32(parameters[3]) << 16)
        timeToCharge = UInt32(parameters[4]) | (UInt32(parameters[5]) << 8) | (UInt32(parameters[6]) << 16)
        flags = parameters[7]
    }
    
}
