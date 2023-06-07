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

// MARK: - DeviceProperty

/// Enumeration of Device Properties specified in
/// [Mesh Device Properties 2](https://www.bluetooth.com/specifications/specs/mesh-device-properties-2/).
///
/// Each property has a corresponding ``DevicePropertyCharacteristic``.
///
/// - note: Not all properties have their corresponding characteristics currently
///         implemented in this library. For those,
///         ``DevicePropertyCharacteristic/other(_:)`` should be used
///         until they are implemented.
public enum DeviceProperty {
    case averageAmbientTemperatureInAPeriodOfDay
    case averageInputCurrent
    case averageInputVoltage
    case averageOutputCurrent
    case averageOutputVoltage
    case centerBeamIntensityAtFullPower
    case chromaticityTolerance
    case colorRenderingIndexR9
    case colorRenderingIndexRa
    case deviceAppearance
    case deviceCountryOfOrigin
    case deviceDateOfManufacture
    case deviceEnergyUseSinceTurnOn
    case deviceFirmwareRevision
    case deviceGlobalTradeItemNumber
    case deviceHardwareRevision
    case deviceManufacturerName
    case deviceModelNumber
    case deviceOperatingTemperatureRangeSpecification
    case deviceOperatingTemperatureStatisticalValues
    case deviceOverTemperatureEventStatistics
    case devicePowerRangeSpecification
    case deviceRuntimeSinceTurnOn
    case deviceRuntimeWarranty
    case deviceSerialNumber
    case deviceSoftwareRevision
    case deviceUnderTemperatureEventStatistics
    case indoorAmbientTemperatureStatisticalValues
    case initialCIE1931ChromaticityCoordinates
    case initialCorrelatedColorTemperature
    case initialLuminousFlux
    case initialPlanckianDistance
    case inputCurrentRangeSpecification
    case inputCurrentStatistics
    case inputOverCurrentEventStatistics
    case inputOverRippleVoltageEventStatistics
    case inputOverVoltageEventStatistics
    case inputUnderCurrentEventStatistics
    case inputUnderVoltageEventStatistics
    case inputVoltageRangeSpecification
    case inputVoltageRippleSpecification
    case inputVoltageStatistics
    case lightControlAmbientLuxLevelOn
    case lightControlAmbientLuxLevelProlong
    case lightControlAmbientLuxLevelStandby
    case lightControlLightnessOn
    case lightControlLightnessProlong
    case lightControlLightnessStandby
    case lightControlRegulatorAccuracy
    case lightControlRegulatorKid
    case lightControlRegulatorKiu
    case lightControlRegulatorKpd
    case lightControlRegulatorKpu
    case lightControlTimeFade
    case lightControlTimeFadeOn
    case lightControlTimeFadeStandbyAuto
    case lightControlTimeFadeStandbyManual
    case lightControlTimeOccupancyDelay
    case lightControlTimeProlong
    case lightControlTimeRunOn
    case lumenMaintenanceFactor
    case luminousEfficacy
    case luminousEnergySinceTurnOn
    case luminousExposure
    case luminousFluxRange
    case motionSensed
    case motionThreshold
    case openCircuitEventStatistics
    case outdoorStatisticalValues
    case outputCurrentRange
    case outputCurrentStatistics
    case outputRippleVoltageSpecification
    case outputVoltageRange
    case outputVoltageStatistics
    case overOutputRippleVoltageEventStatistics
    case peopleCount
    case presenceDetected
    case presentAmbientLightLevel
    case presentAmbientTemperature
    case presentCIE1931ChromaticityCoordinates
    case presentCorrelatedColorTemperature
    case presentDeviceInputPower
    case presentDeviceOperatingEfficiency
    case presentDeviceOperatingTemperature
    case presentIlluminance
    case presentIndoorAmbientTemperature
    case presentInputCurrent
    case presentInputRippleVoltage
    case presentInputVoltage
    case presentLuminousFlux
    case presentOutdoorAmbientTemperature
    case presentOutputCurrent
    case presentOutputVoltage
    case presentPlanckianDistance
    case presentRelativeOutputRippleVoltage
    case relativeDeviceEnergyUseInAPeriodOfDay
    case relativeDeviceRuntimeInAGenericLevelRange
    case relativeExposureTimeInAnIlluminanceRange
    case relativeRuntimeInACorrelatedColorTemperatureRange
    case relativeRuntimeInADeviceOperatingTemperatureRange
    case relativeRuntimeInAnInputCurrentRange
    case relativeRuntimeInAnInputVoltageRange
    case shortCircuitEventStatistics
    case timeSinceMotionSensed
    case timeSincePresenceDetected
    case totalDeviceEnergyUse
    case totalDeviceOffOnCycles
    case totalDevicePowerOnCycles
    case totalDevicePowerOnTime
    case totalDeviceRuntime
    case totalLightExposureTime
    case totalLuminousEnergy
    case desiredAmbientTemperature
    case preciseTotalDeviceEnergyUse
    case powerFactor
    case sensorGain
    case precisePresentAmbientTemperature
    case presentAmbientRelativeHumidity
    case presentAmbientCarbonDioxideConcentration
    case presentAmbientVolatileOrganicCompoundsConcentration
    case presentAmbientNoise
    case activeEnergyLoadside
    case activePowerLoadside
    case airPressure
    case apparentEnergy
    case apparentPower
    case apparentWindDirection
    case apparentWindSpeed
    case dewPoint
    case externalSupplyVoltage
    case externalSupplyVoltageFrequency
    case gustFactor
    case heatIndex
    case lightDistribution
    case lightSourceCurrent
    case lightSourceOnTimeNotResettable
    case lightSourceOnTimeResettable
    case lightSourceOpenCircuitStatistics
    case lightSourceOverallFailuresStatistics
    case lightSourceShortCircuitStatistics
    case lightSourceStartCounterResettable
    case lightSourceTemperature
    case lightSourceThermalDeratingStatistics
    case lightSourceThermalShutdownStatistics
    case lightSourceTotalPowerOnCycles
    case lightSourceVoltage
    case luminaireColor
    case luminaireIdentificationNumber
    case luminaireManufacturerGTIN
    case luminaireNominalInputPower
    case luminaireNominalMaximumACMainsVoltage
    case luminaireNominalMinimumACMainsVoltage
    case luminairePowerAtMinimumDimLevel
    case luminaireTimeOfManufacture
    case magneticDeclination
    case magneticFluxDensity2D
    case magneticFluxDensity3D
    case nominalLightOutput
    case overallFailureCondition
    case pollenConcentration
    case presentIndoorRelativeHumidity
    case presentOutdoorRelativeHumidity
    case pressure
    case rainfall
    case ratedMedianUsefulLifeOfLuminaire
    case ratedMedianUsefulLightSourceStarts
    case referenceTemperature
    case totalDeviceStarts
    case trueWindDirection
    case trueWindSpeed
    case uVIndex
    case windChill
    case lightSourceType
    case luminaireIdentificationString
    case outputPowerLimitation
    case thermalDerating
    case outputCurrentPercent
    case unknown(UInt16)
    
