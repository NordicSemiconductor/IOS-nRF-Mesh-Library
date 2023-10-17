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
    /// UUID. The first 16 bytes are the converted to UUID.
    var unprovisionedDeviceUUID: UUID? {
        guard let serviceData = self[CBAdvertisementDataServiceDataKey] as? [CBUUID : Data],
              let data = serviceData[MeshProvisioningService.uuid] else {
                return nil
        }
        guard data.count == 18 || data.count == 22 else {
            return nil
        }
        
        return UUID(data: data.subdata(in: 0 ..< 16))
    }
    
    /// Hash of the associated URI advertised with the URI AD Type.
    ///
    /// Along with the Unprovisioned Device beacon, the unprovisioned device may also
    /// advertise a separate non-connectable advertising packet with a URI data type
    /// that points to OOB information such as a Public Key. To allow the association
    /// of the advertised URI with the Unprovisioned Device beacon, the beacon may
    /// contain an optional 4-octet URI Hash field.
    ///
    /// The URI Hash is calculated as:
    /// ```swift
    /// s1(URI Data)[0-3]
    /// ```
    /// The URI Data is a buffer containing the URI data type, as defined in Core Bluetooth
    /// Supplement (CSS) Version 6 or later.
    var uriHash: Data? {
        guard let serviceData = self[CBAdvertisementDataServiceDataKey] as? [CBUUID : Data],
              let data = serviceData[MeshProvisioningService.uuid] else {
                return nil
        }
        guard data.count == 22 else {
            return nil
        }
        return data.subdata(in: 19 ..< 23)
    }
    
    /// Returns the Unprovisioned Device's OOB information or `nil` if such
    /// value not be parsed.
    ///
    /// This value is taken from the Service Data with Mesh Provisioning Service
    /// UUID. The last 2 bytes are parsed and returned as ``OobInformation``.
    var oobInformation: OobInformation? {
        return OobInformation(advertisementData: self)
    }
    
    /// Returns the Network ID from a packet of a provisioned Node
    /// with Proxy capabilities, or `nil` if such value not be parsed.
    ///
    /// - note: Before version 4.0.0 this property returned Data object.
    ///         The API changed was made due to introduction of Private Network Identity
    ///         advertising packets, which don't contain the Network ID directly,
    ///         but still can identify a network cryptographically.
    /// - seeAlso: ``NetworkIdentity/matches(networkKey:)``
    /// - seeAlso: ``MeshNetwork/matches(networkIdentity:)``
    /// - since: 4.0.0
    var networkIdentity: NetworkIdentity? {
        return PublicNetworkIdentity(advertisementData: self) ?? PrivateNetworkIdentity(advertisementData: self)
    }
    
    /// Returns the Network ID from a packet of a provisioned Node
    /// with Proxy capabilities, or `nil` if such value not be parsed.
    ///
    /// - seeAlso: ``MeshNetwork/matches(networkId:)``
    @available(*, deprecated, renamed: "networkIdentity")
    var networkId: Data? {
        return PublicNetworkIdentity(advertisementData: self)?.networkId
    }
    
    /// Returns the Node Identity beacon data or `nil` if such value was not parsed.
    ///
    /// - note: Before version 4.0.0 this property returned Hash and Random pair.
    /// - seeAlso: ``NodeIdentity/matches(node:)``
    /// - seeAlso: ``MeshNetwork/node(matchingNodeIdentity:)``
    /// - since: 4.0.0
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

extension UUID {
    
    /// Converts the Data to foundation UUID.
    init?(data: Data) {
        guard data.count == 16 else {
            return nil
        }
        self = data.withUnsafeBytes { UUID(uuid: $0.load(as: uuid_t.self)) }
    }
    
    /// Converts the Data to foundation UUID using Little Endian notation.
    init?(dataLittleEndian data: Data) {
        guard data.count == 16 else {
            return nil
        }
        let reversed = Data(data.reversed())
        self = reversed.withUnsafeBytes { UUID(uuid: $0.load(as: uuid_t.self)) }
    }
    
}
