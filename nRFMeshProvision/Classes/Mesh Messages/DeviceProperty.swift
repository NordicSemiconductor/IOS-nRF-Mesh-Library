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

/// The device property.
///
/// - note: Each property has a corresponding `DevicePropertyCharacteristic`.
///         However, currently not all values are implemented in this library.
///         For those, `.other` should be used until they are implemented.
public enum DeviceProperty: UInt16 {
    case averageAmbientTemperatureInAPeriodOfDay = 0x0001
    case averageInputCurrent = 0x0002
    case averageInputVoltage = 0x0003
    case averageOutputCurrent = 0x0004
    case averageOutputVoltage = 0x0005
    case centerBeamIntensityAtFullPower = 0x0006
    case chromaticityTolerance = 0x0007
    case colorRenderingIndexR9 = 0x0008
    case colorRenderingIndexRa = 0x0009
    case deviceAppearance = 0x000A
    case deviceCountryOfOrigin = 0x000B
    case deviceDateOfManufacture = 0x000C
    case deviceEnergyUseSinceTurnOn = 0x000D
    case deviceFirmwareRevision = 0x000E
    case deviceGlobalTradeItemNumber = 0x000F
    case deviceHardwareRevision = 0x0010
    case deviceManufacturerName = 0x0011
    case deviceModelNumber = 0x0012
    case deviceOperatingTemperatureRangeSpecification = 0x0013
    case deviceOperatingTemperatureStatisticalValues = 0x0014
    case deviceOverTemperatureEventStatistics = 0x0015
    case devicePowerRangeSpecification = 0x0016
    case deviceRuntimeSinceTurnOn = 0x0017
    case deviceRuntimeWarranty = 0x0018
    case deviceSerialNumber = 0x0019
    case deviceSoftwareRevision = 0x001A
    case deviceUnderTemperatureEventStatistics = 0x001B
    case indoorAmbientTemperatureStatisticalValues = 0x001C
    case initialCIE1931ChromaticityCoordinates = 0x001D
    case initialCorrelatedColorTemperature = 0x001E
    case initialLuminousFlux = 0x001F
    case initialPlanckianDistance = 0x0020
    case inputCurrentRangeSpecification = 0x0021
    case inputCurrentStatistics = 0x0022
    case inputOverCurrentEventStatistics = 0x0023
    case inputOverRippleVoltageEventStatistics = 0x0024
    case inputOverVoltageEventStatistics = 0x0025
    case inputUnderCurrentEventStatistics = 0x0026
    case inputUnderVoltageEventStatistics = 0x0027
    case inputVoltageRangeSpecification = 0x0028
    case inputVoltageRippleSpecification = 0x0029
    case inputVoltageStatistics = 0x002A
    case lightControlAmbientLuxLevelOn = 0x002B
    case lightControlAmbientLuxLevelProlong = 0x002C
    case lightControlAmbientLuxLevelStandby = 0x002D
    case lightControlLightnessOn = 0x002E
    case lightControlLightnessProlong = 0x002F
    case lightControlLightnessStandby = 0x0030
    case lightControlRegulatorAccuracy = 0x0031
    case lightControlRegulatorKid = 0x0032
    case lightControlRegulatorKiu = 0x0033
    case lightControlRegulatorKpd = 0x0034
    case lightControlRegulatorKpu = 0x0035
    case lightControlTimeFade = 0x0036
    case lightControlTimeFadeOn = 0x0037
    case lightControlTimeFadeStandbyAuto = 0x0038
    case lightControlTimeFadeStandbyManual = 0x0039
    case lightControlTimeOccupancyDelay = 0x003A
    case lightControlTimeProlong = 0x003B
    case lightControlTimeRunOn = 0x003C
    case lumenMaintenanceFactor = 0x003D
    case luminousEfficacy = 0x003E
    case luminousEnergySinceTurnOn = 0x003F
    case luminousExposure = 0x0040
    case luminousFluxRange = 0x0041
    case motionSensed = 0x0042
    case motionThreshold = 0x0043
    case openCircuitEventStatistics = 0x0044
    case outdoorStatisticalValues = 0x0045
    case outputCurrentRange = 0x0046
    case outputCurrentStatistics = 0x0047
    case outputRippleVoltageSpecification = 0x0048
    case outputVoltageRange = 0x0049
    case outputVoltageStatistics = 0x004A
    case overOutputRippleVoltageEventStatistics = 0x004B
    case peopleCount = 0x004C
    case presenceDetected = 0x004D
    case presentAmbientLightLevel = 0x004E
    case presentAmbientTemperature = 0x004F
    case presentCIE1931ChromaticityCoordinates = 0x0050
    case presentCorrelatedColorTemperature = 0x0051
    case presentDeviceInputPower = 0x0052
    case presentDeviceOperatingEfficiency = 0x0053
    case presentDeviceOperatingTemperature = 0x0054
    case presentIlluminance = 0x0055
    case presentIndoorAmbientTemperature = 0x0056
    case presentInputCurrent = 0x0057
    case presentInputRippleVoltage = 0x0058
    case presentInputVoltage = 0x0059
    case presentLuminousFlux = 0x005A
    case presentOutdoorAmbientTemperature = 0x005B
    case presentOutputCurrent = 0x005C
    case presentOutputVoltage = 0x005D
    case presentPlanckianDistance = 0x005E
    case presentRelativeOutputRippleVoltage = 0x005F
    case relativeDeviceEnergyUseInAPeriodOfDay = 0x0060
    case relativeDeviceRuntimeInAGenericLevelRange = 0x0061
    case relativeExposureTimeInAnIlluminanceRange = 0x0062
    case relativeRuntimeInACorrelatedColorTemperatureRange = 0x0063
    case relativeRuntimeInADeviceOperatingTemperatureRange = 0x0064
    case relativeRuntimeInAnInputCurrentRange = 0x0065
    case relativeRuntimeInAnInputVoltageRange = 0x0066
    case shortCircuitEventStatistics = 0x0067
    case timeSinceMotionSensed = 0x0068
    case timeSincePresenceDetected = 0x0069
    case totalDeviceEnergyUse = 0x006A
    case totalDeviceOffOnCycles = 0x006B
    case totalDevicePowerOnCycles = 0x006C
    case totalDevicePowerOnTime = 0x006D
    case totalDeviceRuntime = 0x006E
    case totalLightExposureTime = 0x006F
    case totalLuminousEnergy = 0x0070
    case desiredAmbientTemperature = 0x0071
    case preciseTotalDeviceEnergyUse = 0x0072
    case powerFactor = 0x0073
    case sensorGain = 0x0074
    case precisePresentAmbientTemperature = 0x0075
    case presentAmbientRelativeHumidity = 0x0076
    case presentAmbientCarbonDioxideConcentration = 0x0077
    case presentAmbientVolatileOrganicCompoundsConcentration = 0x0078
    case presentAmbientNoise = 0x0079
 // case these are undefined in Mesh Device Properties v2 = 0x007A
 // case these are undefined in Mesh Device Properties v2 = 0x007B
 // case these are undefined in Mesh Device Properties v2 = 0x007C
 // case these are undefined in Mesh Device Properties v2 = 0x007D
 // case these are undefined in Mesh Device Properties v2 = 0x007E
 // case these are undefined in Mesh Device Properties v2 = 0x007F
    case activeEnergyLoadside = 0x0080
    case activePowerLoadside = 0x0081
    case airPressure = 0x0082
    case apparentEnergy = 0x0083
    case apparentPower = 0x0084
    case apparentWindDirection = 0x0085
    case apparentWindSpeed = 0x0086
    case dewPoint = 0x0087
    case externalSupplyVoltage = 0x0088
    case externalSupplyVoltageFrequency = 0x0089
    case gustFactor = 0x008A
    case heatIndex = 0x008B
    case lightDistribution = 0x008C
    case lightSourceCurrent = 0x008D
    case lightSourceOnTimeNotResettable = 0x008E
    case lightSourceOnTimeResettable = 0x008F
    case lightSourceOpenCircuitStatistics = 0x0090
    case lightSourceOverallFailuresStatistics = 0x0091
    case lightSourceShortCircuitStatistics = 0x0092
    case lightSourceStartCounterResettable = 0x0093
    case lightSourceTemperature = 0x0094
    case lightSourceThermalDeratingStatistics = 0x0095
    case lightSourceThermalShutdownStatistics = 0x0096
    case lightSourceTotalPowerOnCycles = 0x0097
    case lightSourceVoltage = 0x0098
    case luminaireColor = 0x0099
    case luminaireIdentificationNumber = 0x009A
    case luminaireManufacturerGTIN = 0x009B
    case luminaireNominalInputPower = 0x009C
    case luminaireNominalMaximumACMainsVoltage = 0x009D
    case luminaireNominalMinimumACMainsVoltage = 0x009E
    case luminairePowerAtMinimumDimLevel = 0x009F
    case luminaireTimeOfManufacture = 0x00A0
    case magneticDeclination = 0x00A1
    case magneticFluxDensity2D = 0x00A2
    case magneticFluxDensity3D = 0x00A3
    case nominalLightOutput = 0x00A4
    case overallFailureCondition = 0x00A5
    case pollenConcentration = 0x00A6
    case presentIndoorRelativeHumidity = 0x00A7
    case presentOutdoorRelativeHumidity = 0x00A8
    case pressure = 0x00A9
    case rainfall = 0x00AA
    case ratedMedianUsefulLifeOfLuminaire = 0x00AB
    case ratedMedianUsefulLightSourceStarts = 0x00AC
    case referenceTemperature = 0x00AD
    case totalDeviceStarts = 0x00AE
    case trueWindDirection = 0x00AF
    case trueWindSpeed = 0x00B0
    case uVIndex = 0x00B1
    case windChill = 0x00B2
    case lightSourceType = 0x00B3
    case luminaireIdentificationString = 0x00B4
    case outputPowerLimitation = 0x00B5
    case thermalDerating = 0x00B6
    case outputCurrentPercent = 0x00B7
    
}

