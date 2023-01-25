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

public extension Dictionary where Key == String, Value == Any {
    
    /// Returns the value under the Complete or Shortened Local Name
    /// from the advertising packet, or `nil` if such doesn't exist.
    var localName: String? {
        return self[CBAdvertisementDataLocalNameKey] as? String
    }
    
    /// Returns the Unprovisioned Device's UUID or `nil` if such value not be parsed.
    ///
    /// This value is taken from the Service Data with Mesh Provisioning Service
    /// UUID. The first 16 bytes are the converted to CBUUID.
    var unprovisionedDeviceUUID: CBUUID? {
        guard let serviceData = self[CBAdvertisementDataServiceDataKey] as? [CBUUID : Data],
              let data = serviceData[MeshProvisioningService.uuid] else {
                return nil
        }
        guard data.count == 18 else {
            return nil
        }
        
        return CBUUID(data: data.subdata(in: 0 ..< 16))
    }
    
    /// Returns the Unprovisioned Device's OOB information or `nil` if such
    /// value not be parsed.
    ///
    /// This value is taken from the Service Data with Mesh Provisioning Service
    /// UUID. The last 2 bytes are parsed and returned as ``OobInformation``.
    var oobInformation: OobInformation? {
        guard let serviceData = self[CBAdvertisementDataServiceDataKey] as? [CBUUID : Data],
              let data = serviceData[MeshProvisioningService.uuid] else {
                return nil
        }
        guard data.count == 18 else {
            return nil
        }
        
        let rawValue: UInt16 = data.read(fromOffset: 16)
        return OobInformation(rawValue: rawValue)
    }
    
    /// Returns the Network ID from a packet of a provisioned Node
    /// with Proxy capabilities, or `nil` if such value not be parsed.
    ///
    /// - note: Before version 3.3.0 this property returned Data object.
    ///         The API changed was made due to introduction of Private Network Identity
    ///         advertising packets, which don't contain the Network ID directly,
    ///         but still can identify a network cryptographicaly.
    /// - seeAlso: ``NetworkIdentity/matches(networkKey:)``
    /// - seeAlso: ``MeshNetwork/matches(networkIdentity:)``
    /// - since: 3.3.0
    var networkIdentity: NetworkIdentity? {
        return PublicNetworkIdentity(advertisementData: self) ?? PrivateNetworkIdentity(advertisementData: self)
    }
    
    /// Returns the Network ID from a packet of a provisioned Node
    /// with Proxy capabilities, or `nil` if such value not be parsed.
    ///
    /// - seeAlso: ``MeshNetwork/matches(networkId:)``
    @available(*, deprecated, renamed: "networkIdentity")
    var networkId: Data? {
        guard let serviceData = self[CBAdvertisementDataServiceDataKey] as? [CBUUID : Data],
              let data = serviceData[MeshProxyService.uuid] else {
            return nil
        }
        guard data.count == 9, data[0] == 0x00 else {
            return nil
        }
        return data.subdata(in: 1..<9)
    }
    
    /// Returns the Node Identity beacon data or `nil` if such value was not parsed.
    ///
    /// - note: Before version 3.3.0 this property returned Hash and Random pair.
    /// - seeAlso: ``NodeIdentity/matches(node:)``
    /// - seeAlso: ``MeshNetwork/node(matchingNodeIdentity:)``
    /// - since: 3.3.0
    var nodeIdentity: NodeIdentity? {
        return PublicNodeIdentity(advertisementData: self) ?? PrivateNodeIdentity(advertisementData: self)
    }
}

extension CBUUID {
    
    /// Converts the CBUUID to foundation UUID.
    var uuid: UUID {
        return data.withUnsafeBytes { UUID(uuid: $0.load(as: uuid_t.self)) }
    }
    
}
