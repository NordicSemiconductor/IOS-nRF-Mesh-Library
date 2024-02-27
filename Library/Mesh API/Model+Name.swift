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

public extension Model {
    
    /// The Model name as defined in Bluetooth Mesh Model Specification.
    var name: String? {
        if !isBluetoothSIGAssigned {
            return "Vendor Model"
        }
        switch modelIdentifier {
        // Foundation, from Mesh Profile 1.0.1
        case .configurationServerModelId: return "Configuration Server"
        case .configurationClientModelId: return "Configuration Client"
        case .healthServerModelId: return "Health Server"
        case .healthClientModelId: return "Health Client"
        // Foundation, added in Mesh Protocol 1.1
        case .remoteProvisioningServerModelId: return "Remote Provisioning Server"
        case .remoteProvisioningClientModelId: return "Remote Provisioning Client"
        case .directedForwardingConfigurationServerModelId: return "Directed Forwarding Configuration Server"
        case .directedForwardingConfigurationClientModelId: return "Directed Forwarding Configuration Client"
        case .bridgeConfigurationServerModelId: return "Bridge Configuration Server"
        case .bridgeConfigurationClientModelId: return "Bridge Configuration Client"
        case .privateBeaconServerModelId: return "Mesh Private Beacon Server"
        case .privateBeaconClientModelId: return "Mesh Private Beacon Client"
        case .onDemandPrivateProxyServerModelId: return "On-­Demand Private Proxy Server"
        case .onDemandPrivateProxyClientModelId: return "On-­Demand Private Proxy Client"
        case .sarConfigurationServerModelId: return "SAR Configuration Server"
        case .sarConfigurationClientModelId: return "SAR Configuration Client"
        case .opcodesAggregatorServerModelId: return "Opcodes Aggregator Server"
        case .opcodesAggregatorClientModelId: return "Opcodes Aggregator Client"
        case .largeCompositionDataServerModelId: return "Large Composition Data Server"
        case .largeCompositionDataClientModelId: return "Large Composition Data Client"
        case .solicitationPduRplConfigurationServerModelId: return "Solicitation PDU RPL Configuration Server"
        case .solicitationPduRplConfigurationClientModelId: return "Solicitation PDU RPL Configuration Client"
        // Generic
        case .genericOnOffServerModelId: return "Generic OnOff Server"
        case .genericOnOffClientModelId: return "Generic OnOff Client"
        case .genericLevelServerModelId: return "Generic Level Server"
        case .genericLevelClientModelId: return "Generic Level Client"
        case .genericDefaultTransitionTimeServerModelId: return "Generic Default Transition Time Server"
        case .genericDefaultTransitionTimeClientModelId: return "Generic Default Transition Time Client"
        case .genericPowerOnOffServerModelId: return "Generic Power OnOff Server"
        case .genericPowerOnOffSetupServerModelId: return "Generic Power OnOff Setup Server"
        case .genericPowerOnOffClientModelId: return "Generic Power OnOff Client"
        case .genericPowerLevelServerModelId: return "Generic Power Level Server"
        case .genericPowerLevelSetupServerModelId: return "Generic Power Level Setup Server"
        case .genericPowerLevelClientModelId: return "Generic Power Level Client"
        case .genericBatteryServerModelId: return "Generic Battery Server"
        case .genericBatteryClientModelId: return "Generic Battery Client"
        case .genericLocationServerModelId: return "Generic Location Server"
        case .genericLocationSetupServerModelId: return "Generic Location Setup Server"
        case .genericLocationClientModelId: return "Generic Location Client"
        case .genericAdminPropertyServerModelId: return "Generic Admin Property Server"
        case .genericManufacturerPropertyServerModelId: return "Generic Manufacturer Property Server"
        case .genericUserPropertyServerModelId: return "Generic User Property Server"
        case .genericClientPropertyServerModelId: return "Generic Client Property Server"
        case .genericPropertyClientModelId: return "Generic Property Client"
        // Sensors
        case .sensorServerModelId: return "Sensor Server"
        case .sensorSetupServerModelId: return "Sensor Setup Server"
        case .sensorClientModelId: return "Sensor Client"
        // Time and Scenes
        case .timeServerModelId: return "Time Server"
        case .timeSetupServerModelId: return "Time Setup Server"
        case .timeClientModelId: return "Time Client"
        case .sceneServerModelId: return "Scene Server"
        case .sceneSetupServerModelId: return "Scene Setup Server"
        case .sceneClientModelId: return "Scene Client"
        case .schedulerServerModelId: return "Scheduler Server"
        case .schedulerSetupServerModelId: return "Scheduler Setup Server"
        case .schedulerClientModelId: return "Scheduler Client"
        // Lighting
        case .lightLightnessServerModelId: return "Light Lightness Server"
        case .lightLightnessSetupServerModelId: return "Light Lightness Setup Server"
        case .lightLightnessClientModelId: return "Light Lightness Client"
        case .lightCTLServerModelId: return "Light CTL Server"
        case .lightCTLSetupServerModelId: return "Light CTL Setup Server"
        case .lightCTLClientModelId: return "Light CTL Client"
        case .lightCTLTemperatureServerModelId: return "Light CTL Temperature Server"
        case .lightHSLServerModelId: return "Light HSL Server"
        case .lightHSLSetupServerModelId: return "Light HSL Setup Server "
        case .lightHSLClientModelId: return "Light HSL Client"
        case .lightHSLHueServerModelId: return "Light HSL Hue Server"
        case .lightHSLSaturationServerModelId: return "Light HSL Saturation Server"
        case .lightXyLServerModelId: return "Light xyL Server"
        case .lightXyLSetupServerModelId: return "Light xyL Setup Server"
        case .lightXyLClientModelId: return "Light xyL Client"
        case .lightLCServerModelId: return "Light LC Server"
        case .lightLCSetupServerModelId: return "Light LC Setup Server"
        case .lightLCClientModelId: return "Light LC Client"
        // BLOB Transfer
        case .blobTransferServer: return "BLOB Transfer Server"
        case .blonTransferClient: return "BLOB Transfer Client"
        // Device Firmware Update (DFU), added in Mesh Protocol 1.1
        case .firmwareUpdateServer: return "Firmware Update Server"
        case .firmwareUpdateClient: return "Firmware Update Client"
        case .firmwareDistributionServer: return "Firmware Distribution Server"
        case .firmwareDistributionClient: return "Firmware Distribution Client"
            
        default: return nil
        }
    }
    
}