internal extension DeviceProperty {
    
    /// Lenght of the characteristic value in bytes.
    ///
    /// If the characteristic is not yet supported, this is `nil`.
    var valueLength: Int? {
        switch self {
        case .presenceDetected,
             .lightControlRegulatorAccuracy,
             .outputRippleVoltageSpecification,
             .inputVoltageRippleSpecification,
             .outputCurrentPercent,
             .lumenMaintenanceFactor,
             .motionSensed,
             .motionThreshold,
             .presentDeviceOperatingEfficiency,
             .presentRelativeOutputRippleVoltage,
             .presentInputRippleVoltage,
             .desiredAmbientTemperature,
             .presentAmbientTemperature,
             .presentIndoorAmbientTemperature,
             .presentOutdoorAmbientTemperature:
            return 1
            
        case .lightControlLightnessOn,
             .lightControlLightnessProlong,
             .lightControlLightnessStandby,
             .peopleCount,
             .presentAmbientRelativeHumidity,
             .presentIndoorRelativeHumidity,
             .presentOutdoorRelativeHumidity,
             .timeSinceMotionSensed,
             .timeSincePresenceDetected:
            return 2
            
        case .deviceDateOfManufacture,
             .deviceRuntimeSinceTurnOn,
             .deviceRuntimeWarranty,
             .totalDeviceStarts,
             .totalDevicePowerOnTime,
             .totalDeviceRuntime,
             .totalLightExposureTime,
             .totalDeviceOffOnCycles,
             .totalDevicePowerOnCycles,
             .lightControlTimeFade,
             .lightControlTimeFadeOn,
             .lightControlTimeFadeStandbyAuto,
             .lightControlTimeFadeStandbyManual,
             .lightControlTimeOccupancyDelay,
             .lightControlTimeProlong,
             .lightControlTimeRunOn,
             .lightControlAmbientLuxLevelOn,
             .lightControlAmbientLuxLevelProlong,
             .lightControlAmbientLuxLevelStandby,
             .lightSourceStartCounterResettable,
             .lightSourceTotalPowerOnCycles,
             .luminaireTimeOfManufacture,
             .presentAmbientLightLevel,
             .presentIlluminance,
             .ratedMedianUsefulLightSourceStarts,
             .ratedMedianUsefulLifeOfLuminaire:
            return 3
            
        case .airPressure,
             .pressure,
             .lightControlRegulatorKid,
             .lightControlRegulatorKiu,
             .lightControlRegulatorKpd,
             .lightControlRegulatorKpu,
             .sensorGain:
            return 4
            
        case .deviceFirmwareRevision,
             .deviceSoftwareRevision:
            return 8
        case .deviceHardwareRevision,
             .deviceSerialNumber:
            return 16
        case .deviceModelNumber,
             .luminaireColor,
             .luminaireIdentificationNumber:
            return 24
        case .deviceManufacturerName:
            return 36
        case .luminaireIdentificationString:
            return 64
            
        default:
            return nil // Unknown
        }
    }
    
