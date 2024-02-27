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

/// A base protocol for sensor property messages.
public protocol SensorPropertyMessage: MeshMessage {
    /// Property for the sensor.
    var property: DeviceProperty { get }
}

/// The Sensor Descriptor state represents the attributes describing the
/// sensor data. This state does not change throughout the lifetime of an
/// Element.
public struct SensorDescriptor {
    /// The Sensor Property describes the meaning and the format of data
    /// reported by a sensor.
    public let property: DeviceProperty
    /// The Sensor Positive Tolerance field is a 12-bit value representing
    /// the magnitude of a possible positive error associated with the
    /// measurements that the sensor is reporting.
    ///
    /// The error can be calculated using the following formula:
    /// ```
    /// possible error [%] = 100[%] * tolerance / 4095
    /// ```
    ///
    /// A tolerance of 0 should be interpreted as “unspecified”.
    public let positiveTolerance: UInt16
    /// The Sensor Negative Tolerance field is a 12-bit value representing
    /// the magnitude of a possible negative error associated with the
    /// measurements that the sensor is reporting.
    ///
    /// The error can be calculated using the following formula:
    /// ```
    /// possible error [%] = 100[%] * tolerance / 4095
    /// ```
    ///
    /// A tolerance of 0 should be interpreted as “unspecified”.
    public let negativeTolerance: UInt16
    /// This Sensor Sampling Function field specifies the averaging
    /// operation or type of sampling function applied to the measured value.
    public let samplingFunction: SensorSamplingFunction
    /// This Sensor Measurement Period field specifies a UInt8 value n
    /// that represents the averaging time span, accumulation time, or
    /// measurement period in seconds over which the measurement is taken.
    ///
    /// The period is calculated using formula:
    /// ```
    /// represented value = 1.1^(n-64)
    /// ```
    /// For those cases where a value for the measurement period is not
    /// available or is not applicable, a special number has been assigned
    /// to indicate Not Applicable equal to 0.
    /// - seeAlso: ``SensorDescriptor/measurementPeriod``
    internal let measurementPeriodValue: UInt8
    /// The measurement reported by a sensor is internally refreshed at
    /// the frequency indicated in the Sensor Update Interval field
    /// (e.g., a temperature value that is internally updated every 15 minutes).
    ///
    /// This field specifies a UInt8 value n that determines the interval
    /// (in seconds) between updates, using the formula:
    /// ```
    /// represented value = 1.1^(n-64)
    /// ```
    /// For those cases where a value for the Sensor Update Interval is
    /// not available or is not applicable, a special number has been assigned
    /// to indicate Not Applicable equal to 0.
    /// - seeAlso: ``SensorDescriptor/updateInteval``
    internal let updateIntervalValue: UInt8
    
    /// Whether the positive tolerance is specified.
    public var isPositiveToleranceSpecified: Bool {
        return positiveTolerance > 0
    }
    /// Whether the negatove tolerance is specified.
    public var isNegativeToleranceSpecified: Bool {
        return negativeTolerance > 0
    }
    /// The measurement period in seconds, or `nil`, if measurement period is
    /// not available or is not applicable.
    ///
    /// For example, the measurement period can specify the length of the
    /// period used to obtain an average reading.
    public var measurementPeriod: TimeInterval? {
        if measurementPeriodValue == 0 {
            return nil
        }
        return pow(1.1, Double(measurementPeriodValue) - 64.0)
    }
    /// The update interval in seconds, or `nil`, if update interval is
    /// not available or is not applicable.
    public var updateInteval: TimeInterval? {
        if updateIntervalValue == 0 {
            return nil
        }
        return pow(1.1, Double(updateIntervalValue) - 64.0)
    }
    
    /// Descriptor as Data.
    internal var data: Data {
        // Encode two 12-bit tolerance values in 2 bytes.
        let tolerances: UInt32 = UInt32(negativeTolerance) << 12 | UInt32(positiveTolerance)
        
        var data = Data() + property.id
        data += (Data() + tolerances.littleEndian).dropLast()
        data += samplingFunction.rawValue
        data += measurementPeriodValue
        data += updateIntervalValue
        return data
    }
    
