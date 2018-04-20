//
//  MeshModelIdentifiers.swift
//  nRFMeshProvision_Example
//
//  Created by Mostafa Berg on 13/04/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation

public enum MeshModelIdentifiers: UInt16 {
    // SIG Models, Mesh Spec
    case configurationServer = 0x0000
    case configurationClient = 0x0001
    case healthServer        = 0x0002
    case healthClient        = 0x0003
    // SIG Generics, Mesh Model Spec
    case genericOnOffServer = 0x1000
    case genericOnOffClient = 0x1001
    case genericLevelServer = 0x1002
    case genericLevelClient = 0x1003
    case genericDefaultTransitionTimeServer = 0x1004
    case genericDefaultTransitionTimeClient = 0x1005
    case genericPowerOnOffServer = 0x1006
    case genericPowerOnOffSetupServer = 0x1007
    case genericPowerOnOffClient = 0x1008
    case genericPowerLevelServer = 0x1009
    case genericPowerLevelSetupServer = 0x100A
    case genericPowerLevelClient = 0x100B
    case genericBatteryServer = 0x100C
    case genericBatteryClient = 0x100D
    case genericLocationServer = 0x100E
    case genericLocationSetupServer = 0x100F
    case genericLocationClient = 0x1010
    case genericAdminPropertyServer = 0x1011
    case genericManufacturerPropertyServer = 0x1012
    case genericUserPropertyServer = 0x1013
    case genericClientPropertyServer = 0x1014
    case genericPropertyClient = 0x1015
    // SIG Sensors, Mesh Model Spec
    case sensorServer = 0x1100
    case sensorSetupServer = 0x1101
    case sensorClient = 0x1102
    // SIG Time and Scenes, Mesh Model Spec
    case timeServer = 0x1200
    case timeSetupServer = 0x1201
    case timeClient = 0x1202
    case sceneServer = 0x1203
    case sceneSetupServer = 0x1204
    case sceneClient = 0x1205
    case schedulerServer = 0x1206
    case schedulerSetupServer = 0x1207
    case schedulerClient = 0x1208
    // SIG Lightning, Mesh Model Spec
    case lightLightnessServer = 0x1300
    case lightLightnessSetupServer = 0x1301
    case lightLightnessClient = 0x1302
    case lightCTLServer = 0x1303
    case lightCTLSetupServer = 0x1304
    case lightCTLClient = 0x1305
    case lightCTLTemperatureServer = 0x1306
    case lightHSLServer = 0x1307
    case lightHSLSetupServer = 0x1308
    case lightHSLClient = 0x1309
    case lightHSLHueServer = 0x130A
    case lightHSLSaturationServer = 0x130B
    case lightxyLServer = 0x130C
    case lightxyLSetupServer = 0x130D
    case lightxyLClient = 0x130E
    case lightLCServer = 0x130F
    case lightLCSetupServer = 0x1310
    case lightLCClient = 0x1311
}