    /// Parses the characteristic from given data.
    ///
    /// - important: This method does not ensure that the length of data is sufficient.
    ///
    /// - parameters:
    ///   - data:   The data to be read from.
    ///   - offset: The offset.
    ///   - length: Expected length of the data.
    /// - returns: The characteristic value.
    func read(from data: Data, at offset: Int, length: Int) -> DevicePropertyCharacteristic {
        switch self {
        // Bool:
        case .presenceDetected:
            return .bool(data[offset] != 0x00)
        
        // UInt8:
        case .lightControlRegulatorAccuracy,
             .outputRippleVoltageSpecification,
             .inputVoltageRippleSpecification,
             .outputCurrentPercent,
             .lumenMaintenanceFactor,
             .motionSensed,
             .motionThreshold,
             .presentDeviceOperatingEfficiency,
             .presentRelativeOutputRippleVoltage,
             .presentInputRippleVoltage:
            return .percentage8(data[offset])
            
        // Int8:
        case .desiredAmbientTemperature,
             .presentAmbientTemperature,
             .presentIndoorAmbientTemperature,
             .presentOutdoorAmbientTemperature:
            return .temperature8(Int8(bitPattern: data[offset]))
            
        // UInt16:
        case .peopleCount:
            return .count16(data.read(fromOffset: offset))
        case .presentAmbientRelativeHumidity,
             .presentIndoorRelativeHumidity,
             .presentOutdoorRelativeHumidity:
            return .humidity(data.read(fromOffset: offset))
        case .lightControlLightnessOn,
             .lightControlLightnessProlong,
             .lightControlLightnessStandby:
            return .perceivedLightness(data.read(fromOffset: offset))
        case .timeSinceMotionSensed,
             .timeSincePresenceDetected:
            return .timeSecond16(data.read(fromOffset: offset))
            
        // UInt24:
        case .lightSourceStartCounterResettable,
             .lightSourceTotalPowerOnCycles,
             .ratedMedianUsefulLightSourceStarts,
             .totalDeviceOffOnCycles,
             .totalDevicePowerOnCycles,
             .totalDeviceStarts:
            return .count24(data.readUInt24(fromOffset: offset))
        case .lightControlAmbientLuxLevelOn,
             .lightControlAmbientLuxLevelProlong,
             .lightControlAmbientLuxLevelStandby,
             .presentAmbientLightLevel,
             .presentIlluminance:
            return .illuminance(data.readUInt24(fromOffset: offset))
        case .deviceRuntimeSinceTurnOn,
             .deviceRuntimeWarranty,
             .ratedMedianUsefulLifeOfLuminaire,
             .totalDevicePowerOnTime,
             .totalDeviceRuntime,
             .totalLightExposureTime:
            return .timeHour24(data.readUInt24(fromOffset: offset))
        case .lightControlTimeFade,
             .lightControlTimeFadeOn,
             .lightControlTimeFadeStandbyAuto,
             .lightControlTimeFadeStandbyManual,
             .lightControlTimeOccupancyDelay,
             .lightControlTimeProlong,
             .lightControlTimeRunOn:
            return .timeMillisecond24(data.readUInt24(fromOffset: offset))
        case .deviceDateOfManufacture,
             .luminaireTimeOfManufacture:
            let numberOfDays = data.readUInt24(fromOffset: offset)
            let timeInterval = TimeInterval(numberOfDays) * 86400.0
            return .dateUTC(Date(timeIntervalSince1970: timeInterval))
            
        // UInt32:
        case .pressure,
             .airPressure:
            return .pressure(data.read(fromOffset: offset))
            
        // Float32 (IEEE 754):
        case .lightControlRegulatorKid,
             .lightControlRegulatorKiu,
             .lightControlRegulatorKpd,
             .lightControlRegulatorKpu,
             .sensorGain:
            let asInt32: UInt32 = data.read(fromOffset: offset)
            return .coefficient(Float(bitPattern: asInt32))
            
        // String:
        case .deviceFirmwareRevision,
             .deviceSoftwareRevision:
            return .fixedString8(String(data: data.subdata(in: offset..<offset + 8), encoding: .utf8)!)
        case .deviceHardwareRevision,
             .deviceSerialNumber:
            return .fixedString16(String(data: data.subdata(in: offset..<offset + 16), encoding: .utf8)!)
        case .deviceModelNumber,
             .luminaireColor,
             .luminaireIdentificationNumber:
            return .fixedString24(String(data: data.subdata(in: offset..<offset + 24), encoding: .utf8)!)
        case .deviceManufacturerName:
            return .fixedString36(String(data: data.subdata(in: offset..<offset + 36), encoding: .utf8)!)
        case .luminaireIdentificationString:
            return .fixedString64(String(data: data.subdata(in: offset..<offset + 64), encoding: .utf8)!)
            
        // Other:
        default:
            return .other(data.subdata(in: offset..<offset + length))
        }
    }
    
}