    init(_ id: UInt16) {
        switch id {
        case 0x0001: self = .averageAmbientTemperatureInAPeriodOfDay
        case 0x0002: self = .averageInputCurrent
        case 0x0003: self = .averageInputVoltage
        case 0x0004: self = .averageOutputCurrent
        case 0x0005: self = .averageOutputVoltage
        case 0x0006: self = .centerBeamIntensityAtFullPower
        case 0x0007: self = .chromaticityTolerance
        case 0x0008: self = .colorRenderingIndexR9
        case 0x0009: self = .colorRenderingIndexRa
        case 0x000A: self = .deviceAppearance
        case 0x000B: self = .deviceCountryOfOrigin
        case 0x000C: self = .deviceDateOfManufacture
        case 0x000D: self = .deviceEnergyUseSinceTurnOn
        case 0x000E: self = .deviceFirmwareRevision
        case 0x000F: self = .deviceGlobalTradeItemNumber
        case 0x0010: self = .deviceHardwareRevision
        case 0x0011: self = .deviceManufacturerName
        case 0x0012: self = .deviceModelNumber
        case 0x0013: self = .deviceOperatingTemperatureRangeSpecification
        case 0x0014: self = .deviceOperatingTemperatureStatisticalValues
        case 0x0015: self = .deviceOverTemperatureEventStatistics
        case 0x0016: self = .devicePowerRangeSpecification
        case 0x0017: self = .deviceRuntimeSinceTurnOn
        case 0x0018: self = .deviceRuntimeWarranty
        case 0x0019: self = .deviceSerialNumber
        case 0x001A: self = .deviceSoftwareRevision
        case 0x001B: self = .deviceUnderTemperatureEventStatistics
        case 0x001C: self = .indoorAmbientTemperatureStatisticalValues
        case 0x001D: self = .initialCIE1931ChromaticityCoordinates
        case 0x001E: self = .initialCorrelatedColorTemperature
        case 0x001F: self = .initialLuminousFlux
        case 0x0020: self = .initialPlanckianDistance
        case 0x0021: self = .inputCurrentRangeSpecification
        case 0x0022: self = .inputCurrentStatistics
        case 0x0023: self = .inputOverCurrentEventStatistics
        case 0x0024: self = .inputOverRippleVoltageEventStatistics
        case 0x0025: self = .inputOverVoltageEventStatistics
        case 0x0026: self = .inputUnderCurrentEventStatistics
        case 0x0027: self = .inputUnderVoltageEventStatistics
        case 0x0028: self = .inputVoltageRangeSpecification
        case 0x0029: self = .inputVoltageRippleSpecification
        case 0x002A: self = .inputVoltageStatistics
        case 0x002B: self = .lightControlAmbientLuxLevelOn
        case 0x002C: self = .lightControlAmbientLuxLevelProlong
        case 0x002D: self = .lightControlAmbientLuxLevelStandby
        case 0x002E: self = .lightControlLightnessOn
        case 0x002F: self = .lightControlLightnessProlong
        case 0x0030: self = .lightControlLightnessStandby
        case 0x0031: self = .lightControlRegulatorAccuracy
        case 0x0032: self = .lightControlRegulatorKid
        case 0x0033: self = .lightControlRegulatorKiu
        case 0x0034: self = .lightControlRegulatorKpd
        case 0x0035: self = .lightControlRegulatorKpu
        case 0x0036: self = .lightControlTimeFade
        case 0x0037: self = .lightControlTimeFadeOn
        case 0x0038: self = .lightControlTimeFadeStandbyAuto
        case 0x0039: self = .lightControlTimeFadeStandbyManual
        case 0x003A: self = .lightControlTimeOccupancyDelay
        case 0x003B: self = .lightControlTimeProlong
        case 0x003C: self = .lightControlTimeRunOn
        case 0x003D: self = .lumenMaintenanceFactor
        case 0x003E: self = .luminousEfficacy
        case 0x003F: self = .luminousEnergySinceTurnOn
        case 0x0040: self = .luminousExposure
        case 0x0041: self = .luminousFluxRange
        case 0x0042: self = .motionSensed
        case 0x0043: self = .motionThreshold
        case 0x0044: self = .openCircuitEventStatistics
        case 0x0045: self = .outdoorStatisticalValues
        case 0x0046: self = .outputCurrentRange
        case 0x0047: self = .outputCurrentStatistics
        case 0x0048: self = .outputRippleVoltageSpecification
        case 0x0049: self = .outputVoltageRange
        case 0x004A: self = .outputVoltageStatistics
        case 0x004B: self = .overOutputRippleVoltageEventStatistics
        case 0x004C: self = .peopleCount
        case 0x004D: self = .presenceDetected
        case 0x004E: self = .presentAmbientLightLevel
        case 0x004F: self = .presentAmbientTemperature
        case 0x0050: self = .presentCIE1931ChromaticityCoordinates
        case 0x0051: self = .presentCorrelatedColorTemperature
        case 0x0052: self = .presentDeviceInputPower
        case 0x0053: self = .presentDeviceOperatingEfficiency
        case 0x0054: self = .presentDeviceOperatingTemperature
        case 0x0055: self = .presentIlluminance
        case 0x0056: self = .presentIndoorAmbientTemperature
        case 0x0057: self = .presentInputCurrent
        case 0x0058: self = .presentInputRippleVoltage
        case 0x0059: self = .presentInputVoltage
        case 0x005A: self = .presentLuminousFlux
        case 0x005B: self = .presentOutdoorAmbientTemperature
        case 0x005C: self = .presentOutputCurrent
        case 0x005D: self = .presentOutputVoltage
        case 0x005E: self = .presentPlanckianDistance
        case 0x005F: self = .presentRelativeOutputRippleVoltage
        case 0x0060: self = .relativeDeviceEnergyUseInAPeriodOfDay
        case 0x0061: self = .relativeDeviceRuntimeInAGenericLevelRange
        case 0x0062: self = .relativeExposureTimeInAnIlluminanceRange
        case 0x0063: self = .relativeRuntimeInACorrelatedColorTemperatureRange
        case 0x0064: self = .relativeRuntimeInADeviceOperatingTemperatureRange
        case 0x0065: self = .relativeRuntimeInAnInputCurrentRange
        case 0x0066: self = .relativeRuntimeInAnInputVoltageRange
        case 0x0067: self = .shortCircuitEventStatistics
        case 0x0068: self = .timeSinceMotionSensed
        case 0x0069: self = .timeSincePresenceDetected
        case 0x006A: self = .totalDeviceEnergyUse
        case 0x006B: self = .totalDeviceOffOnCycles
        case 0x006C: self = .totalDevicePowerOnCycles
        case 0x006D: self = .totalDevicePowerOnTime
        case 0x006E: self = .totalDeviceRuntime
        case 0x006F: self = .totalLightExposureTime
        case 0x0070: self = .totalLuminousEnergy
        case 0x0071: self = .desiredAmbientTemperature
        case 0x0072: self = .preciseTotalDeviceEnergyUse
        case 0x0073: self = .powerFactor
        case 0x0074: self = .sensorGain
        case 0x0075: self = .precisePresentAmbientTemperature
        case 0x0076: self = .presentAmbientRelativeHumidity
        case 0x0077: self = .presentAmbientCarbonDioxideConcentration
        case 0x0078: self = .presentAmbientVolatileOrganicCompoundsConcentration
        case 0x0079: self = .presentAmbientNoise
        case 0x0080: self = .activeEnergyLoadside
        case 0x0081: self = .activePowerLoadside
        case 0x0082: self = .airPressure
        case 0x0083: self = .apparentEnergy
        case 0x0084: self = .apparentPower
        case 0x0085: self = .apparentWindDirection
        case 0x0086: self = .apparentWindSpeed
        case 0x0087: self = .dewPoint
        case 0x0088: self = .externalSupplyVoltage
        case 0x0089: self = .externalSupplyVoltageFrequency
        case 0x008A: self = .gustFactor
        case 0x008B: self = .heatIndex
        case 0x008C: self = .lightDistribution
        case 0x008D: self = .lightSourceCurrent
        case 0x008E: self = .lightSourceOnTimeNotResettable
        case 0x008F: self = .lightSourceOnTimeResettable
        case 0x0090: self = .lightSourceOpenCircuitStatistics
        case 0x0091: self = .lightSourceOverallFailuresStatistics
        case 0x0092: self = .lightSourceShortCircuitStatistics
        case 0x0093: self = .lightSourceStartCounterResettable
        case 0x0094: self = .lightSourceTemperature
        case 0x0095: self = .lightSourceThermalDeratingStatistics
        case 0x0096: self = .lightSourceThermalShutdownStatistics
        case 0x0097: self = .lightSourceTotalPowerOnCycles
        case 0x0098: self = .lightSourceVoltage
        case 0x0099: self = .luminaireColor
        case 0x009A: self = .luminaireIdentificationNumber
        case 0x009B: self = .luminaireManufacturerGTIN
        case 0x009C: self = .luminaireNominalInputPower
        case 0x009D: self = .luminaireNominalMaximumACMainsVoltage
        case 0x009E: self = .luminaireNominalMinimumACMainsVoltage
        case 0x009F: self = .luminairePowerAtMinimumDimLevel
        case 0x00A0: self = .luminaireTimeOfManufacture
        case 0x00A1: self = .magneticDeclination
        case 0x00A2: self = .magneticFluxDensity2D
        case 0x00A3: self = .magneticFluxDensity3D
        case 0x00A4: self = .nominalLightOutput
        case 0x00A5: self = .overallFailureCondition
        case 0x00A6: self = .pollenConcentration
        case 0x00A7: self = .presentIndoorRelativeHumidity
        case 0x00A8: self = .presentOutdoorRelativeHumidity
        case 0x00A9: self = .pressure
        case 0x00AA: self = .rainfall
        case 0x00AB: self = .ratedMedianUsefulLifeOfLuminaire
        case 0x00AC: self = .ratedMedianUsefulLightSourceStarts
        case 0x00AD: self = .referenceTemperature
        case 0x00AE: self = .totalDeviceStarts
        case 0x00AF: self = .trueWindDirection
        case 0x00B0: self = .trueWindSpeed
        case 0x00B1: self = .uVIndex
        case 0x00B2: self = .windChill
        case 0x00B3: self = .lightSourceType
        case 0x00B4: self = .luminaireIdentificationString
        case 0x00B5: self = .outputPowerLimitation
        case 0x00B6: self = .thermalDerating
        case 0x00B7: self = .outputCurrentPercent
        default:     self = .unknown(id)
        }
    }
    