    /// Creates Sensor Descriptor object.
    ///
    /// - parameters:
    ///   - property: The device property that describes the meaning and
    ///               the format of data reported by a sensor.
    ///   - positiveTolerance: The magnitude of a possible positive error
    ///                        associated with the measurements that the
    ///                        sensor is reporting.
    ///                        A tolerance of 0 should be interpreted as
    ///                        “unspecified”.
    ///   - negativeTolerance: The magnitude of a possible negative error
    ///                        associated with the measurements that the
    ///                        sensor is reporting.
    ///                        A tolerance of 0 should be interpreted as
    ///                        “unspecified”.
    ///   - samplingFunction:  The averaging operation or type of sampling
    ///                        function applied to the measured value.
    ///   - measurementPeriod: The averaging time span, accumulation
    ///                        time, or measurement period in seconds over
    ///                        which the measurement is taken.
    ///                        Represented value is equal to `1.1^(n-64)`.
    ///                        Value 0 indicates that the period is not
    ///                        available or is not applicable.
    ///   - updateInterval:    The interval of internal refreshing.
    ///                        Represented value is equal to `1.1^(n-64)`.
    ///                        Value 0 indicates that the interval is not
    ///                        available or is not applicable.
    public init(_ property: DeviceProperty,
         positiveTolerance: UInt16,
         negativeTolerance: UInt16,
         samplingFunction: SensorSamplingFunction,
         measurementPeriod: UInt8,
         updateInterval: UInt8) {
        self.property = property
        self.positiveTolerance = positiveTolerance
        self.negativeTolerance = negativeTolerance
        self.samplingFunction = samplingFunction
        self.measurementPeriodValue = measurementPeriod
        self.updateIntervalValue = updateInterval
    }
    
    internal init?(from parameters: Data, at offset: Int) {
        guard parameters.count >= offset + 8 else {
            return nil
        }
        let propertyId: UInt16 = parameters.read(fromOffset: offset)
        self.property = DeviceProperty(propertyId)
        // Decode two 12-bit tolerace values from 2 bytes.
        self.positiveTolerance = UInt16(parameters[offset + 3] & 0x0F) << 8 | UInt16(parameters[offset + 2])
        self.negativeTolerance = UInt16(parameters[offset + 4]) << 4 | UInt16(parameters[offset + 3] >> 4)
        guard let function = SensorSamplingFunction(rawValue: parameters[offset + 5]) else {
            return nil
        }
        self.samplingFunction = function
        self.measurementPeriodValue = parameters[offset + 6]
        self.updateIntervalValue = parameters[offset + 7]
    }
}

/// Enumeration of sensor sampling functions.
public enum SensorSamplingFunction: UInt8 {
    /// Sampling function is not made available.
    case unspecified    = 0x00
    /// The presented value is an instantaneous sample.
    case instantaneous  = 0x01
    /// The presented value is the arithmetic mean of multiple samples.
    case arithmeticMean = 0x02
    /// The presented value is the root mean square of multiple samples.
    case rms            = 0x03
    /// The presented value is the maximum of multiple samples.
    case maximum        = 0x04
    /// The presented value is the minimum of multiple samples.
    case minimum        = 0x05
    /// The Accumulated sampling function is intended to represent a
    /// cumulative moving average.
    ///
    /// The Sensor Measurement Period in this case would state the length
    /// of the period over which a counted number of lightning strikes was
    /// detected.
    case accumulated    = 0x06
    /// The Count sampling function can be used for a discrete variable
    /// such as the number of lightning discharges detected by a lightning
    /// detector.
    ///
    /// The measurement value would be a cumulative moving average value
    /// that was continually updated with a frequency indicated by the
    /// Sensor Update Interval.
    case count          = 0x07
}

/// The structure of sensor cadence.
public struct SensorCadence {
    
    /// The Status Trigger Delta controls the positive and negative
    /// change of a measured quantity that triggers more rapid publication of
    /// a Sensor Status message.
    ///
    /// Depending on the Sensor Trigger Type value, the
    public enum StatusTriggerDelta {
        /// The delta type and unit is defined by the Format Type of the characteristic
        /// of the Sensor Property.
        case values(down: DevicePropertyCharacteristic, up: DevicePropertyCharacteristic)
        /// The unit is «unitless», and the value is represented as a percentage
        /// change with a resolution of 0.01 percent.
        case percentage(down: UInt16, up: UInt16)
        
