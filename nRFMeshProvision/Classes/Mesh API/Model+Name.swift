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
        // Foundation
        case 0x0000: return "Configuration Server"
        case 0x0001: return "Configuration Client"
        case 0x0002: return "Health Server"
        case 0x0003: return "Health Client"
        // Generic
        case 0x1000: return "Generic OnOff Server"
        case 0x1001: return "Generic OnOff Client"
        case 0x1002: return "Generic Level Server"
        case 0x1003: return "Generic Level Client"
        case 0x1004: return "Generic Default Transition Time Server"
        case 0x1005: return "Generic Default Transition Time Client"
        case 0x1006: return "Generic Power OnOff Server"
        case 0x1007: return "Generic Power OnOff Setup Server"
        case 0x1008: return "Generic Power OnOff Client"
        case 0x1009: return "Generic Power Level Server"
        case 0x100A: return "Generic Power Level Setup Server"
        case 0x100B: return "Generic Power Level Client"
        case 0x100C: return "Generic Battery Server"
        case 0x100D: return "Generic Battery Client"
        case 0x100E: return "Generic Location Server"
        case 0x100F: return "Generic Location Setup Server"
        case 0x1010: return "Generic Location Client"
        case 0x1011: return "Generic Admin Property Server"
        case 0x1012: return "Generic Manufacturer Property Server"
        case 0x1013: return "Generic User Property Server"
        case 0x1014: return "Generic Client Property Server"
        case 0x1015: return "Generic Property Client"
        // Sensors
        case 0x1100: return "Sensor Server"
        case 0x1101: return "Sensor Setup Server"
        case 0x1102: return "Sensor Client"
        // Time and Scenes
        case 0x1200: return "Time Server"
        case 0x1201: return "Time Setup Server"
        case 0x1202: return "Time Client"
        case 0x1203: return "Scene Server"
        case 0x1204: return "Scene Setup Server"
        case 0x1205: return "Scene Client"
        case 0x1206: return "Scheduler Server"
        case 0x1207: return "Scheduler Setup Server"
        case 0x1208: return "Scheduler Client"
        // Lighting
        case 0x1300: return "Light Lightness Server"
        case 0x1301: return "Light Lightness Setup Server"
        case 0x1302: return "Light Lightness Client"
        case 0x1303: return "Light CTL Server"
        case 0x1304: return "Light CTL Setup Server"
        case 0x1305: return "Light CTL Client"
        case 0x1306: return "Light CTL Temperature Server"
        case 0x1307: return "Light HSL Server"
        case 0x1308: return "Light HSL Setup Server "
        case 0x1309: return "Light HSL Client"
        case 0x130A: return "Light HSL Hue Server"
        case 0x130B: return "Light HSL Saturation Server"
        case 0x130C: return "Light xyL Server"
        case 0x130D: return "Light xyL Setup Server"
        case 0x130E: return "Light xyL Client"
        case 0x130F: return "Light LC Server"
        case 0x1310: return "Light LC Setup Server"
        case 0x1311: return "Light LC Client"
            
        default: return nil
        }
    }
    
}