    /// The Property ID.
    public var id: UInt16 {
        switch self {
        case .averageAmbientTemperatureInAPeriodOfDay: return 0x0001
        case .averageInputCurrent: return 0x0002
        case .averageInputVoltage: return 0x0003
        case .averageOutputCurrent: return 0x0004
        case .averageOutputVoltage: return 0x0005
        case .centerBeamIntensityAtFullPower: return 0x0006
        case .chromaticityTolerance: return 0x0007
        case .colorRenderingIndexR9: return 0x0008
        case .colorRenderingIndexRa: return 0x0009
        case .deviceAppearance: return 0x000A
        case .deviceCountryOfOrigin: return 0x000B
        case .deviceDateOfManufacture: return 0x000C
        case .deviceEnergyUseSinceTurnOn: return 0x000D
        case .deviceFirmwareRevision: return 0x000E
        case .deviceGlobalTradeItemNumber: return 0x000F
        case .deviceHardwareRevision: return 0x0010
        case .deviceManufacturerName: return 0x0011
        case .deviceModelNumber: return 0x0012
        case .deviceOperatingTemperatureRangeSpecification: return 0x0013
        case .deviceOperatingTemperatureStatisticalValues: return 0x0014
        case .deviceOverTemperatureEventStatistics: return 0x0015
        case .devicePowerRangeSpecification: return 0x0016
        case .deviceRuntimeSinceTurnOn: return 0x0017
        case .deviceRuntimeWarranty: return 0x0018
        case .deviceSerialNumber: return 0x0019
        case .deviceSoftwareRevision: return 0x001A
        case .deviceUnderTemperatureEventStatistics: return 0x001B
        case .indoorAmbientTemperatureStatisticalValues: return 0x001C
        case .initialCIE1931ChromaticityCoordinates: return 0x001D
        case .initialCorrelatedColorTemperature: return 0x001E
        case .initialLuminousFlux: return 0x001F
        case .initialPlanckianDistance: return 0x0020
        case .inputCurrentRangeSpecification: return 0x0021
        case .inputCurrentStatistics: return 0x0022
        case .inputOverCurrentEventStatistics: return 0x0023
        case .inputOverRippleVoltageEventStatistics: return 0x0024
        case .inputOverVoltageEventStatistics: return 0x0025
        case .inputUnderCurrentEventStatistics: return 0x0026
        case .inputUnderVoltageEventStatistics: return 0x0027
        case .inputVoltageRangeSpecification: return 0x0028
        case .inputVoltageRippleSpecification: return 0x0029
        case .inputVoltageStatistics: return 0x002A
        case .lightControlAmbientLuxLevelOn: return 0x002B
        case .lightControlAmbientLuxLevelProlong: return 0x002C
        case .lightControlAmbientLuxLevelStandby: return 0x002D
        case .lightControlLightnessOn: return 0x002E
        case .lightControlLightnessProlong: return 0x002F
        case .lightControlLightnessStandby: return 0x0030
        case .lightControlRegulatorAccuracy: return 0x0031
        case .lightControlRegulatorKid: return 0x0032
        case .lightControlRegulatorKiu: return 0x0033
        case .lightControlRegulatorKpd: return 0x0034
        case .lightControlRegulatorKpu: return 0x0035
        case .lightControlTimeFade: return 0x0036
        case .lightControlTimeFadeOn: return 0x0037
        case .lightControlTimeFadeStandbyAuto: return 0x0038
        case .lightControlTimeFadeStandbyManual: return 0x0039
        case .lightControlTimeOccupancyDelay: return 0x003A
        case .lightControlTimeProlong: return 0x003B
        case .lightControlTimeRunOn: return 0x003C
        case .lumenMaintenanceFactor: return 0x003D
        case .luminousEfficacy: return 0x003E
        case .luminousEnergySinceTurnOn: return 0x003F
        case .luminousExposure: return 0x0040
        case .luminousFluxRange: return 0x0041
        case .motionSensed: return 0x0042
        case .motionThreshold: return 0x0043
        case .openCircuitEventStatistics: return 0x0044
        case .outdoorStatisticalValues: return 0x0045
        case .outputCurrentRange: return 0x0046
        case .outputCurrentStatistics: return 0x0047
        case .outputRippleVoltageSpecification: return 0x0048
        case .outputVoltageRange: return 0x0049
        case .outputVoltageStatistics: return 0x004A
        case .overOutputRippleVoltageEventStatistics: return 0x004B
        case .peopleCount: return 0x004C
        case .presenceDetected: return 0x004D
        case .presentAmbientLightLevel: return 0x004E
        case .presentAmbientTemperature: return 0x004F
        case .presentCIE1931ChromaticityCoordinates: return 0x0050
        case .presentCorrelatedColorTemperature: return 0x0051
        case .presentDeviceInputPower: return 0x0052
        case .presentDeviceOperatingEfficiency: return 0x0053
        case .presentDeviceOperatingTemperature: return 0x0054
        case .presentIlluminance: return 0x0055
        case .presentIndoorAmbientTemperature: return 0x0056
        case .presentInputCurrent: return 0x0057
        case .presentInputRippleVoltage: return 0x0058
        case .presentInputVoltage: return 0x0059
        case .presentLuminousFlux: return 0x005A
        case .presentOutdoorAmbientTemperature: return 0x005B
        case .presentOutputCurrent: return 0x005C
        case .presentOutputVoltage: return 0x005D
        case .presentPlanckianDistance: return 0x005E
        case .presentRelativeOutputRippleVoltage: return 0x005F
        case .relativeDeviceEnergyUseInAPeriodOfDay: return 0x0060
        case .relativeDeviceRuntimeInAGenericLevelRange: return 0x0061
        case .relativeExposureTimeInAnIlluminanceRange: return 0x0062
        case .relativeRuntimeInACorrelatedColorTemperatureRange: return 0x0063
        case .relativeRuntimeInADeviceOperatingTemperatureRange: return 0x0064
        case .relativeRuntimeInAnInputCurrentRange: return 0x0065
        case .relativeRuntimeInAnInputVoltageRange: return 0x0066
        case .shortCircuitEventStatistics: return 0x0067
        case .timeSinceMotionSensed: return 0x0068
        case .timeSincePresenceDetected: return 0x0069
        case .totalDeviceEnergyUse: return 0x006A
        case .totalDeviceOffOnCycles: return 0x006B
        case .totalDevicePowerOnCycles: return 0x006C
        case .totalDevicePowerOnTime: return 0x006D
        case .totalDeviceRuntime: return 0x006E
        case .totalLightExposureTime: return 0x006F
        case .totalLuminousEnergy: return 0x0070
        case .desiredAmbientTemperature: return 0x0071
        case .preciseTotalDeviceEnergyUse: return 0x0072
        case .powerFactor: return 0x0073
        case .sensorGain: return 0x0074
        case .precisePresentAmbientTemperature: return 0x0075
        case .presentAmbientRelativeHumidity: return 0x0076
        case .presentAmbientCarbonDioxideConcentration: return 0x0077
        case .presentAmbientVolatileOrganicCompoundsConcentration: return 0x0078
        case .presentAmbientNoise: return 0x0079
     // case these are undefined in Mesh Device Properties v2 = 0x007A
     // case these are undefined in Mesh Device Properties v2 = 0x007B
     // case these are undefined in Mesh Device Properties v2 = 0x007C
     // case these are undefined in Mesh Device Properties v2 = 0x007D
     // case these are undefined in Mesh Device Properties v2 = 0x007E
     // case these are undefined in Mesh Device Properties v2 = 0x007F
        case .activeEnergyLoadside: return 0x0080
        case .activePowerLoadside: return 0x0081
        case .airPressure: return 0x0082
        case .apparentEnergy: return 0x0083
        case .apparentPower: return 0x0084
        case .apparentWindDirection: return 0x0085
        case .apparentWindSpeed: return 0x0086
        case .dewPoint: return 0x0087
        case .externalSupplyVoltage: return 0x0088
        case .externalSupplyVoltageFrequency: return 0x0089
        case .gustFactor: return 0x008A
        case .heatIndex: return 0x008B
        case .lightDistribution: return 0x008C
        case .lightSourceCurrent: return 0x008D
        case .lightSourceOnTimeNotResettable: return 0x008E
        case .lightSourceOnTimeResettable: return 0x008F
        case .lightSourceOpenCircuitStatistics: return 0x0090
        case .lightSourceOverallFailuresStatistics: return 0x0091
        case .lightSourceShortCircuitStatistics: return 0x0092
        case .lightSourceStartCounterResettable: return 0x0093
        case .lightSourceTemperature: return 0x0094
        case .lightSourceThermalDeratingStatistics: return 0x0095
        case .lightSourceThermalShutdownStatistics: return 0x0096
        case .lightSourceTotalPowerOnCycles: return 0x0097
        case .lightSourceVoltage: return 0x0098
        case .luminaireColor: return 0x0099
        case .luminaireIdentificationNumber: return 0x009A
        case .luminaireManufacturerGTIN: return 0x009B
        case .luminaireNominalInputPower: return 0x009C
        case .luminaireNominalMaximumACMainsVoltage: return 0x009D
        case .luminaireNominalMinimumACMainsVoltage: return 0x009E
        case .luminairePowerAtMinimumDimLevel: return 0x009F
        case .luminaireTimeOfManufacture: return 0x00A0
        case .magneticDeclination: return 0x00A1
        case .magneticFluxDensity2D: return 0x00A2
        case .magneticFluxDensity3D: return 0x00A3
        case .nominalLightOutput: return 0x00A4
        case .overallFailureCondition: return 0x00A5
        case .pollenConcentration: return 0x00A6
        case .presentIndoorRelativeHumidity: return 0x00A7
        case .presentOutdoorRelativeHumidity: return 0x00A8
        case .pressure: return 0x00A9
        case .rainfall: return 0x00AA
        case .ratedMedianUsefulLifeOfLuminaire: return 0x00AB
        case .ratedMedianUsefulLightSourceStarts: return 0x00AC
        case .referenceTemperature: return 0x00AD
        case .totalDeviceStarts: return 0x00AE
        case .trueWindDirection: return 0x00AF
        case .trueWindSpeed: return 0x00B0
        case .uVIndex: return 0x00B1
        case .windChill: return 0x00B2
        case .lightSourceType: return 0x00B3
        case .luminaireIdentificationString: return 0x00B4
        case .outputPowerLimitation: return 0x00B5
        case .thermalDerating: return 0x00B6
        case .outputCurrentPercent: return 0x00B7
        case .unknown(let id): return id
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
        case .unknown(let id): return "Unknown (Property ID: \(id))"
        }
    }
    
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
             .presentOutdoorAmbientTemperature,
             .uVIndex:
            return 1
            
