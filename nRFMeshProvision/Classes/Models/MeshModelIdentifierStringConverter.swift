//
//  MeshModelIdentifierStringConverter.swift
//  nRFMeshProvision_Example
//
//  Created by Mostafa Berg on 13/04/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation

public struct MeshModelIdentifierStringConverter {
    let identifierMap: [MeshModelIdentifiers: String]
    
    public init() {
        identifierMap = [
        .configurationServer: "Configuration Server",
        .configurationClient: "Configuration Client",
        .healthServer: "Health Server",
        .healthClient: "Health Client",
        .genericOnOffServer: "Generic OnOff Server",
        .genericOnOffClient: "Generic OnOff Client",
        .genericLevelServer: "Generic Level Server",
        .genericLevelClient: "Generic Level Client",
        .genericDefaultTransitionTimeServer: "Generic Default Transition Time Server",
        .genericDefaultTransitionTimeClient: "Generic Default Transition Time Client",
        .genericPowerOnOffServer: "Generic Power OnOff Server",
        .genericPowerOnOffSetupServer: "Generic PowerOnOff Setup Server",
        .genericPowerOnOffClient: "Generic Power OnOff Client",
        .genericPowerLevelServer: "Generic Power Level Server",
        .genericPowerLevelSetupServer: "Generic Power Level Setup Server",
        .genericPowerLevelClient: "Generic Power Level Client",
        .genericBatteryServer: "Generic Battery Server",
        .genericBatteryClient: "Generic Battery Client",
        .genericLocationServer: "Generic Location Server",
        .genericLocationSetupServer: "Generic Location Setup Server",
        .genericLocationClient: "Generic Location Client",
        .genericAdminPropertyServer: "Generic Admin Property Server",
        .genericManufacturerPropertyServer: "Generic Manufacturer Property Server",
        .genericUserPropertyServer: "Generic User Property Server",
        .genericClientPropertyServer: "Generic Client Property Server",
        .genericPropertyClient: "Generic Property Client",
        .sensorServer: "Sensor Server",
        .sensorSetupServer: "Sensor Setup Server",
        .sensorClient: "Sensor Client",
        .timeServer: "Time Server",
        .timeSetupServer: "Time Setup Server",
        .timeClient: "Time Client",
        .sceneServer: "Scene Server",
        .sceneSetupServer: "Scene Setup Server",
        .sceneClient: "Scene Client",
        .schedulerServer: "Scheduler Server",
        .schedulerSetupServer: "Scheduler Setup Server",
        .schedulerClient: "Scheduler Client",
        .lightLightnessServer: "Light Lightness Server",
        .lightLightnessSetupServer: "Light Lightness Setup Server",
        .lightLightnessClient: "Light Lightness Client",
        .lightCTLServer: "Light CTL Server",
        .lightCTLSetupServer: "Light CTL Setup Server",
        .lightCTLClient: "Light CTL Client",
        .lightCTLTemperatureServer: "Light CTL Temperature Server",
        .lightHSLServer: "Light HSL Server",
        .lightHSLSetupServer: "Light HSL Setup Server",
        .lightHSLClient: "Light HSL Client",
        .lightHSLHueServer: "Light HSL Hue Server",
        .lightHSLSaturationServer: "Light HSL Saturation Server",
        .lightxyLServer: "Light xyL Server",
        .lightxyLSetupServer: "Light xyL Setup Server",
        .lightxyLClient: "Light xyL Client",
        .lightLCServer: "Light LC Server",
        .lightLCSetupServer: "Light LC Setup Server",
        .lightLCClient: "Light LC Client"
        ]
    }
    public func stringValueForIdentifier(_ aModelIdentifier: MeshModelIdentifiers) -> String {
        if let stringValue = identifierMap[aModelIdentifier] {
            return stringValue
        }
        return "Unknown Identifier"
    }
}