        internal var data: Data {
            switch self {
            case let .values(down: deltaDown, up: deltaUp):
                return deltaDown.data + deltaUp.data
            case let .percentage(down: down, up: up):
                return Data() + down + up
            }
        }
    }
    
    /// The Fast Cadence Period Divisor field is a 7-bit value that shall
    /// control the increased cadence of publishing Sensor Status messages.
    /// The value is represented as a 2^n divisor of the Publish Period.
    /// For example, the value 0x04 would have a divisor of 16, and the value 0x00
    /// would have a divisor of 1 (i.e., the Publish Period would not change).
    ///
    /// The valid range for the Fast Cadence Period Divisor state is 0..15
    /// and other values are Prohibited.
    public let fastCadencePeriodDivisor: UInt8
    /// Defines the unit and format of the Status Trigger Delta fields.
    ///
    /// The value of 0x00 means that the format shall be defined by the Format Type
    /// of the characteristic that the Sensor Property ID state references.
    /// The value of 0x01 means that the unit is «unitless», and the value is
    /// represented as a percentage change with a resolution of 0.01 percent.
    internal let statusTriggerType: UInt8
    /// The Status Trigger Delta field shall control the positive and negative
    /// change of a measured quantity that triggers more rapid publication of
    /// a Sensor Status message.
    ///
    /// A value represented by the Fast Cadence Period Divisor state is used as
    /// a divider for the Publish Period (configured for the model) if the change
    /// exceeds the conditions determined by delta.
    public let statusTriggerDelta: StatusTriggerDelta
    /// The Status Min Interval field is a 1-octet value that shall control
    /// the minimum interval between publishing two consecutive Sensor Status
    /// messages.
    ///
    /// The value is represented as 2^n milliseconds. For example, the value
    /// 0x0A would represent an interval of 1024 ms.
    ///
    /// The valid range for the Status Min Interval is 0–26 and other values
    /// are Prohibited.
    public let statusMinIntervalValue: UInt8
    /// The Fast Cadence Low field shall define the lower boundary of a range
    /// of measured quantities when the publishing cadence is increased as
    /// defined by the Fast Cadence Period Divisor field.
    public let fastCadenceLow: DevicePropertyCharacteristic
    /// The Fast Cadence High field shall define the upper boundary of a range
    /// of measured quantities when the publishing cadence is increased as
    /// defined by the Fast Cadence Period Divisor field.
    public let fastCadenceHigh: DevicePropertyCharacteristic
    
    /// The Status Min Interval field controls the minimum interval between
    /// publishing two consecutive Sensor Status messages.
    public var statusMinInterval: TimeInterval {
        return pow(2.0, Double(statusMinIntervalValue)) / 1000.0
    }
    
    /// Creates Sensor Cadence object.
    ///
    /// - parameters:
    ///   - divider: Publish period divider.
    ///   - low: Low threshold value of characteristic to initiate publishing
    ///          with publish period divider.
    ///   - high: High threshold value of characteristic to initiate publishing
    ///           with publish period divider.
    ///   - deltaDown: Smallest delta down to initiate fast publishing.
    ///   - deltaUp:   Smallest delta up to initiate fast publishing.
    ///   - minInterval: Minimum interval between publications, in `2^n`
    ///                  milliseconds. Valid range is 0..26.
    public init(increasePublishingFrequencyWithPeriodDivider divider: UInt8,
                whenValueIsAbove low: DevicePropertyCharacteristic,
                andBelow high: DevicePropertyCharacteristic,
                orChangesDownByMoreThan deltaDown: DevicePropertyCharacteristic,
                orUpBy deltaUp: DevicePropertyCharacteristic,
                withMinIntervalExponent minInterval: UInt8) {
        self.fastCadencePeriodDivisor = divider
        self.fastCadenceLow = low
        self.fastCadenceHigh = high
        self.statusMinIntervalValue = min(minInterval, 26)
        self.statusTriggerType = 0x00
        self.statusTriggerDelta = .values(down: deltaDown, up: deltaUp)
    }
    