        case .lightControlLightnessOn,
             .lightControlLightnessProlong,
             .lightControlLightnessStandby,
             .peopleCount,
             .presentAmbientCarbonDioxideConcentration,
             .presentAmbientRelativeHumidity,
             .presentAmbientVolatileOrganicCompoundsConcentration,
             .presentIndoorRelativeHumidity,
             .presentInputCurrent,
             .presentOutdoorRelativeHumidity,
             .presentOutputCurrent,
             .presentDeviceOperatingTemperature,
             .precisePresentAmbientTemperature,
             .timeSinceMotionSensed,
             .timeSincePresenceDetected,
             .luminaireNominalMaximumACMainsVoltage,
             .luminaireNominalMinimumACMainsVoltage,
             .presentInputVoltage,
             .presentOutputVoltage,
             .rainfall:
            return 2
            
        case .activePowerLoadside,
             .apparentPower,
             .averageInputCurrent,
             .averageInputVoltage,
             .averageOutputCurrent,
             .averageOutputVoltage,
             .deviceDateOfManufacture,
             .deviceEnergyUseSinceTurnOn,
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
             .lightSourceCurrent,
             .lightSourceVoltage,
             .lightSourceStartCounterResettable,
             .lightSourceTotalPowerOnCycles,
             .luminaireNominalInputPower,
             .luminairePowerAtMinimumDimLevel,
             .luminaireTimeOfManufacture,
             .presentAmbientLightLevel,
             .presentDeviceInputPower,
             .presentIlluminance,
             .ratedMedianUsefulLightSourceStarts,
             .ratedMedianUsefulLifeOfLuminaire,
             .totalDeviceEnergyUse:
            return 3
            
        case .activeEnergyLoadside,
             .apparentEnergy,
             .airPressure,
             .preciseTotalDeviceEnergyUse,
             .pressure,
             .lightControlRegulatorKid,
             .lightControlRegulatorKiu,
             .lightControlRegulatorKpd,
             .lightControlRegulatorKpu,
             .sensorGain:
            return 4
            
