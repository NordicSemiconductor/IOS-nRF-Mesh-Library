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

public struct SchedulerRegistryEntry {
    public let year: SchedulerYear
    public let month: SchedulerMonth
    public let day: SchedulerDay
    public let hour: SchedulerHour
    public let minute: SchedulerMinute
    public let second: SchedulerSecond
    public let dayOfWeek: SchedulerDayOfWeek
    public let action: SchedulerAction
    public let transitionTime: TransitionTime
    public let sceneNumber: UInt16
    
    public init() {
        year = SchedulerYear.any()
        month = SchedulerMonth.any(of: [])
        day = SchedulerDay.any()
        hour = SchedulerHour.any()
        minute = SchedulerMinute.any()
        second = SchedulerSecond.any()
        dayOfWeek = SchedulerDayOfWeek.any(of: [])
        action = SchedulerAction.NoAction
        transitionTime = TransitionTime.unknown
        sceneNumber = 0
    }
    
    public init(year: SchedulerYear, month: SchedulerMonth, day: SchedulerDay, hour: SchedulerHour, minute: SchedulerMinute, second: SchedulerSecond, dayOfWeek: SchedulerDayOfWeek, action: SchedulerAction, transitionTime: TransitionTime, sceneNumber: UInt16) {
        self.year = year
        self.month = month
        self.day = day
        self.hour = hour
        self.minute = minute
        self.second = second
        self.dayOfWeek = dayOfWeek
        self.action = action
        self.transitionTime = transitionTime
        self.sceneNumber = sceneNumber
    }
}

// MARK: Structures to represent scheduler entry properties.

public struct SchedulerYear {
    public let value: UInt8 // 7 bits

    public static func any() -> SchedulerYear {
        return SchedulerYear(value: 0x64)
    }
    public static func specific(year: Int) -> SchedulerYear {
        return SchedulerYear(value: UInt8(min(year, 99)))
    }
}

public enum Month: UInt16 {
    case January = 0x0001
    case February = 0x0002
    case March = 0x0004
    case April = 0x0008
    case May = 0x0010
    case June = 0x0020
    case July = 0x0040
    case August = 0x0080
    case September = 0x0100
    case October = 0x0200
    case November = 0x0400
    case December = 0x0800
}

public struct SchedulerMonth {
    public let value: UInt16 // 12 bits
    
    public static func any(of months: [Month]) -> SchedulerMonth {
        return SchedulerMonth(value: months.reduce(0, { (result, month) -> UInt16 in result + month.rawValue}))
    }
}

public struct SchedulerDay {
    public let value: UInt8 // 5 bits

    public static func any() -> SchedulerDay {
        return SchedulerDay(value: 0x00)
    }
    public static func specific(day: Int) -> SchedulerDay {
        return SchedulerDay(value: UInt8(min(day, 31)))
    }
}

public struct SchedulerHour {
    public let value: UInt8 // 5 bits

    public static func any() -> SchedulerHour {
        return SchedulerHour(value: 0x18)
    }

    public static func random() -> SchedulerHour {
        return SchedulerHour(value: 0x19)
    }

    public static func specific(hour: Int) -> SchedulerHour {
        return SchedulerHour(value: UInt8(min(hour, 23)))
    }
}

public struct SchedulerMinute {
    public let value: UInt8 // 6 bits

    public static func any() -> SchedulerMinute {
        return SchedulerMinute(value: 0x3C)
    }

    public static func every15() -> SchedulerMinute {
        return SchedulerMinute(value: 0x3D)
    }

    public static func every20() -> SchedulerMinute {
        return SchedulerMinute(value: 0x3E)
    }

    public static func random() -> SchedulerMinute {
        return SchedulerMinute(value: 0x3F)
    }

    public static func specific(minute: Int) -> SchedulerMinute {
        return SchedulerMinute(value: UInt8(min(minute, 59)))
    }
}

public struct SchedulerSecond {
    public let value: UInt8 // 6 bits

    public static func any() -> SchedulerSecond {
        return SchedulerSecond(value: 0x3C)
    }

    public static func every15() -> SchedulerSecond {
        return SchedulerSecond(value: 0x3D)
    }