/// A representation of a property charactersitic.
public enum DevicePropertyCharacteristic {
    /// True or false.
    case bool(Bool)
    /// The Count 16 characteristic is used to represent a general count value.
    ///
    /// A value of 0xFFFF represents 'value is not known'.
    case count16(UInt16)
    /// The Count 24 characteristic is used to represent a general count value.
    ///
    /// A value of 0xFFFFFF represents 'value is not known'.
    case count24(UInt32)
    /// The Coefficient characteristic is used to represent a general coefficient value.
    case coefficient(Float32)
    /// Date as days elapsed since the Epoch (Jan 1, 1970) in the Coordinated Universal
    /// Time (UTC) time zone.
    ///
    /// A value of 0x000000 (Jan 1, 1970) represents 'value is not known'.
    case dateUTC(Date)
    /// The Fixed String 8 characteristic represents an 8-octet UTF-8 string.
    case fixedString8(String)
    /// The Fixed String 16 characteristic represents a 16-octet UTF-8 string.
    case fixedString16(String)
    /// The Fixed String 24 characteristic represents a 24-octet UTF-8 string.
    case fixedString24(String)
    /// The Fixed String 36 characteristic represents a 36-octet UTF-8 string.
    case fixedString36(String)
    /// The Fixed String 64 characteristic represents a 64-octet UTF-8 string.
    case fixedString64(String)
    /// The Humidity characteristic is used to represent humidity value in
    /// percent with a resolution of 0.01 percent.
    case humidity(UInt16)
    /// The Illuminance characteristic is used to represent a measure of illuminance
    /// in units of lux with resolution 0.01 lux.
    ///
    /// A value of 0xFFFFFF represents 'value is not known'.
    case illuminance(UInt32)
    /// The Percentage 8 characteristic is used to represent a measure of percentage.
    ///
    /// Unit is a percentage with a resolution of 0.5.
    ///
    /// A value of 0xFF represents 'value is not known'.
    /// Values 201..254 are Prohibited.
    case percentage8(UInt8)
    /// The Perceived Lightness characteristic is used to represent the perceived
    /// lightness of a light.
    case perceivedLightness(UInt16)
    /// The Pressure characteristic is used to represent a pressure value.
    ///
    /// Unit is in pascals with a resolution of 0.1 Pa.
    case pressure(UInt32)
    /// The Temperature 8 characteristic is used to represent a measure of
    /// temperature with a unit of 0.5 degree Celsius.
    ///
    /// A value of 0x7F represents 'value is not known'.
    case temperature8(Int8)
    /// The Time Hour 24 characteristic is used to represent a period of time in hours.
    ///
    /// A value of 0xFFFFFF represents 'value is not known'.
    case timeHour24(UInt32)
    /// The Time Millisecond 24 characteristic is used to represent a period of time
    /// with a resolution of 1 millisecond.
    ///
    /// A value of 0xFFFFFF represents 'value is not known'.
    case timeMillisecond24(UInt32)
    /// The Time Second 16 characteristic is used to represent a period of time with
    /// a unit of 1 second.
    ///
    /// A value of 0xFFFF represents 'value is not known'.
    case timeSecond16(UInt16)
    /// The Time Second 32 characteristic is used to represent a period of time with
    /// a unit of 1 second.
    ///
    /// A value of 0xFFFFFF represents 'value is not known'.
    case timeSecond32(UInt32)
    /// Generic data type for other characteristics.
    case other(Data)
    
}