        case .deviceOverTemperatureEventStatistics,
             .deviceUnderTemperatureEventStatistics,
             .inputOverCurrentEventStatistics,
             .inputOverRippleVoltageEventStatistics,
             .inputOverVoltageEventStatistics,
             .inputUnderCurrentEventStatistics,
             .inputUnderVoltageEventStatistics,
             .lightSourceOpenCircuitStatistics,
             .lightSourceOverallFailuresStatistics,
             .lightSourceShortCircuitStatistics,
             .lightSourceThermalDeratingStatistics,
             .lightSourceThermalShutdownStatistics,
             .openCircuitEventStatistics,
             .outputPowerLimitation,
             .overOutputRippleVoltageEventStatistics,
             .overallFailureCondition,
             .shortCircuitEventStatistics,
             .thermalDerating:
            return 6
            
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
    /// If the given length is 0, the returned characterisitc will be returned with default
    /// value (false, 0, etc.).
    ///
    /// - important: This method does not ensure that the length of data is sufficient.
    ///
    /// - parameters:
    ///   - data:   The data to be read from.
    ///   - offset: The offset.
    ///   - length: Expected length of the data. If 0, the characteristic will be returned
    ///             with default value.
    /// - returns: The characteristic value.
    func read(from data: Data, at offset: Int, length: Int) -> DevicePropertyCharacteristic {
        switch self {
        // UInt8 -> UInt8
        case .uVIndex:
            guard length == valueLength else { return .uvIndex(0) }
            return .uvIndex(data[offset])
            
        // UInt8 -> Bool
        case .presenceDetected:
            guard length == valueLength else { return .bool(false) }
            return .bool(data[offset].toBool())
        
        // 2 x UInt16 + 2 x UInt8 -> Event Statistics
        case .deviceOverTemperatureEventStatistics,
             .deviceUnderTemperatureEventStatistics,
             .inputOverCurrentEventStatistics,
             .inputOverRippleVoltageEventStatistics,
             .inputOverVoltageEventStatistics,
             .inputUnderCurrentEventStatistics,
             .inputUnderVoltageEventStatistics,
             .lightSourceOpenCircuitStatistics,
             .lightSourceOverallFailuresStatistics,
             .lightSourceShortCircuitStatistics,
             .lightSourceThermalDeratingStatistics,
             .lightSourceThermalShutdownStatistics,
             .openCircuitEventStatistics,
             .outputPowerLimitation,
             .overOutputRippleVoltageEventStatistics,
             .overallFailureCondition,
             .shortCircuitEventStatistics,
             .thermalDerating:
            guard length == valueLength else { return .eventStatistics(nil, averageEventDuration: nil, timeElapsedSinceLastEvent: nil, sensingDuration: nil) }
            let count: UInt16? = (data.read(fromOffset: offset) as UInt16).withUnknownValue(0xFFFF)
            let averageEventDuration: UInt16? = (data.read(fromOffset: offset + 2) as UInt16).withUnknownValue(0xFFFF)
            let timeElapsedSinceLastEvent: TimeExponential = .rawValue(data[offset + 4])
            let sensingDuration: TimeExponential = .rawValue(data[offset + 5])
            return .eventStatistics(count,
                                    averageEventDuration: averageEventDuration,
                                    timeElapsedSinceLastEvent: timeElapsedSinceLastEvent,
                                    sensingDuration: sensingDuration)
            
        // UInt8 -> Float?
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
            guard length == valueLength else { return .percentage8(nil) }
            return .percentage8(data[offset].toDecimal(withRange: 0...100, withResolution: 0.5, withUnknownValue: 0xFF))
            
        // Int8 -> Float?
        case .desiredAmbientTemperature,
             .presentAmbientTemperature,
             .presentIndoorAmbientTemperature,
             .presentOutdoorAmbientTemperature:
            guard length == valueLength else { return .temperature8(nil) }
            let value: Int8 = Int8(bitPattern: data[offset])
            return .temperature8(value.toDecimal(withRange: -64.0...63.0, withResolution: 0.5, withUnknownValue: 0x7F))
            
        // UInt16 -> UInt16
        case .lightControlLightnessOn,
             .lightControlLightnessProlong,
             .lightControlLightnessStandby:
            guard length == valueLength else { return .perceivedLightness(0) }
            return .perceivedLightness(data.read(fromOffset: offset))
        case .rainfall:
            guard length == valueLength else { return .rainfall(0) }
            return .rainfall(data.read(fromOffset: offset))
            
        // UInt16 -> UInt16?
        case .peopleCount:
            guard length == valueLength else { return .count16(nil) }
            let count: UInt16 = data.read(fromOffset: offset)
            return .count16(count.withUnknownValue(0xFFFF))
        case .timeSinceMotionSensed,
             .timeSincePresenceDetected:
            guard length == valueLength else { return .timeSecond16(nil) }
            let value: UInt16 = data.read(fromOffset: offset)
            return .timeSecond16(value.withUnknownValue(0xFFFF))
        case .presentAmbientCarbonDioxideConcentration:
            guard length == valueLength else { return .co2Concentration(nil) }
            let value: UInt16 = data.read(fromOffset: offset)
            return .co2Concentration(value.withUnknownValue(0xFFFF))
        case .presentAmbientVolatileOrganicCompoundsConcentration:
            guard length == valueLength else { return .vocConcentration(nil) }
            let value: UInt16 = data.read(fromOffset: offset)
            return .vocConcentration(value.withUnknownValue(0xFFFF))
        
        // UInt16 -> Decimal?
        case .presentAmbientRelativeHumidity,
             .presentIndoorRelativeHumidity,
             .presentOutdoorRelativeHumidity:
            guard length == valueLength else { return .humidity(nil) }
            let value: UInt16 = data.read(fromOffset: offset)
            return .humidity(value.toDecimal(withRange: 0.0...100.0, withResolution: 0.01, withUnknownValue: 0xFFFF))
        case .presentOutputCurrent,
             .presentInputCurrent:
            guard length == valueLength else { return .electricCurrent(nil) }
            let value: UInt16 = data.read(fromOffset: offset)
            return .electricCurrent(value.toDecimal(withRange: 0.0...655.34, withResolution: 0.01, withUnknownValue: 0xFFFF))
        case .averageInputCurrent,
             .averageOutputCurrent,
             .lightSourceCurrent:
            guard length == valueLength else { return .averageCurrent(nil, sensingDuration: nil) }
            let value: UInt16 = data.read(fromOffset: offset)
            let n: UInt8 = data[offset + 2]
            return .averageCurrent(
                value.toDecimal(withRange: 0.0...655.34, withResolution: 0.01, withUnknownValue: 0xFFFF),
                sensingDuration: TimeExponential.from(rawValue: n))
            
        case .luminaireNominalMaximumACMainsVoltage,
             .luminaireNominalMinimumACMainsVoltage,
             .presentInputVoltage,
             .presentOutputVoltage:
            guard length == valueLength else { return .voltage(nil) }
            let value: UInt16 = data.read(fromOffset: offset)
            let resolution = Decimal(sign: .plus, exponent: -6, significand: 15625)
            return .voltage(value.toDecimal(withRange: 0.0...1022.0, withResolution: resolution, withUnknownValue: 0xFFFF))
        case .averageInputVoltage,
             .averageOutputVoltage,
             .lightSourceVoltage:
            guard length == valueLength else { return .averageVoltage(nil, sensingDuration: nil) }
            let value: UInt16 = data.read(fromOffset: offset)
            let n: UInt8 = data[offset + 2]
            let resolution = Decimal(sign: .plus, exponent: -6, significand: 15625)
            return .averageVoltage(
                value.toDecimal(withRange: 0.0...1022.0, withResolution: resolution, withUnknownValue: 0xFFFF),
                sensingDuration: TimeExponential.from(rawValue: n))
            
        // Int16 -> Decimal?
        case .precisePresentAmbientTemperature,
             .presentDeviceOperatingTemperature:
            guard length == valueLength else { return .temperature(nil) }
            let value: Int16 = data.read(fromOffset: offset)
            return .temperature(value.toDecimal(withRange: -273.15...327.67, withResolution: 0.01, withUnknownValue: -32768))
            
        // UInt24 -> Decimal?
        case .lightControlAmbientLuxLevelOn,
             .lightControlAmbientLuxLevelProlong,
             .lightControlAmbientLuxLevelStandby,
             .presentAmbientLightLevel,
             .presentIlluminance:
            guard length == valueLength else { return .illuminance(nil) }
            let value: UInt32 = data.readUInt24(fromOffset: offset)
            return .illuminance(value.toDecimal(withResolution: 0.01, withUnknownValue: 0xFFFFFF))
        case .activePowerLoadside,
             .luminaireNominalInputPower,
             .luminairePowerAtMinimumDimLevel,
             .presentDeviceInputPower:
          guard length == valueLength else { return .power(nil) }
          let value: UInt32 = data.readUInt24(fromOffset: offset)
          return .power(value.toDecimal(withResolution: 0.1, withUnknownValue: 0xFFFFFF))

        // UInt24 -> UInt24?
        case .lightSourceStartCounterResettable,
             .lightSourceTotalPowerOnCycles,
             .ratedMedianUsefulLightSourceStarts,
             .totalDeviceOffOnCycles,
             .totalDevicePowerOnCycles,
             .totalDeviceStarts:
            guard length == valueLength else { return .count24(nil) }
            let value: UInt32 = data.readUInt24(fromOffset: offset)
            return .count24(value.withUnknownValue(0xFFFFFF))
        case .deviceRuntimeSinceTurnOn,
             .deviceRuntimeWarranty,
             .ratedMedianUsefulLifeOfLuminaire,
             .totalDevicePowerOnTime,
             .totalDeviceRuntime,
             .totalLightExposureTime:
            guard length == valueLength else { return .timeHour24(nil) }
            let value: UInt32 = data.readUInt24(fromOffset: offset)
            return .timeHour24(value.withUnknownValue(0xFFFFFF))
        case .lightControlTimeFade,
             .lightControlTimeFadeOn,
             .lightControlTimeFadeStandbyAuto,
             .lightControlTimeFadeStandbyManual,
             .lightControlTimeOccupancyDelay,
             .lightControlTimeProlong,
             .lightControlTimeRunOn:
            guard length == valueLength else { return .timeMillisecond24(nil) }
            let value: UInt32 = data.readUInt24(fromOffset: offset)
            return .timeMillisecond24(value.withUnknownValue(0xFFFFFF))
        case .deviceEnergyUseSinceTurnOn,
             .totalDeviceEnergyUse:
            guard length == valueLength else { return .energy(nil) }
            let value: UInt32 = data.readUInt24(fromOffset: offset)
            return .energy(value.withUnknownValue(0xFFFFFF))
            
        // UInt24 -> Date?
        case .deviceDateOfManufacture,
             .luminaireTimeOfManufacture:
            guard length == valueLength else { return .dateUTC(nil) }
            let numberOfDays = data.readUInt24(fromOffset: offset)
            guard numberOfDays != 0 else { return .dateUTC(nil) }
            let timeInterval = TimeInterval(numberOfDays) * 86400.0
            return .dateUTC(Date(timeIntervalSince1970: timeInterval))
            
        // UInt32 -> Decimal
        case .pressure,
             .airPressure:
            guard length == valueLength else { return .pressure(0) }
            let value: UInt32 = data.read(fromOffset: offset)
            return .pressure(value.toDecimal(withResolution: 0.1))
            
        // UInt24 -> ValidDecimal?
        case .apparentPower:
            guard length == valueLength else { return .apparentPower(nil) }
            let value: UInt32 = data.readUInt24(fromOffset: offset)
            
            guard value != UInt32(0xFFFFFF) else { return .apparentPower(nil) }
            guard value != UInt32(0xFFFFFE) else { return .apparentPower(.invalid) }
            return .apparentPower(.valid(Decimal(sign: .plus, exponent: -1, significand: Decimal(value))))

        // UInt32 -> ValidDecimal?
        case .preciseTotalDeviceEnergyUse,
             .activeEnergyLoadside:
            guard length == valueLength else { return .energy32(nil) }
            let value: UInt32 = data.read(fromOffset: offset)
            
            guard value != UInt32(0xFFFFFFFF) else { return .energy32(nil) }
            guard value != UInt32(0xFFFFFFFE) else { return .energy32(.invalid) }
            return .energy32(.valid(Decimal(sign: .plus, exponent: -3, significand: Decimal(value))))
            
        case .apparentEnergy:
            guard length == valueLength else { return .apparentEnergy32(nil) }
            let value: UInt32 = data.read(fromOffset: offset)
            
            guard value != UInt32(0xFFFFFFFF) else { return .apparentEnergy32(nil) }
            guard value != UInt32(0xFFFFFFFE) else { return .apparentEnergy32(.invalid) }
            return .apparentEnergy32(.valid(Decimal(sign: .plus, exponent: -3, significand: Decimal(value))))

        // Float32 (IEEE 754)
        case .lightControlRegulatorKid,
             .lightControlRegulatorKiu,
             .lightControlRegulatorKpd,
             .lightControlRegulatorKpu,
             .sensorGain:
            guard length == valueLength else { return .coefficient(0.0) }
            let asInt32: UInt32 = data.read(fromOffset: offset)
            return .coefficient(Float(bitPattern: asInt32))
            
        // String
        case .deviceFirmwareRevision,
             .deviceSoftwareRevision:
            guard length == valueLength else { return .fixedString8(String(repeating: " ", count: 8)) }
            return .fixedString8(String(data: data.subdata(in: offset..<offset + 8), encoding: .utf8)!)
        case .deviceHardwareRevision,
             .deviceSerialNumber:
            guard length == valueLength else { return .fixedString16(String(repeating: " ", count: 16)) }
            return .fixedString16(String(data: data.subdata(in: offset..<offset + 16), encoding: .utf8)!)
        case .deviceModelNumber,
             .luminaireColor,
             .luminaireIdentificationNumber:
            guard length == valueLength else { return .fixedString24(String(repeating: " ", count: 24)) }
            return .fixedString24(String(data: data.subdata(in: offset..<offset + 24), encoding: .utf8)!)
        case .deviceManufacturerName:
            guard length == valueLength else { return .fixedString36(String(repeating: " ", count: 36)) }
            return .fixedString36(String(data: data.subdata(in: offset..<offset + 36), encoding: .utf8)!)
        case .luminaireIdentificationString:
            guard length == valueLength else { return .fixedString64(String(repeating: " ", count: 64)) }
            return .fixedString64(String(data: data.subdata(in: offset..<offset + 64), encoding: .utf8)!)
            
        // Other
        default:
            return .other(data.subdata(in: offset..<offset + length))
        }
    }
    
}

// MARK: - DevicePropertyCharacteristic

/// An enum representing valid or invalid decimal values.
///
/// - since: 4.0.0
public enum ValidDecimal: Equatable {
    /// The value is valid.
    case valid(Decimal)
    /// The value is invalid.
    case invalid
}

