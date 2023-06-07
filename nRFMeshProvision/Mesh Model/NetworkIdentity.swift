/*
* Copyright (c) 2023, Nordic Semiconductor
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

/// The Network Identity contains information from Network Identity or Private Network
/// Identity beacon.
///
/// Network Identities can be matched to Network Keys in the network.
///
/// - since: 4.0.0
public protocol NetworkIdentity {
    /// Returns whether the identity matches given ``NetworkKey``.
    ///
    /// - parameter networkKey: The Network Key to check.
    /// - returns: True, if the identity matches the Network Key; false otherwise.
    func matches(networkKey: NetworkKey) -> Bool
}

/// Representation of Network ID advertising packet.
public struct PublicNetworkIdentity: NetworkIdentity {
    /// The Network ID is 64-bit network identifier derived from the Network Key.
    public let networkId: Data
    
    /// Creates the Network Identity object from Hash and Random values.
    ///
    /// - parameter networkId: Identifies the network.
    public init(networkId: Data) {
        self.networkId = networkId
    }
    
    /// Creates the Network Identity object from the received advertisement data.
    ///
    /// - parameter advertisementData: Received advertisement data.
    public init?(advertisementData: [String : Any]) {
        guard let serviceData = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID : Data],
              let data = serviceData[MeshProxyService.uuid],
              data.count > 0 else {
            return nil
        }
        guard data.count == 9 && data[0] == 0x00 else {
            return nil
        }
        self.init(networkId: data.subdata(in: 1..<9))
    }
    
    public func matches(networkKey: NetworkKey) -> Bool {
        return networkId == networkKey.networkId || networkId == networkKey.oldNetworkId
    }
}

/// Representation of Private Network Identity advertising packet.
public struct PrivateNetworkIdentity: NetworkIdentity {
    /// Function of the included random number and identity information.
    public let hash: Data
    /// 64-bit random number.
    public let random: Data
    
    /// Creates the Network Identity object from Hash and Random values.
    /// - parameters:
    ///   - hash: Function of the included random number and identity information.
    ///   - random: 64-bit random number.
    public init(hash: Data, random: Data) {
        self.hash = hash
        self.random = random
    }
    
    /// Creates the Network Identity object from the received advertisement data.
    ///
    /// - parameter advertisementData: Received advertisement data.
    public init?(advertisementData: [String : Any]) {
        guard let serviceData = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID : Data],
              let data = serviceData[MeshProxyService.uuid],
              data.count > 0 else {
            return nil
        }
        guard data.count == 17 && data[0] == 0x02 else {
            return nil
        }
        self.init(hash: data.subdata(in: 1..<9), random: data.subdata(in: 9..<17))
    }
    
    public func matches(networkKey: NetworkKey) -> Bool {
        // Data are: Network ID and 64 bit Random.
        let data = networkKey.networkId + random
        let calculatedHash = Crypto.calculateHash(from: data,
                                                  usingIdentityKey: networkKey.keys.identityKey)
        if calculatedHash == hash {
            return true
        }
        
        // If the Key Refresh Procedure is in place, the identity might have been
        // generated with the old key.
        if let oldIdentityKey = networkKey.oldKeys?.identityKey,
           let oldNetworkId = networkKey.oldNetworkId {
            let oldData = oldNetworkId + random
            let calculatedHash = Crypto.calculateHash(from: oldData,
                                                      usingIdentityKey: oldIdentityKey)
            if calculatedHash == hash {
                return true
            }
        }
        return false
    }
}

extension PublicNetworkIdentity: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return "Network Identity (0x\(networkId.hex))"
    }
    
}

extension PrivateNetworkIdentity: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return "Network Identity (hash: 0x\(hash.hex), random: 0x\(random.hex))"
    }
    
}