internal extension DevicePropertyCharacteristic {
    
    /// The characteristic value as Data.
    var data: Data {
        switch self {
        // Bool:
        case .bool(let value):
            return Data([value ? 0x01 : 0x00])
            
        // UInt8:
        case .percentage8(let value):
            return Data([value])
            
        // Int8:
        case .temperature8(let value):
            return Data([UInt8(bitPattern: value)])
            
        // UInt16:
        case .count16(let value),
             .humidity(let value),
             .timeSecond16(let value),
             .perceivedLightness(let value):
            return Data() + value
            
        // UInt24:
        case .count24(let value),
             .illuminance(let value),
             .timeHour24(let value),
             .timeMillisecond24(let value):
            return (Data() + value).dropLast()
            
        case .dateUTC(let date):
            let numberOfDays = UInt32(date.timeIntervalSince1970 / 86400.0) // convert to days
            return (Data() + numberOfDays).dropLast()
        
        // UInt32:
        case .pressure(let value),
             .timeSecond32(let value):
            return Data() + value
        
        // Float32 (IEEE 754):
        case .coefficient(let value):
            return Data() + value.bitPattern
            
        // String: (we need to ensure the required number of bytes)
        case .fixedString8(let string):
            return string.padding(toLength: 8, withPad: " ", startingAt: 0).data(using: .utf8)!.prefix(8)
        case .fixedString16(let string):
            return string.padding(toLength: 16, withPad: " ", startingAt: 0).data(using: .utf8)!.prefix(16)
        case .fixedString24(let string):
            return string.padding(toLength: 24, withPad: " ", startingAt: 0).data(using: .utf8)!.prefix(24)
        case .fixedString36(let string):
            return string.padding(toLength: 36, withPad: " ", startingAt: 0).data(using: .utf8)!.prefix(36)
        case .fixedString64(let string):
            return string.padding(toLength: 64, withPad: " ", startingAt: 0).data(using: .utf8)!.prefix(64)
            
        // Other:
        case .other(let data):
            return data
        }
    }
}

extension DevicePropertyCharacteristic: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        // Bool:
        case .bool(let value):
            // There's only one Boolean property: .presenceDetected.
            return value ? "Presence Detected" : "Presence Not Detected"
            
        // UInt8:
        case .percentage8(let percent):
            switch percent {
            case 0xFF:
                return "Value is not known"
            case let percent where percent >= 0 && percent <= 200:
                return String(format: "%.1f%%", Float(percent) / 2.0)
            default:
                return "Prohibited (\(percent))"
            }
            
        // Int8:
        case .temperature8(let temp):
            switch temp {
            case 0x7F:
                return "Value is not known"
            default:
                return String(format: "%.1f°C", Float(temp) / 2.0)
            }
            
        // UInt16:
        case .count16(let count):
            switch count {
            case 0xFFFF:
                return "Value is not known"
            default:
                return "\(count)" // unitless
            }
        case .perceivedLightness(let count):
            return "\(count)"
        case .timeSecond16(let count):
            switch count {
            case 0xFFFF:
                return "Value is not known"
            default:
                return "\(count) seconds"
            }
            
        // UInt24:
        case .count24(let count):
            switch count {
            case 0xFFFFFF:
                return "Value is not known"
            default:
                return "\(count)" // unitless
            }
        case .humidity(let percent):
            switch percent {
            case let percent where percent <= 10000:
                return String(format: "%.2f%%", Float(percent) / 100.0)
            default:
                return "Prohibited (\(percent))"
            }
        case .illuminance(let millilux):
            switch millilux {
            case 0xFFFFFF:
                return "Value is not known"
            default:
                return String(format: "%.2f lux", Float(millilux) / 100.0)
            }
        case .timeHour24(let count):
            switch count {
            case let count where count >= 0xFFFFFF:
                return "Value is not known"
            default:
                return "\(count) hours"
            }
        case .timeMillisecond24(let count):
            switch count {
            case let invalid where invalid >= 0xFFFFFF:
                return "Value is not known"
            default:
                return "\(count) ms"
            }
        case .dateUTC(let date):
            if date.timeIntervalSince1970 < 86400 {
                return "Value is not known"
            }
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            return dateFormatter.string(from: date)
            
        // UInt32:
        case .pressure(let pressure):
            return String(format: "%.1f Pa", Double(pressure) / 10.0)
        case .timeSecond32(let count):
            switch count {
            case 0xFFFFFFFF:
                return "Value is not known"
            default:
                return "\(count) seconds"
            }
            
        // Float32 (IEEE 754):
        case .coefficient(let coefficient):
            return "\(coefficient)" // unitless
            
        // String:
        case .fixedString8(let string),
             .fixedString16(let string),
             .fixedString24(let string),
             .fixedString36(let string),
             .fixedString64(let string):
            return string
            
        // Other:
        case .other(let data):
            return data.hex
        }
    }
    
}