/// The time is represented by the value `1.1^(N–64)` in seconds, with `N` being the raw 8-bit value.
///
/// - since: 4.0.0
public enum TimeExponential: Equatable {
    /// Creates a ``TimeExponential`` object based on the given time.
    ///
    /// As the time is represented as `1.1^(N-64)` it will be ronded to the nearest possible value.
    ///
    /// - parameter seconds: The time in seconds as `TimeInterval`.
    static func interval(_ seconds: TimeInterval) -> TimeExponential {
        switch seconds {
        case 0:
            return .rawValue(0)
        case let s where s > 66560641:
            return .rawValue(0xFD)
        default:
            let x = Int(log(seconds) / log(1.1) + 64)
            guard x > 0 else { return .rawValue(0) }
            return .rawValue(UInt8(x))
        }
    }
    /// Approximate value of the time in seconds.
    ///
    /// As the time is represented as `1.1^(N-64)`, the value will be rounded to nearest lower value.
    case rawValue(UInt8)
    /// The total lifetime of the device.
    case deviceLifetime
    /// Approximate time interval calculated from the raw value.
    ///
    /// - warning: The returned time may differ from the time used to create the object, as the value
    ///            is encoded as `1.1^(N-64)`.
    var interval: TimeInterval? {
        // Special case for "unknown time".
        guard case .rawValue(let n) = self else {
            return nil
        }
        // Special case for 0 seconds.
        if n == 0 {
            return 0.0
        }
        // iOS fails to calculate power with high negative exponent: 1.1^(-49) -> NaN
        // Instead, we calculate inverse of positive power: 1 / 1.1^49, which gives the correct result.
        let number = Decimal(sign: .plus, exponent: -1, significand: 11) // 1.1
        let exponent = Int(n) - 64
        if exponent < 0 {
            let result = pow(number, -exponent)
            return 1.0 / NSDecimalNumber(decimal: result).doubleValue
        } else {
            let result = pow(number, exponent)
            return NSDecimalNumber(decimal: result).doubleValue
        }
    }
    
    fileprivate static func from(rawValue: UInt8) -> TimeExponential? {
        switch rawValue {
        case 0xFE:
            return .deviceLifetime
        case 0xFF:
            return nil
        default:
            return .rawValue(rawValue)
        }
    }
}

/// A representation of a property characteristic.
///
/// The unit of a characteristic is specified in the comment.
///
/// For example, ``DevicePropertyCharacteristic/electricCurrent(_:)`` unit is Ampere
/// with resulution of 0.01 A.
///
/// #### Encoding sample
/// ```swift
/// // The value of the characteristic will be encoded as 0xD204 (12.34).
/// let characteristic: DevicePropertyCharacteristic = .electricCurrent(12.345)
/// ```
/// #### Decoding sample
/// ```swift
/// guard case .electricCurrent(let current) = characteristic else {
///    return
/// }
/// print(current) // -> "12.34 A"
/// ```
public enum DevicePropertyCharacteristic: Equatable {
    /// The integral of Apparent Power over a time interval,
    /// represented in units of kVAh (kilo-volt-ampere-hour).
    ///
    /// Unit is kilo-volt-ampere-hour with resolution of 1 volt-ampere-hour.
    case apparentEnergy32(ValidDecimal?)
    /// Apparent power is the product of the quadratic mean values of voltage and current.
    ///
    /// It is needed for designing and operating power systems, because although the current
    /// associated with reactive power does not work at the load, it is still supplied by the
    /// power source. Apparent power is expressed in volt-amperes (VA) since it is the product
    /// of quadratic mean voltage and quadratic mean current.
    case apparentPower(ValidDecimal?)
    /// This characteristic represents the average Electric Current and the time over which it
    /// was measured.
    ///
    /// Unit of Electric Current is ampere with a resolution of 0.01 A.
    case averageCurrent(Decimal?, sensingDuration: TimeExponential?)
    /// This characteristic represents the average Voltage and the time over which it
    /// was measured.
    ///
    /// Unit of Voltage is volt with a resolution of 1/64 V.
    case averageVoltage(Decimal?, sensingDuration: TimeExponential?)
    /// True or false.
    case bool(Bool)
    /// The Count 16 characteristic is used to represent a general count value.
    case count16(UInt16?)
    /// The Count 24 characteristic is used to represent a general count value.
    case count24(UInt32?)
    /// The Coefficient characteristic is used to represent a general coefficient value.
    case coefficient(Float32)
    /// The CO2 Concentration characteristic is used to represent a measure of carbon dioxide
    /// concentration in units of parts per million.
    ///
    /// Unit is parts per million (ppm) with a resolution of 1.
    ///
    /// A value of 0xFFFE represents ‘value is 65534 or greater’.
    case co2Concentration(UInt16?)
    /// Date as days elapsed since the Epoch (Jan 1, 1970) in the Coordinated Universal
    /// Time (UTC) time zone.
    case dateUTC(Date?)
    /// The Electric Current characteristic is used to represent an electric current value.
    ///
    /// Unit is ampere with a resolution of 0.01 A.
    case electricCurrent(Decimal?)
    /// The Energy characteristic is used to represent a measure of energy in units of kilowatt hours.
    ///
    /// Unit is Kilowatt-hour (kWh) with a resolution of 1.
    case energy(UInt32?)
    /// The Energy32 characteristic is used to represent a energy value.
    ///
    /// Unit is Kilowatt-hour with a resolution of 1 Watt-hour.
    case energy32(ValidDecimal?)
    /// The Event Statistics characteristic is used to represent statistical values of events.
    ///
    /// The value represents number of events with average event duration (in seconds),
    /// time elapsed since the last event and sensing duration.
    case eventStatistics(UInt16?,
                         averageEventDuration: UInt16?,
                         timeElapsedSinceLastEvent: TimeExponential?,
                         sensingDuration: TimeExponential?)
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
    case humidity(Decimal?)
    /// The Illuminance characteristic is used to represent a measure of illuminance
    /// in units of lux with resolution 0.01 lux.
    case illuminance(Decimal?)
    /// The Percentage 8 characteristic is used to represent a measure of percentage.
    ///
    /// Unit is a percentage with resolution 0.5, with allowed range 0..100.
    case percentage8(Decimal?)
    /// The Perceived Lightness characteristic is used to represent the perceived
    /// lightness of a light.
    ///
    /// Unit is unitless with a resolution of 1.
    case perceivedLightness(UInt16)
    /// The Power characteristic is used to represent a power value.
    ///
    /// Unit is in watt with a resolution of 0.1 W.
    case power(Decimal?)
    /// The Pressure characteristic is used to represent a pressure value.
    ///
    /// Unit is in pascals with a resolution of 0.1 Pa.
    case pressure(Decimal)
    /// The Rainfall characteristic is used to represent the amount of rain that has fallen.
    ///
    /// Unit is in millimeters.
    /// - note: In Bluetooth Mesh Device Properties 2 this characteristic is encoded as meters
    ///         with resolution of 0.01 mm. For simplification, in this library use millimeters
    ///         directly.
    case rainfall(UInt16)
    /// The Temperature characteristic is used to represent a temperature is degrees
    /// Celsius with a resolution of 0.01 degrees Celsius.
    ///
    /// Allowed range is: -273.15 to 327.67 degrees Celsius.
    case temperature(Decimal?)
    /// The Temperature 8 characteristic is used to represent a measure of
    /// temperature with a unit of 0.5 degree Celsius.
    case temperature8(Decimal?)
    /// The Time Hour 24 characteristic is used to represent a period of time in hours.
    case timeHour24(UInt32?)
    /// The Time Millisecond 24 characteristic is used to represent a period of time
    /// with a resolution of 1 millisecond.
    case timeMillisecond24(UInt32?)
    /// The Time Second 16 characteristic is used to represent a period of time with
    /// a unit of 1 second.
    case timeSecond16(UInt16?)
    /// The Time Second 32 characteristic is used to represent a period of time with
    /// a unit of 1 second.
    case timeSecond32(UInt32?)
    /// The UV Index characteristic is used to represent the UV Index.
    ///
    /// The value is unitless.
    case uvIndex(UInt8)
    /// The VOC Concentration characteristic is used to represent a measure of volatile
    /// organic compounds concentration in units of parts per billion.
    ///
    /// Unit is parts per billion (ppb) with a resolution of 1.
    ///
    /// A value of 0xFFFE represents ‘value is 65534 or greater’.
    case vocConcentration(UInt16?)
    /// The Voltage characteristic is used to represent a measure of positive electric
    /// potential difference in units of volts with 1/64 V resolution.
    case voltage(Decimal?)
    /// Generic data type for other characteristics.
    case other(Data)
}

internal extension DevicePropertyCharacteristic {
    