    public static func every20() -> SchedulerSecond {
        return SchedulerSecond(value: 0x3E)
    }

    public static func random() -> SchedulerSecond {
        return SchedulerSecond(value: 0x3F)
    }

    public static func specific(second: Int) -> SchedulerSecond {
        return SchedulerSecond(value: UInt8(min(second, 59)))
    }
}

public enum WeekDay: UInt8 {
    case Monday = 0x01
    case Tuesday = 0x02
    case Wednesday = 0x04
    case Thursday = 0x08
    case Friday = 0x10
    case Saturday = 0x20
    case Sunday = 0x40
}

public struct SchedulerDayOfWeek {
    public let value: UInt8 // 7 bits
    
    public static func any(of days: [WeekDay]) -> SchedulerDayOfWeek {
        return SchedulerDayOfWeek(value: days.reduce(0, { (result, day) -> UInt8 in result + day.rawValue}))
    }
}

public enum SchedulerAction: UInt8 {
    case TurnOff = 0x00
    case TurnOn = 0x01
    case SceneRecall = 0x02
    case NoAction = 0x0F
}

// MARK: Marshalling

/// Entry is encoded with multiple bitfields to pack data as densely as possible.
/// Below are the fields in order, with the number of bits each one occupies.
/// Specification from section 5.1.4.2 in Mesh Model.
///
/// Index 4 (not part of the entry, but part of the message and included here for simplicity.
///
/// Year 7
/// Month 12
/// Day 5
/// Hour 5
/// Minute 6
/// Second 6
/// DayOfWeek 7
/// Action 4
/// Transition Time 8
/// Scene Number 16
extension SchedulerRegistryEntry {
    public static func unmarshal(_ parameters: Data) -> (index: UInt8, entry: SchedulerRegistryEntry) {
        let index = UInt8(parameters.readBits(4, fromOffset: 0))
        let year = UInt8(parameters.readBits(7, fromOffset: 4))
        let month = UInt16(parameters.readBits(12, fromOffset: 11))
        let day = UInt8(parameters.readBits(5, fromOffset: 23))
        let hour = UInt8(parameters.readBits(5, fromOffset: 28))
        let minute = UInt8(parameters.readBits(6, fromOffset: 33))
        let second = UInt8(parameters.readBits(6, fromOffset: 39))
        let dayOfWeek = UInt8(parameters.readBits(7, fromOffset: 45))
        let action = UInt8(parameters.readBits(4, fromOffset: 52))
        let transitionTime = TransitionTime(rawValue: parameters[7])
        let sceneNumber: UInt16 = parameters.read(fromOffset: 8)
        
        return (index, SchedulerRegistryEntry(year: SchedulerYear(value: year), month: SchedulerMonth(value: month), day: SchedulerDay(value: day), hour: SchedulerHour(value: hour), minute: SchedulerMinute(value: minute), second: SchedulerSecond(value: second), dayOfWeek: SchedulerDayOfWeek(value: dayOfWeek), action: SchedulerAction(rawValue: action)!, transitionTime: transitionTime, sceneNumber: sceneNumber))
    }
    
    public static func marshal(index: UInt8, entry: SchedulerRegistryEntry) -> Data {
        var data = Data(count: 10)
        
        data.writeBits(value: index, numBits: 4, atOffset: 0)
        data.writeBits(value: entry.year.value, numBits: 7, atOffset: 4)
        data.writeBits(value: entry.month.value, numBits: 12, atOffset: 11)
        data.writeBits(value: entry.day.value, numBits: 5, atOffset: 23)
        data.writeBits(value: entry.hour.value, numBits: 5, atOffset: 28)
        data.writeBits(value: entry.minute.value, numBits: 6, atOffset: 33)
        data.writeBits(value: entry.second.value, numBits: 6, atOffset: 39)
        data.writeBits(value: entry.dayOfWeek.value, numBits: 7, atOffset: 45)
        data.writeBits(value: entry.action.rawValue, numBits: 4, atOffset: 52)
        data.writeBits(value: entry.transitionTime.rawValue, numBits: 8, atOffset: 56)
        data.writeBits(value: entry.sceneNumber, numBits: 16, atOffset: 64)

        return data
    }
}