extension DeviceProperty: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .averageAmbientTemperatureInAPeriodOfDay: return "Average Ambient Temperature In A Period Of Day"
        case .averageInputCurrent: return "Average Input Current"
        case .averageInputVoltage: return "Average Input Voltage"
        case .averageOutputCurrent: return "Average Output Current"
        case .averageOutputVoltage: return "Average Output Voltage"
        case .centerBeamIntensityAtFullPower: return "Center Beam Intensity At Full Power"
        case .chromaticityTolerance: return "Chromaticity T olerance"
        case .colorRenderingIndexR9: return "Color Rendering Index R9"
        case .colorRenderingIndexRa: return "Color Rendering Index Ra"
        case .deviceAppearance: return "Device Appearance"
        case .deviceCountryOfOrigin: return "Device Country Of Origin"
        case .deviceDateOfManufacture: return "Device Date Of Manufacture"
        case .deviceEnergyUseSinceTurnOn: return "Device Energy Use Since Turn On"
        case .deviceFirmwareRevision: return "Device Firmware Revision"
        case .deviceGlobalTradeItemNumber: return "Device Global Trade Item Number"
        case .deviceHardwareRevision: return "Device Hardware Revision"
        case .deviceManufacturerName: return "Device Manufacturer Name"
        case .deviceModelNumber: return "Device Model Number"
        case .deviceOperatingTemperatureRangeSpecification: return "Device Operating Temperature Range Specification"
        case .deviceOperatingTemperatureStatisticalValues: return "Device Operating Temperature Statistical Values"
        case .deviceOverTemperatureEventStatistics: return "Device Over Temperature Event Statistics"
        case .devicePowerRangeSpecification: return "Device Power Range Specification"
        case .deviceRuntimeSinceTurnOn: return "Device Runtime Since Turn On"
        case .deviceRuntimeWarranty: return "Device Runtime Warranty"
        case .deviceSerialNumber: return "Device Serial Number"
        case .deviceSoftwareRevision: return "Device Software Revision"
        case .deviceUnderTemperatureEventStatistics: return "Device Under Temperature Event Statistics"
        case .indoorAmbientTemperatureStatisticalValues: return "Indoor Ambient Temperature Statistical Values"
        case .initialCIE1931ChromaticityCoordinates: return "Initial CIE 1931 Chromaticity Coordinates"
        case .initialCorrelatedColorTemperature: return "Initial Correlated Color Temperature"
        case .initialLuminousFlux: return "Initial Luminous Flux"
        case .initialPlanckianDistance: return "Initial Planckian Distance"
        case .inputCurrentRangeSpecification: return "Input Current Range Specification"
        case .inputCurrentStatistics: return "Input Current Statistics"
        case .inputOverCurrentEventStatistics: return "Input Over Current Event Statistics"
        case .inputOverRippleVoltageEventStatistics: return "Input Over Ripple Voltage Event Statistics"
        case .inputOverVoltageEventStatistics: return "Input Over Voltage Event Statistics"
        case .inputUnderCurrentEventStatistics: return "Input Under Current Event Statistics"
        case .inputUnderVoltageEventStatistics: return "Input Under Voltage Event Statistics"
        case .inputVoltageRangeSpecification: return "Input Voltage Range Specification"
        case .inputVoltageRippleSpecification: return "Input Voltage Ripple Specification"
        case .inputVoltageStatistics: return "Input Voltage Statistics"
        case .lightControlAmbientLuxLevelOn: return "Light Control Ambient LuxLevel On"
        case .lightControlAmbientLuxLevelProlong: return "Light Control Ambient LuxLevel Prolong"
        case .lightControlAmbientLuxLevelStandby: return "Light Control Ambient LuxLevel Standby"
        case .lightControlLightnessOn: return "Light Control Lightness On"
        case .lightControlLightnessProlong: return "Light Control Lightness Prolong"
        case .lightControlLightnessStandby: return "Light Control Lightness Standby"
        case .lightControlRegulatorAccuracy: return "Light Control Regulator Accuracy"
        case .lightControlRegulatorKid: return "Light Control Regulator Kid"
        case .lightControlRegulatorKiu: return "Light Control Regulator Kiu"
        case .lightControlRegulatorKpd: return "Light Control Regulator Kpd"
        case .lightControlRegulatorKpu: return "Light Control Regulator Kpu"
        case .lightControlTimeFade: return "Light Control Time Fade"
        case .lightControlTimeFadeOn: return "Light Control Time Fade On"
        case .lightControlTimeFadeStandbyAuto: return "Light Control Time Fade Standby Auto"
        case .lightControlTimeFadeStandbyManual: return "Light Control Time Fade Standby Manual"
        case .lightControlTimeOccupancyDelay: return "Light Control Time Occupancy Delay"
        case .lightControlTimeProlong: return "Light Control Time Prolong"
        case .lightControlTimeRunOn: return "Light Control Time Run On"
        case .lumenMaintenanceFactor: return "Lumen Maintenance Factor"
        case .luminousEfficacy: return "Luminous Efficacy"
        case .luminousEnergySinceTurnOn: return "Luminous Energy Since Turn On"
        case .luminousExposure: return "Luminous Exposure"
        case .luminousFluxRange: return "Luminous Flux Range"
        case .motionSensed: return "Motion Sensed"
        case .motionThreshold: return "Motion Threshold"
        case .openCircuitEventStatistics: return "Open Circuit Event Statistics"
        case .outdoorStatisticalValues: return "Outdoor Statistical Values"
        case .outputCurrentRange: return "Output Current Range"
        case .outputCurrentStatistics: return "Output Current Statistics"
        case .outputRippleVoltageSpecification: return "Output Ripple Voltage Specification"
        case .outputVoltageRange: return "Output Voltage Range"
        case .outputVoltageStatistics: return "Output Voltage Statistics"
        case .overOutputRippleVoltageEventStatistics: return "Over Output Ripple Voltage Event Statistics"
        case .peopleCount: return "People Count"
        case .presenceDetected: return "Presence Detected"
        case .presentAmbientLightLevel: return "Present Ambient Light Level"
        case .presentAmbientTemperature: return "Present Ambient Temperature"
        case .presentCIE1931ChromaticityCoordinates: return "Present CIE 1931 Chromaticity Coordinates"
        case .presentCorrelatedColorTemperature: return "Present Correlated Color Temperature"
        case .presentDeviceInputPower: return "Present Device Input Power"
        case .presentDeviceOperatingEfficiency: return "Present Device Operating Efficiency"
        case .presentDeviceOperatingTemperature: return "Present Device Operating Temperature"
        case .presentIlluminance: return "Present Illuminance"
        case .presentIndoorAmbientTemperature: return "Present Indoor Ambient Temperature"
        case .presentInputCurrent: return "Present Input Current"
        case .presentInputRippleVoltage: return "Present Input Ripple Voltage"
        case .presentInputVoltage: return "Present Input Voltage"
        case .presentLuminousFlux: return "Present Luminous Flux"
        case .presentOutdoorAmbientTemperature: return "Present Outdoor Ambient Temperature"
        case .presentOutputCurrent: return "Present Output Current"
        case .presentOutputVoltage: return "Present Output Voltage"
        case .presentPlanckianDistance: return "Present Planckian Distance"
        case .presentRelativeOutputRippleVoltage: return "Present Relative Output Ripple Voltage"
        case .relativeDeviceEnergyUseInAPeriodOfDay: return "Relative Device Energy Use In A Period Of Day"
        case .relativeDeviceRuntimeInAGenericLevelRange: return "Relative Device Runtime In A Generic Level Range"
        case .relativeExposureTimeInAnIlluminanceRange: return "Relative Exposure Time In An Illuminance Range"
        case .relativeRuntimeInACorrelatedColorTemperatureRange: return "Relative Runtime In A Correlated Color Temperature Range"
        case .relativeRuntimeInADeviceOperatingTemperatureRange: return "Relative Runtime In A Device Operating Temperature Range"
        case .relativeRuntimeInAnInputCurrentRange: return "Relative Runtime In An Input Current Range"
        case .relativeRuntimeInAnInputVoltageRange: return "Relative Runtime In An Input Voltage Range"
        case .shortCircuitEventStatistics: return "Short Circuit Event Statistics"
        case .timeSinceMotionSensed: return "Time Since Motion Sensed"
        case .timeSincePresenceDetected: return "Time Since Presence Detected"
        case .totalDeviceEnergyUse: return "Total Device Energy Use"
        case .totalDeviceOffOnCycles: return "Total Device Off On Cycles"
        case .totalDevicePowerOnCycles: return "Total Device Power On Cycles"
        case .totalDevicePowerOnTime: return "Total Device Power On Time"
        case .totalDeviceRuntime: return "Total Device Runtime"
        case .totalLightExposureTime: return "Total Light Exposure Time"
        case .totalLuminousEnergy: return "Total Luminous Energy"
        case .desiredAmbientTemperature: return "Desired Ambient Temperature"
        case .preciseTotalDeviceEnergyUse: return "Precise Total Device Energy Use"
        case .powerFactor: return "Power Factor"
        case .sensorGain: return "Sensor Gain"
        case .precisePresentAmbientTemperature: return "Precise Present Ambient Temperature"
        case .presentAmbientRelativeHumidity: return "Present Ambient Relative Humidity"
        case .presentAmbientCarbonDioxideConcentration: return "Present Ambient Carbon Dioxide Concentration"
        case .presentAmbientVolatileOrganicCompoundsConcentration: return "Present Ambient Volatile Organic Compounds Concentration"
        case .presentAmbientNoise: return "Present Ambient Noise"
        case .activeEnergyLoadside: return "Active Energy Loadside"
        case .activePowerLoadside: return "Active Power Loadside"
        case .airPressure: return "Air Pressure"
        case .apparentEnergy: return "Apparent Energy"
        case .apparentPower: return "Apparent Power"
        case .apparentWindDirection: return "Apparent Wind Direction"
        case .apparentWindSpeed: return "Apparent Wind Speed"
        case .dewPoint: return "Dew Point"
        case .externalSupplyVoltage: return "External Supply Voltage"
        case .externalSupplyVoltageFrequency: return "External Supply Voltage Frequency"
        case .gustFactor: return "Gust Factor"
        case .heatIndex: return "Heat Index"
        case .lightDistribution: return "Light Distribution"
        case .lightSourceCurrent: return "Light Source Current"
        case .lightSourceOnTimeNotResettable: return "Light Source On Time Not Resettable"
        case .lightSourceOnTimeResettable: return "Light Source On Time Resettable"
        case .lightSourceOpenCircuitStatistics: return "Light Source Open Circuit Statistics"
        case .lightSourceOverallFailuresStatistics: return "Light Source Overall Failures Statistics"
        case .lightSourceShortCircuitStatistics: return "Light Source Short Circuit Statistics"
        case .lightSourceStartCounterResettable: return "Light Source Start Counter Resettable"
        case .lightSourceTemperature: return "Light Source Temperature"
        case .lightSourceThermalDeratingStatistics: return "Light Source Thermal Derating Statistics"
        case .lightSourceThermalShutdownStatistics: return "Light Source Thermal Shutdown Statistics"
        case .lightSourceTotalPowerOnCycles: return "Light Source Total Power On Cycles"
        case .lightSourceVoltage: return "Light Source Voltage"
        case .luminaireColor: return "Luminaire Color"
        case .luminaireIdentificationNumber: return "Luminaire Identification Number"
        case .luminaireManufacturerGTIN: return "Luminaire Manufacturer GTIN"
        case .luminaireNominalInputPower: return "Luminaire Nominal Input Power"
        case .luminaireNominalMaximumACMainsVoltage: return "Luminaire Nominal Maximum AC Mains Voltage"
        case .luminaireNominalMinimumACMainsVoltage: return "Luminaire Nominal Minimum AC Mains Voltage"
        case .luminairePowerAtMinimumDimLevel: return "Luminaire Power At Minimum Dim Level"
        case .luminaireTimeOfManufacture: return "Luminaire Time Of Manufacture"
        case .magneticDeclination: return "Magnetic Declination"
        case .magneticFluxDensity2D: return "Magnetic Flux Density - 2D"
        case .magneticFluxDensity3D: return "Magnetic Flux Density - 3D"
        case .nominalLightOutput: return "Nominal Light Output"
        case .overallFailureCondition: return "Overall Failure Condition"
        case .pollenConcentration: return "Pollen Concentration"
        case .presentIndoorRelativeHumidity: return "Present Indoor Relative Humidity"
        case .presentOutdoorRelativeHumidity: return "Present Outdoor Relative Humidity"
        case .pressure: return "Pressure"
        case .rainfall: return "Rainfall"
        case .ratedMedianUsefulLifeOfLuminaire: return "Rated Median Useful Life Of Luminaire"
        case .ratedMedianUsefulLightSourceStarts: return "Rated Median Useful Light Source Starts"
        case .referenceTemperature: return "Reference Temperature"
        case .totalDeviceStarts: return "Total Device Starts"
        case .trueWindDirection: return "True Wind Direction"
        case .trueWindSpeed: return "True Wind Speed"
        case .uVIndex: return "UV Index"
        case .windChill: return "Wind Chill"
        case .lightSourceType: return "Light Source Type"
        case .luminaireIdentificationString: return "Luminaire Identification String"
        case .outputPowerLimitation: return "Output Power Limitation"
        case .thermalDerating: return "Thermal Derating"
        case .outputCurrentPercent: return "Output Current Percent"
        }
    }
    
}