    /// The characteristic value as Data.
    var data: Data {
        switch self {
        // Bool:
        case .bool(let value):
            return value.toData()
            
        case .uvIndex(let index):
            return Data([index])
            
        // Event Statistics:
        case .eventStatistics(let count,
                              averageEventDuration: let averageEventDuration,
                              timeElapsedSinceLastEvent: let timeElapsedSinceLastEvent,
                              sensingDuration: let sensingDuration):
            let countCharacteristic: DevicePropertyCharacteristic = .count16(count)
            let averageEventDurationCharacteristic: DevicePropertyCharacteristic = .timeSecond16(averageEventDuration)
            return countCharacteristic.data +
                   averageEventDurationCharacteristic.data +
                   timeElapsedSinceLastEvent.toData() + sensingDuration.toData()
            
        // Decimal? as UInt8 with 0xFF as unknown:
        case .percentage8(let value):
            return value.toData(ofLength: 1, withRange: 0.0...100.0, withResolution: 0.5, withUnknownValue: 0xFF)
            
        // Decimal? as Int8 with 0x7F as unknown (see Errata 15863):
        case .temperature8(let value):
            return value.toData(ofLength: 1, withRange: -64.0...63.0, withResolution: 0.5, withUnknownValue: 0x7F)
            
        // UInt16? with 0xFFFF as unknown:
        case .count16(let value),
             .timeSecond16(let value),
            // and 0xFFFE as greater than 65534:
             .co2Concentration(let value),
             .vocConcentration(let value):
            return value.toData(withUnknownValue: 0xFFFF)
            
        // UInt16:
        case .perceivedLightness(let value):
            return value.toData()
        case .rainfall(let value):
            return value.toData()
            
        // Decimal? as UInt16 with 0xFFFF as unknown:
        case .humidity(let value):
            return value.toData(ofLength: 2, withRange: 0.0...100.0, withResolution: 0.01, withUnknownValue: 0xFFFF)
        
        // Decimal? as UInt16 with 0xFFFF as unknown:
        case .electricCurrent(let value):
            return value.toData(ofLength: 2, withRange: 0...655.34, withResolution: 0.01, withUnknownValue: 0xFFFF)
        case .averageCurrent(let current, let time):
            return current.toData(ofLength: 2, withRange: 0...655.34, withResolution: 0.01, withUnknownValue: 0xFFFF) + time.toData()
            
        // Decimal? as UInt16 with 0xFFFF as unknown:
        case .voltage(let value):
            let resolution = Decimal(sign: .plus, exponent: -6, significand: 15625)
            return value.toData(ofLength: 2, withRange: 0...1022, withResolution: resolution, withUnknownValue: 0xFFFF)
        case .averageVoltage(let voltage, let time):
            let resolution = Decimal(sign: .plus, exponent: -6, significand: 15625)
            return voltage.toData(ofLength: 2, withRange: 0...1022, withResolution: resolution, withUnknownValue: 0xFFFF) + time.toData()
            
        // Decimal? as Int16 with 0x8000 as unknown:
        case .temperature(let value):
            return value.toData(ofLength: 2, withRange: -273.15...327.67, withResolution: 0.01, withUnknownValue: 0x8000)
            
        // UInt32? as UInt24 with 0xFFFFFF as unknown:
        case .count24(let value),
             .timeHour24(let value),
             .timeMillisecond24(let value):
            return value.toData(ofLength: 3, withUnknownValue: 0xFFFFFF)
            
        // Decimal? as UInt24 with 0xFFFFFF as unknown:
        case .illuminance(let value):
            return value.toData(ofLength: 3, withRange: 0...167772.14, withResolution: 0.01, withUnknownValue: 0xFFFFFF)
        case .energy(let value):
            return value.toData(ofLength: 3, withRange: 0...16777214, withUnknownValue: 0xFFFFFF)

        // Decimal? as UInt24 with 0xFFFFFF as unknown:
        case .power(let value):
          return value.toData(ofLength: 3, withRange: 0...1677721.4, withResolution: 0.1, withUnknownValue: 0xFFFFFF)

        // Date as UInt24 with 0x000000 as unknown:
        case .dateUTC(let date):
            guard let date = date else {
                return Data([0x00, 0x00, 0x00])
            }
            let numberOfDays = UInt32(date.timeIntervalSince1970 / 86400.0) // convert to days
            return (Data() + numberOfDays).dropLast()
        
        // Decimal as UInt32:
        case .pressure(let value):
            return value.toData(ofLength: 4, withRange: 0...Decimal(UInt32.max), withResolution: 0.1)
            
        // ValidDecimal? as UInt24 with 0xxFFFFFE as invalid and 0xFFFFFF as unknown:
        case .apparentPower(let value):
            let range = 0...Decimal(sign: .plus, exponent: -1, significand: 16777213)
            return value.toData(ofLength: 3, withRange: range, withResolution: 0.1,
                                withInvalidValue: 0xFFFFFE, andUnknownValue: 0xFFFFFF)

        // ValidDecimal? as UInt32 with 0xFFFFFFFE as invalid and 0xFFFFFFFF as unknown:
        case .energy32(let value),
             .apparentEnergy32(let value):
            let range = 0...Decimal(sign: .plus, exponent: -3, significand: 4294967293)
            return value.toData(ofLength: 4, withRange: range, withResolution: 0.001,
                                withInvalidValue: 0xFFFFFFFE, andUnknownValue: 0xFFFFFFFF)
            
        // UInt32? with 0xFFFFFFFF as unknown:
        case .timeSecond32(let value):
            return value.toData(ofLength: 4, withUnknownValue: 0xFFFFFFFF)
        
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
    /// Value formatter, with max 3 fraction digits.
    private static var formatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 3
        formatter.locale = Locale.current
        return formatter
    }
    /// Text printed when the characteristic value is unknown.
    private static let unknown = "Value is not known"
    /// Text printed when the characteristic value is not valid.
    private static let invalid = "Value is not valid"
    
    public var debugDescription: String {
        switch self {
        // Bool:
        case .bool(let value):
            return value ? "True" : "False"
            
        case .uvIndex(let index):
            return "\(index)"
            
        // Event Statistics:
        case .eventStatistics(let count,
                              averageEventDuration: let averageEventDuration,
                              timeElapsedSinceLastEvent: let timeElapsedSinceLastEvent,
                              sensingDuration: let sensingDuration):
            let countCharacteristic: DevicePropertyCharacteristic = .count16(count)
            let averageEventDurationCharacteristic: DevicePropertyCharacteristic = .timeSecond16(averageEventDuration)
            return "\(countCharacteristic) events, avg. event duration: \(averageEventDurationCharacteristic), time elapsed since last event: \(timeElapsedSinceLastEvent?.description ?? "unknown"), sensing duration: \(sensingDuration?.description ?? "unknown")"
            
        // Decimal:
        case .pressure(let pressure):
            return DevicePropertyCharacteristic.formatter.string(from: pressure, withRange: 0...Decimal(UInt32.max / 10), andUnit: " Pa")
            
        // Decimal?:
        case .percentage8(let percent),
             .humidity(let percent):
            guard let percent = percent else {
                return DevicePropertyCharacteristic.unknown
            }
            return DevicePropertyCharacteristic.formatter.string(from: percent, withRange: 0...100, andUnit: "%")
        case .temperature8(let temp):
            guard let temp = temp else {
                return DevicePropertyCharacteristic.unknown
            }
            return DevicePropertyCharacteristic.formatter.string(from: temp, withRange: -64...63, andUnit: "°C")
        case .electricCurrent(let current):
            guard let current = current else {
                return DevicePropertyCharacteristic.unknown
            }
            return DevicePropertyCharacteristic.formatter.string(from: current, withRange: 0...655.34, andUnit: " A")
        case .averageCurrent(let current, let time):
            guard let current = current else {
                return DevicePropertyCharacteristic.unknown
            }
            let characteristic = DevicePropertyCharacteristic.electricCurrent(current)
            return "\(characteristic) over \(time?.description ?? " an unknown time")"
        case .illuminance(let millilux):
            guard let millilux = millilux else {
                return DevicePropertyCharacteristic.unknown
            }
            return DevicePropertyCharacteristic.formatter.string(from: millilux, withRange: 0...167772.13, andUnit: " lux")
        case .power(let power):
            guard let power = power else {
                return DevicePropertyCharacteristic.unknown
            }
            return DevicePropertyCharacteristic.formatter.string(from: power, withRange: 0...1677721.4, andUnit: " W")
        case .temperature(let temp):
            guard let temp = temp else {
                return DevicePropertyCharacteristic.unknown
            }
            return DevicePropertyCharacteristic.formatter.string(from: temp, withRange: -273.15...327.67, andUnit: "°C")
        case .voltage(let voltage):
            guard let voltage = voltage else {
                return DevicePropertyCharacteristic.unknown
            }
            switch voltage {
            case 0:
                return "0 V or lower"
            case 1022:
                return "1022 V or higher"
            default:
                return DevicePropertyCharacteristic.formatter.string(from: voltage, withRange: 0...1022, andUnit: " V")
            }
        case .averageVoltage(let voltage, let time):
            guard let voltage = voltage else {
                return DevicePropertyCharacteristic.unknown
            }
            let characteristic = DevicePropertyCharacteristic.voltage(voltage)
            return "\(characteristic) over \(time?.description ?? " an unknown time")"
            
        // UInt16:
        case .perceivedLightness(let count):
            return "\(count)"
        case .rainfall(let height):
            return "\(height) mm"
            
        // UInt16?:
        case .count16(let count):
            guard let count = count else {
                return DevicePropertyCharacteristic.unknown
            }
            return "\(count)" // unitless
        case .timeSecond16(let numberOfSeconds):
            guard let numberOfSeconds = numberOfSeconds else {
                return DevicePropertyCharacteristic.unknown
            }
            let interval = TimeInterval(numberOfSeconds)
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.day, .hour, .minute, .second]
            formatter.unitsStyle = .short
            return formatter.string(from: interval)!
        case .co2Concentration(let concentration),
             .vocConcentration(let concentration):
            guard let concentration = concentration else {
                return DevicePropertyCharacteristic.unknown
            }
            if concentration == 0xFFFE {
                return "65534 ppm or more"
            }
            return "\(concentration) ppm"
            
        // UInt32? as UInt24?:
        case .count24(let count):
            guard let count = count else {
                return DevicePropertyCharacteristic.unknown
            }
            return "\(min(count, 0xFFFFFE))" // unitless
        case .timeHour24(let numberOfHours):
            guard let numberOfHours = numberOfHours else {
                return DevicePropertyCharacteristic.unknown
            }
            let interval = TimeInterval(min(numberOfHours, 0xFFFFFE)) * 86400.0
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.month, .day, .hour]
            formatter.unitsStyle = .short
            return formatter.string(from: interval)!
        case .timeMillisecond24(let numberOfMilliseconds):
            guard let numberOfMilliseconds = numberOfMilliseconds else {
                return DevicePropertyCharacteristic.unknown
            }
            let interval = TimeInterval(min(numberOfMilliseconds, 0xFFFFFE)) / 1000.0
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.hour, .minute, .second]
            formatter.unitsStyle = .short
            return formatter.string(from: interval)!
        case .energy(let value):
            guard let value = value else {
                return DevicePropertyCharacteristic.unknown
            }
            return "\(min(value, 0xFFFFFE))) kWh"
            