    /// Creates Sensor Cadence object.
    ///
    /// - parameters:
    ///   - divider: Publish period divider.
    ///   - low: Low threshold value of characteristic to initiate publishing
    ///          with publish period divider.
    ///   - high: High threshold value of characteristic to initiate publishing
    ///           with publish period divider.
    ///   - deltaDown: Smallest delta down to initiate fast publishing,
    ///                in 0.01 percent.
    ///   - deltaUp:   Smallest delta up to initiate fast publishing,
    ///                in 0.01 percent.
    ///   - minInterval: Minimum interval between publications, in `2^n`
    ///                  milliseconds. Valid range is 0..26.
    public init(increasePublishingFrequencyWithPeriodDivider divider: UInt8,
                whenValueIsAbove low: DevicePropertyCharacteristic,
                andBelow high: DevicePropertyCharacteristic,
                orChangesDownByMoreThan deltaDown: UInt16, millipercentOrUpBy deltaUp: UInt16,
                millipercentWithMinIntervalExponent minInterval: UInt8) {
        self.fastCadencePeriodDivisor = divider
        self.fastCadenceLow = low
        self.fastCadenceHigh = high
        self.statusMinIntervalValue = min(minInterval, 26)
        self.statusTriggerType = 0x01
        self.statusTriggerDelta = .percentage(down: deltaDown, up: deltaUp)
    }
    
    internal init?(of property: DeviceProperty, from parameters: Data, at offset: Int) {
        // At least 6 bytes are needed if the Characteristic Value is just 1 byte.
        guard parameters.count + offset >= 6 else {
            return nil
        }
        self.fastCadencePeriodDivisor = parameters[offset] >> 1
        var len = 1
        let statusTriggerType = parameters[offset] & 0x01
        self.statusTriggerType = statusTriggerType
        if statusTriggerType == 0x00 {
            // Fast Cadence Period Divider and Status Min Interval are 1 byte each.
            // Status Trigger Delta Down, Up and Fast Cadence Low and High have the same length.
            guard (parameters.count - offset - 1 - 1) & 0b11 == 0b00 else {
                return nil
            }
            len = (parameters.count - offset - 1 - 1) / 4
            guard property.valueLength == nil || property.valueLength == len else {
                return nil
            }
            self.statusTriggerDelta = .values(
                down: property.read(from: parameters, at: offset + 1, length: len),
                up: property.read(from: parameters, at: offset + 1 + len, length: len)
            )
            self.statusMinIntervalValue = parameters[offset + 1 + 2 * len]
            self.fastCadenceLow = property.read(from: parameters, at: offset + 1 + 2 * len + 1, length: len)
            self.fastCadenceHigh = property.read(from: parameters, at: offset + 1 + 3 * len + 1, length: len)
        } else {
            // Fast Cadence Period Divider and Status Min Interval are 1 byte each.
            // Status Trigger Delta Down and Up are UInt16.
            // Fast Cadence Low and High have the same length.
            guard (parameters.count - offset - 1 - 1 - 2 - 2) & 0b1 == 0b0 else {
                return nil
            }
            len = (parameters.count - offset - 1 - 1 - 2 - 2) / 2
            guard property.valueLength == nil || property.valueLength == len else {
                return nil
            }
            self.statusTriggerDelta = .percentage(
                down: parameters.read(fromOffset: offset + 1),
                up: parameters.read(fromOffset: offset + 3)
            )
            self.statusMinIntervalValue = parameters[offset + 5]
            self.fastCadenceLow = property.read(from: parameters, at: offset + 6, length: len)
            self.fastCadenceHigh = property.read(from: parameters, at: offset + 6 + len, length: len)
        }
    }
    
    /// The sensor cadence object encoded as Data.
    internal var data: Data {
        var data = Data([(fastCadencePeriodDivisor << 1) | statusTriggerType])
        data += statusTriggerDelta.data + statusMinIntervalValue
        data += fastCadenceLow.data + fastCadenceHigh.data
        return data
    }
}

extension SensorSamplingFunction: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .unspecified:    return "Unspecified"
        case .instantaneous:  return "Instantaneous"
        case .arithmeticMean: return "Arithmetic Mean"
        case .rms:            return "Root Mean Square"
        case .maximum:        return "Maximum"
        case .minimum:        return "Minimum"
        case .accumulated:    return "Accumulated"
        case .count:          return "Count"
        }
    }
    
}
