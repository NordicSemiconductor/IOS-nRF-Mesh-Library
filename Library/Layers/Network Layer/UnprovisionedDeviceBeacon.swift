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
import CoreBluetooth

internal struct UnprovisionedDeviceBeacon: BeaconPdu {
    let pdu: Data
    let beaconType: BeaconType = .unprovisionedDevice
    
    /// Device UUID uniquely identifying this device.
    let deviceUuid: UUID
    /// The OOB Information field is used to help drive the provisioning
    /// process by indicating the availability of OOB data, such as
    /// a public key of the device.
    let oob: OobInformation
    /// Hash of the associated URI advertised with the URI AD Type.
    let uriHash: Data?
    
    /// Creates Unprovisioned Device beacon PDU object from received PDU.
    ///
    /// - parameter pdu: The data received from mesh network.
    /// - returns: The beacon object, or `nil` if the data are invalid.
    init?(decode pdu: Data) {
        self.pdu = pdu
        guard pdu.count >= 19, pdu[0] == 0 else {
            return nil
        }
        let cbuuid = CBUUID(data: pdu.subdata(in: 1..<17))
        deviceUuid = cbuuid.uuid
        oob = OobInformation(data: pdu, offset: 17)
        if pdu.count == 23 {
            uriHash = pdu.dropFirst(19)
        } else {
            uriHash = nil
        }
    }
}

internal struct UnprovisionedDeviceBeaconDecoder {
    private init() {}
    
    /// This method decodes the given pdu and creates an Unprovisioned Device Beacon.
    ///
    /// - parameters:
    ///   - pdu:         The received PDU.
    /// - returns: The beacon object.
    static func decode(_ pdu: Data) -> UnprovisionedDeviceBeacon? {
        guard pdu.count > 1, let beaconType = BeaconType(rawValue: pdu[0]) else {
            return nil
        }
        switch beaconType {
        case .unprovisionedDevice:
            return UnprovisionedDeviceBeacon(decode: pdu)
        default:
            return nil
        }
    }
    
}

extension UnprovisionedDeviceBeacon: CustomDebugStringConvertible {
    
    var debugDescription: String {
        return "Unprovisioned Device beacon (UUID: \(deviceUuid.uuidString), OOB Info: \(oob), URI hash: \(uriHash?.hex ?? "None"))"
    }
    
}
