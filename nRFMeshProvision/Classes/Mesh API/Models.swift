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
    
    /// Returns whether the Model is subscribed to the given ``Group``.
    ///
    /// - parameter group: The Group to check subscription to.
    /// - returns: `True` if the Model is subscribed to the Group,
    ///            `false` otherwise.
    func isSubscribed(to group: Group) -> Bool {
        return subscriptions.contains(group)
    }
    
    /// Returns whether the Model is subscribed to the given ``MeshAddress``.
    ///
    /// - parameter address: The address to check subscription to.
    /// - returns: `True` if the Model is subscribed to a ``Group`` with given,
    ///            address, `false` otherwise.
    func isSubscribed(to address: MeshAddress) -> Bool {
        return subscriptions.contains { $0.address == address }
    }
    
    /// Whether the Model supports model publication defined in Section 4.2.3 in
    /// Bluetooth Mesh Profile 1.0.1 specification.
    ///
    /// - returns: `true` if the model supports model publication, `false` ir it doesn't
    ///            or `nil` if unknown.
    var supportsModelPublication: Bool? {
        if !isBluetoothSIGAssigned {
            return nil
        }
        switch modelIdentifier {
        // Foundation
        case 0x0000: return false // Configuration Server
        case 0x0001: return false // Configuration Client
        case 0x0002: return true  // Health Server
        case 0x0003: return true  // Health Client
        // Generic
        case 0x1000: return true  // Generic OnOff Server
        case 0x1001: return true  // Generic OnOff Client
        case 0x1002: return true  // Generic Level Server
        case 0x1003: return true  // Generic Level Client
        case 0x1004: return true  // Generic Default Transition Time Server
        case 0x1005: return true  // Generic Default Transition Time Client
        case 0x1006: return true  // Generic Power OnOff Server
        case 0x1007: return false // Generic Power OnOff Setup Server = only subsc
        case 0x1008: return true  // Generic Power OnOff Client
        case 0x1009: return true  // Generic Power Level Server
        case 0x100A: return false // Generic Power Level Setup Server
        case 0x100B: return true  // Generic Power Level Client
        case 0x100C: return true  // Generic Battery Server
        case 0x100D: return true  // Generic Battery Client
        case 0x100E: return true  // Generic Location Server
        case 0x100F: return false // Generic Location Setup Server
        case 0x1010: return true  // Generic Location Client
        case 0x1011: return true  // Generic Admin Property Server
        case 0x1012: return true  // Generic Manufacturer Property Server
        case 0x1013: return true  // Generic User Property Server
        case 0x1014: return true  // Generic Client Property Server
        case 0x1015: return true  // Generic Property Client
        // Sensors
        case 0x1100: return true  // Sensor Server
        case 0x1101: return true  // Sensor Setup Server
        case 0x1102: return true  // Sensor Client
        // Time and Scenes
        case 0x1200: return true  // Time Server
        case 0x1201: return false // Time Setup Server
        case 0x1202: return true  // Time Client
        case 0x1203: return true  // Scene Server
        case 0x1204: return false // Scene Setup Server
        case 0x1205: return true  // Scene Client
        case 0x1206: return true  // Scheduler Server
        case 0x1207: return false // Scheduler Setup Server
        case 0x1208: return true  // Scheduler Client
        // Lighting
        case 0x1300: return true  // Light Lightness Server
        case 0x1301: return false // Light Lightness Setup Server
        case 0x1302: return true  // Light Lightness Client
        case 0x1303: return true  // Light CTL Server
        case 0x1304: return false // Light CTL Setup Server
        case 0x1305: return true  // Light CTL Client
        case 0x1306: return true  // Light CTL Temperature Server
        case 0x1307: return true  // Light HSL Server
        case 0x1308: return false // Light HSL Setup Server
        case 0x1309: return true  // Light HSL Client
        case 0x130A: return true  // Light HSL Hue Server
        case 0x130B: return true  // Light HSL Saturation Server
        case 0x130C: return true  // Light xyL Server
        case 0x130D: return false // Light xyL Setup Server
        case 0x130E: return true  // Light xyL Client
        case 0x130F: return true  // Light LC Server
        case 0x1310: return true  // Light LC Setup Server
        case 0x1311: return true  // Light LC Client
            
        default: return nil
        }
    }
    
    /// Whether the Model supports model subscription defined in Section 4.2.4 in
    /// Bluetooth Mesh Profile 1.0.1 specification.
    ///
    /// - returns: `true` if the model supports model subscription, `false` ir it doesn't
    ///            or `nil` if unknown.
    var supportsModelSubscriptions: Bool? {
        if !isBluetoothSIGAssigned {
            return nil
        }
        switch modelIdentifier {
        // Foundation
        case 0x0000: return false // Configuration Server
        case 0x0001: return false // Configuration Client
        case 0x0002: return true  // Health Server
        case 0x0003: return true  // Health Client
        // Generic
        case 0x1000: return true  // Generic OnOff Server
        case 0x1001: return true  // Generic OnOff Client
        case 0x1002: return true  // Generic Level Server
        case 0x1003: return true  // Generic Level Client
        case 0x1004: return true  // Generic Default Transition Time Server
        case 0x1005: return true  // Generic Default Transition Time Client
        case 0x1006: return true  // Generic Power OnOff Server
        case 0x1007: return true  // Generic Power OnOff Setup Server
        case 0x1008: return true  // Generic Power OnOff Client
        case 0x1009: return true  // Generic Power Level Server
        case 0x100A: return true  // Generic Power Level Setup Server
        case 0x100B: return true  // Generic Power Level Client
        case 0x100C: return true  // Generic Battery Server
        case 0x100D: return true  // Generic Battery Client
        case 0x100E: return true  // Generic Location Server
        case 0x100F: return true  // Generic Location Setup Server
        case 0x1010: return true  // Generic Location Client
        case 0x1011: return true  // Generic Admin Property Server
        case 0x1012: return true  // Generic Manufacturer Property Server
        case 0x1013: return true  // Generic User Property Server
        case 0x1014: return true  // Generic Client Property Server
        case 0x1015: return true  // Generic Property Client
        // Sensors
        case 0x1100: return true  // Sensor Server
        case 0x1101: return true  // Sensor Setup Server
        case 0x1102: return true  // Sensor Client
        // Time and Scenes
        case 0x1200: return true  // Time Server
        case 0x1201: return false // Time Setup Server
        case 0x1202: return true  // Time Client
        case 0x1203: return true  // Scene Server
        case 0x1204: return true  // Scene Setup Server
        case 0x1205: return true  // Scene Client
        case 0x1206: return true  // Scheduler Server
        case 0x1207: return true  // Scheduler Setup Server
        case 0x1208: return true  // Scheduler Client
        // Lighting
        case 0x1300: return true  // Light Lightness Server
        case 0x1301: return true  // Light Lightness Setup Server
        case 0x1302: return true  // Light Lightness Client
        case 0x1303: return true  // Light CTL Server
        case 0x1304: return true  // Light CTL Setup Server
        case 0x1305: return true  // Light CTL Client
        case 0x1306: return true  // Light CTL Temperature Server
        case 0x1307: return true  // Light HSL Server
        case 0x1308: return true  // Light HSL Setup Server
        case 0x1309: return true  // Light HSL Client
        case 0x130A: return true  // Light HSL Hue Server
        case 0x130B: return true  // Light HSL Saturation Server
        case 0x130C: return true  // Light xyL Server
        case 0x130D: return true  // Light xyL Setup Server
        case 0x130E: return true  // Light xyL Client
        case 0x130F: return true  // Light LC Server
        case 0x1310: return true  // Light LC Setup Server
        case 0x1311: return true  // Light LC Client
            
        default: return nil
        }
    }
    
}
