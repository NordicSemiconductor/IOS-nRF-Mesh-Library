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

/// Scheduler Registry entry contains the time information,
/// the scheduler action and Scene Number.
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
    public let sceneNumber: SceneNumber
    
    public init() {
        year = SchedulerYear.any()
        month = SchedulerMonth.any(of: [])
        day = SchedulerDay.any()
        hour = SchedulerHour.any()
        minute = SchedulerMinute.any()
        second = SchedulerSecond.any()
        dayOfWeek = SchedulerDayOfWeek.any(of: [])
        action = SchedulerAction.noAction
        transitionTime = TransitionTime.unknown
        sceneNumber = 0
    }
    
    public init(year: SchedulerYear, month: SchedulerMonth, day: SchedulerDay,
                hour: SchedulerHour, minute: SchedulerMinute, second: SchedulerSecond,
                dayOfWeek: SchedulerDayOfWeek, action: SchedulerAction,
                transitionTime: TransitionTime, sceneNumber: SceneNumber) {
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

/// The scheduler year.
public struct SchedulerYear {
    /// The year in a century.
    ///
    /// This filed contains a 2-digit value in a century. E.g. a year 1985 is stored as 85.
    ///
    /// Value 100 indicates any year.
    public let value: UInt8 // 7 bits

    /// Creates a scheduler year object for any year.
    public static func any() -> SchedulerYear {
        return SchedulerYear(value: 0x64)
    }
    
    /// Creates a scheduler year object for a specific year.
    ///
    /// The year has to be in range 0-99.
    public static func specific(year: Int) -> SchedulerYear {
        return SchedulerYear(value: UInt8(min(year, 99)))
    }
}

/// Bit field representation of a month for Scheduler purposes.
public enum Month: UInt16 {
    case January   = 0x0001
    case February  = 0x0002
    case March     = 0x0004
    case April     = 0x0008
    case May       = 0x0010
    case June      = 0x0020
    case July      = 0x0040
    case August    = 0x0080
    case September = 0x0100
    case October   = 0x0200
    case November  = 0x0400
    case December  = 0x0800
}

/// The scheduler month bit field.
public struct SchedulerMonth {
    /// A bit field representing scheduler months.
    public let value: UInt16 // 12 bits
    
    /// Creates a scheduler month struct from a list of months.
    public static func any(of months: [Month]) -> SchedulerMonth {
        return SchedulerMonth(value: months.reduce(0, { (result, month) -> UInt16 in result + month.rawValue}))
    }
}

/// The scheduler day.
public struct SchedulerDay {
    /// The 5-bit field representing a day number.
    public let value: UInt8 // 5 bits

    /// Creates a scheduler day object for any day.
    public static func any() -> SchedulerDay {
        return SchedulerDay(value: 0x00)
    }
    
    /// Create a scheduler day object for the specific day.
    public static func specific(day: Int) -> SchedulerDay {
        return SchedulerDay(value: UInt8(min(day, 31)))
    }
}

/// The scheduler hour.
public struct SchedulerHour {
    /// The 5-bit field representing a hour number.
    public let value: UInt8 // 5 bits

    /// Creates a scheduler hour object for any hour.
    public static func any() -> SchedulerHour {
        return SchedulerHour(value: 0x18)
    }

    /// Creates a scheduler hour object for a random hour.
    public static func random() -> SchedulerHour {
        return SchedulerHour(value: 0x19)
    }

    /// Creates a scheduler hour object for a specific hour.
    public static func specific(hour: Int) -> SchedulerHour {
        return SchedulerHour(value: UInt8(min(hour, 23)))
    }
}

/// The scheduler month.
public struct SchedulerMinute {
    /// The 6-bit field representing a minute number.
    public let value: UInt8 // 6 bits

    /// Creates a scheduler minute object for any minute.
    public static func any() -> SchedulerMinute {
        return SchedulerMinute(value: 0x3C)
    }

    /// Creates a scheduler minute object indicating every 15 minutes.
    public static func every15() -> SchedulerMinute {
        return SchedulerMinute(value: 0x3D)
    }

    /// Creates a scheduler minute object indicating every 20 minutes.
    public static func every20() -> SchedulerMinute {
        return SchedulerMinute(value: 0x3E)
    }

    /// Creates a scheduler minute object for a random minute.
    public static func random() -> SchedulerMinute {
        return SchedulerMinute(value: 0x3F)
    }

    /// Creates a scheduler minute object for a specific minute.
    public static func specific(minute: Int) -> SchedulerMinute {
        return SchedulerMinute(value: UInt8(min(minute, 59)))
    }
}

/// The scheduler second.
public struct SchedulerSecond {
    /// The 6-bit field representing a second number.
    public let value: UInt8 // 6 bits

    /// Creates a scheduler second object for any second.
    public static func any() -> SchedulerSecond {
        return SchedulerSecond(value: 0x3C)
    }

    /// Creates a scheduler second object indicating every 15 seconds.
    public static func every15() -> SchedulerSecond {
        return SchedulerSecond(value: 0x3D)
    }

    /// Creates a scheduler second object indicating every 20 seconds.
    public static func every20() -> SchedulerSecond {
        return SchedulerSecond(value: 0x3E)
    }

    /// Creates a scheduler second object for a random second.
    public static func random() -> SchedulerSecond {
        return SchedulerSecond(value: 0x3F)
    }

    /// Creates a scheduler second object for a specific second.
    public static func specific(second: Int) -> SchedulerSecond {
        return SchedulerSecond(value: UInt8(min(second, 59)))
    }
}

/// A bit field representation of a week day for Scheduler purposes.
public enum WeekDay: UInt8 {
    case Monday    = 0x01
    case Tuesday   = 0x02
    case Wednesday = 0x04
    case Thursday  = 0x08
    case Friday    = 0x10
    case Saturday  = 0x20
    case Sunday    = 0x40
}

/// The scheduler day of week.
public struct SchedulerDayOfWeek {
    /// A 7-bit long bit field representation of week days.
    public let value: UInt8 // 7 bits
    
    /// Creates a scheduler day of week struct from a list of week days.
    public static func any(of days: [WeekDay]) -> SchedulerDayOfWeek {
        return SchedulerDayOfWeek(value: days.reduce(0, { (result, day) -> UInt8 in result + day.rawValue}))
    }
}

/// The scheduler action enumeration as defined in Mesh Model specification..
public enum SchedulerAction: UInt8 {
    case turnOff     = 0x00
    case turnOn      = 0x01
    case sceneRecall = 0x02
    case noAction    = 0x0F
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
    
    /// Unmarshals the Entry from 10-byte long data.
    ///
    /// - parameter parameters: The raw data. Has to be at least 10-bytes long.
    /// - returns: A tupple of an index and scheduler registry entry.
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
        let sceneNumber: SceneNumber = parameters.read(fromOffset: 8)
        
        return (index, SchedulerRegistryEntry(
            year: SchedulerYear(value: year), month: SchedulerMonth(value: month),
            day: SchedulerDay(value: day), hour: SchedulerHour(value: hour),
            minute: SchedulerMinute(value: minute),
            second: SchedulerSecond(value: second),
            dayOfWeek: SchedulerDayOfWeek(value: dayOfWeek),
            action: SchedulerAction(rawValue: action)!,
            transitionTime: transitionTime, sceneNumber: sceneNumber))
    }
    
    /// Marshals the scheduler registry entry into raw bytes of size 10.
    /// 
    /// - parameters:
    ///   - index: An index.
    ///   - entry: The registry entry.
    /// - returns: Data of size 10 bytes.
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