        // UInt32?:
        case .timeSecond32(let numberOfSeconds):
            guard let numberOfSeconds = numberOfSeconds else {
                return DevicePropertyCharacteristic.unknown
            }
            let interval = TimeInterval(numberOfSeconds)
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.year, .month, .day, .hour, .minute, .second]
            formatter.unitsStyle = .short
            return formatter.string(from: interval)!
        
        // ValidDecimal?:
        case .energy32(let value),
             .apparentEnergy32(let value),
             .apparentPower(let value):
            guard let value = value else {
                return DevicePropertyCharacteristic.unknown
            }
            switch value {
            case .invalid:
                return DevicePropertyCharacteristic.invalid
            case .valid(let value):
                switch self {
                case .energy32:
                    return DevicePropertyCharacteristic.formatter.string(from: value, withRange: 0...Decimal(UInt32.max), andUnit: " kWh")
                case .apparentEnergy32:
                    return DevicePropertyCharacteristic.formatter.string(from: value, withRange: 0...Decimal(UInt32.max), andUnit: " kWAh")
                case .apparentPower:
                    return DevicePropertyCharacteristic.formatter.string(from: value, withRange: 0...1677721.3, andUnit: " VA")
                default:
                    fatalError()
                }
            }
            
        // Date?:
        case .dateUTC(let date):
            guard let date = date else {
                return DevicePropertyCharacteristic.unknown
            }
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            return dateFormatter.string(from: date)
            
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

// MARK: - Helper extenstions - decoding

private extension NumberFormatter {
    
    func string(from decimal: Decimal, withRange range: ClosedRange<Decimal>, andUnit unit: String?) -> String {
        let valueInRange = max(range.lowerBound, min(range.upperBound, decimal))
        if let stringRepresentation = string(from: valueInRange as NSDecimalNumber) {
            if let unit = unit {
                return stringRepresentation + unit
            }
            return stringRepresentation
        }
        if let unit = unit {
            return decimal.description + unit
        }
        return decimal.description
    }
    
}

private extension BinaryInteger {
    
    /// Converts value to Bool.
    ///
    /// 0 is translated to `false`, anything else to`true`.
    ///
    /// - returns: Value as Bool.
    func toBool() -> Bool {
        return self != 0x00
    }
    
    /// Converts the value to Float.
    ///
    /// - parameters:
    ///   - range: The range the value is to be located in.
    ///   - resolution: The convertion resolution.
    /// - returns: The value as Float.
    func toDecimal(withRange range: ClosedRange<Decimal>? = nil,
                   withResolution resolution: Decimal = 1.0) -> Decimal {
        let value = Decimal(integerLiteral: Int(self)) * resolution
        return range.map { Swift.max($0.lowerBound, Swift.min($0.upperBound, value)) } ?? value
    }
    
    /// Converts the value to Float.
    ///
    /// - parameters:
    ///   - range: The range the value is to be located in.
    ///   - resolution: The convertion resolution.
    ///   - unknownValue: The unknown value.
    /// - returns: The value as Float, or `nil` if it matches the unknown value.
    func toDecimal<T: FixedWidthInteger>(withRange range: ClosedRange<Decimal>? = nil,
                                         withResolution resolution: Decimal = 1.0,
                                         withUnknownValue unknownValue: T) -> Decimal? {
        guard self != unknownValue else { return nil }
        return toDecimal(withRange: range, withResolution: resolution)
    }
    
    /// Returns the value, or `nil`, if it's equal to the given value.
    ///
    /// - parameter unknownValue: The unknown value.
    /// - returns: The value, or `nil` if it matches the unknown value.
    func withUnknownValue<T: FixedWidthInteger>(_ unknownValue: T) -> T? {
        guard self != unknownValue else { return nil }
        return self as? T
    }
    
}

// MARK: - Helper extenstions - encoding

private extension Bool {
    
    /// Returns the value as 1-octed Data.
    ///
    /// - returns: The Data representation of Bool.
    func toData() -> Data {
        return Data([self ? 0x01 : 0x00])
    }
    
}

private extension Optional where Wrapped == TimeExponential {
    
    /// Converts the optional ``TimeExponential`` to Data.
    func toData() -> Data {
        switch self {
        case .none:
            return Data([0xFF])
        case .deviceLifetime:
            return Data([0xFE])
        case .rawValue(let raw):
            return Data([raw])
        }
    }
    
}

extension TimeExponential: CustomStringConvertible {
    
    public var description: String {
        guard let interval = interval else {
            return "Total device lifetime"
        }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.year, .month, .day, .hour, .minute, .second]
        formatter.unitsStyle = .short
        return formatter.string(from: interval)!
    }
    
}

private extension DataConvertible where Self: Comparable {
    
    /// Returns the value as Data.
    ///
    /// - parameters:
    ///   - numberOfBytes: Resulting number of bytes.
    ///   - range: The range the value is to be located in.
    /// - returns: The Data.
    func toData(ofLength numberOfBytes: Int = MemoryLayout<Self>.size,
                withRange range: ClosedRange<Self>? = nil) -> Data {
        let truncated = range.map { Swift.max($0.lowerBound, Swift.min($0.upperBound, self)) } ?? self
        return (Data() + truncated).subdata(in: 0..<numberOfBytes)
    }
    
}

private extension Optional where Wrapped: DataConvertible & FixedWidthInteger {
    
    /// Returns the value as Data. If the value is `nil`, the given
    /// unknown value converted to Data is returned.
    ///
    /// - parameters:
    ///   - numberOfBytes: Resulting number of bytes.
    ///   - range: The range the value is to be located in.
    ///   - unknownValue: The value to be returned when the value is unknown.
    /// - returns: The Data.
    func toData(ofLength numberOfBytes: Int = MemoryLayout<Wrapped>.size,
                withRange range: ClosedRange<Wrapped>? = nil,
                withUnknownValue unknownValue: Wrapped) -> Data {
        guard let self = self else {
            return unknownValue.toData(ofLength: numberOfBytes, withRange: range)
        }
        return self.toData(ofLength: numberOfBytes, withRange: range)
    }
    
}

private extension Decimal {
    
    /// Returns the value as Data.
    ///
    /// - parameters:
    ///   - numberOfBytes: Resulting number of bytes.
    ///   - range: The range the value is to be located in.
    ///   - resolution: The convertion resolution.
    /// - returns: The Data.
    func toData(ofLength numberOfBytes: Int,
                withRange range: ClosedRange<Decimal>? = nil,
                withResolution resolution: Decimal = 1.0) -> Data {
        let truncated = range.map { max($0.lowerBound, min($0.upperBound, self)) } ?? self
        let rescaled = truncated / resolution
        let rescaledAsInt = NSDecimalNumber(decimal: rescaled).int64Value
        return rescaledAsInt.toData(ofLength: numberOfBytes)
    }
    
}

private extension Optional where Wrapped == Decimal {
    
    /// Returns the value as Data.
    ///
    /// - parameters:
    ///   - numberOfBytes: Resulting number of bytes.
    ///   - range: The range the value is to be located in.
    ///   - resolution: The convertion resolution.
    ///   - unknownValue: The unknown value.
    /// - returns: The Data.
    func toData(ofLength numberOfBytes: Int,
                withRange range: ClosedRange<Decimal>? = nil,
                withResolution resolution: Decimal = 1.0,
                withUnknownValue unknownValue: Int64) -> Data {
        guard let self = self else {
            return unknownValue.toData(ofLength: numberOfBytes)
        }
        return self.toData(ofLength: numberOfBytes, withRange: range, withResolution: resolution)
    }
    
}

private extension Optional where Wrapped == ValidDecimal {
    
    /// Returns the value as Data.
    ///
    /// - parameters:
    ///   - numberOfBytes: Resulting number of bytes.
    ///   - range: The range the value is to be located in.
    ///   - resolution: The convertion resolution.
    ///   - invalidValue: The invalid value.
    ///   - unknownValue: The unknown value.
    /// - returns: The Data.
    func toData(ofLength numberOfBytes: Int,
                withRange range: ClosedRange<Decimal>? = nil,
                withResolution resolution: Decimal = 1.0,
                withInvalidValue invalidValue: Int64,
                andUnknownValue unknownValue: Int64) -> Data {
        switch self {
        case .none:
            return unknownValue.toData(ofLength: numberOfBytes)
        case .invalid:
            return invalidValue.toData(ofLength: numberOfBytes)
        case .valid(let value):
            return value.toData(ofLength: numberOfBytes, withRange: range, withResolution: resolution)
        }
    }
    
}
