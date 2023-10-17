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

/// The Node Identity contains information from Node Identity or Private Node Identity
/// beacon.
///
/// It can be used to match advertising device to a specific ``Node`` in the network.
///
/// - since: 4.0.0
public protocol NodeIdentity {
    /// Returns whether the identity matches given ``Node``.
    ///
    /// - parameter node: The Node to check.
    /// - returns: True, if the identity matches the Node; false otherwise.
    func matches(node: Node) -> Bool
}

/// Representation of Node Identity advertising packet.
public struct PublicNodeIdentity: NodeIdentity {
    /// Function of the included random number and identity information.
    public let hash: Data
    /// 64-bit random number.
    public let random: Data
    
    /// Creates the Node Identity object from Hash and Random values.
    /// - parameters:
    ///   - hash: Function of the included random number and identity information.
    ///   - random: 64-bit random number.
    public init(hash: Data, random: Data) {
        self.hash = hash
        self.random = random
    }
    
    /// Creates the Node Identity object from the received advertisement data.
    ///
    /// - parameter advertisementData: Received advertisement data.
    public init?(advertisementData: [String : Any]) {
        guard let serviceData = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID : Data],
              let data = serviceData[MeshProxyService.uuid] else {
            return nil
        }
        guard data.count == 17, data[0] == 0x01 else {
            return nil
        }
        self.init(hash: data.subdata(in: 1..<9), random: data.subdata(in: 9..<17))
    }
    
    public func matches(node: Node) -> Bool {
        // Data are: 48 bits of Padding (0s), 64 bit Random and Unicast Address.
        let data = Data(repeating: 0, count: 6) + random + node.primaryUnicastAddress.bigEndian
        
        for networkKey in node.networkKeys {
            let calculatedHash = Crypto.calculateHash(from: data,
                                                      usingIdentityKey: networkKey.keys.identityKey)
            if calculatedHash == hash {
                return true
            }
            // If the Key Refresh Procedure is in place, the identity might have been
            // generated with the old key.
            if let oldIdentityKey = networkKey.oldKeys?.identityKey {
                let calculatedHash = Crypto.calculateHash(from: data,
                                                          usingIdentityKey: oldIdentityKey)
                if calculatedHash == hash {
                    return true
                }
            }
        }
        return false
    }
}

/// Representation of Private Node Identity advertising packet.
public struct PrivateNodeIdentity: NodeIdentity {
    /// Function of the included random number and identity information.
    public let hash: Data
    /// 64-bit random number.
    public let random: Data
    
    /// Creates the Private Node Identity object from Hash and Random values.
    /// - parameters:
    ///   - hash: Function of the included random number and identity information.
    ///   - random: 64-bit random number.
    public init(hash: Data, random: Data) {
        self.hash = hash
        self.random = random
    }
    
    /// Creates the Private Node Identity object from the received advertisement data.
    ///
    /// - parameter advertisementData: Received advertisement data.
    public init?(advertisementData: [String : Any]) {
        guard let serviceData = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID : Data],
              let data = serviceData[MeshProxyService.uuid] else {
            return nil
        }
        guard data.count == 17, data[0] == 0x03 else {
            return nil
        }
        self.init(hash: data.subdata(in: 1..<9), random: data.subdata(in: 9..<17))
    }
    
    public func matches(node: Node) -> Bool {
        // Data are: 40 bits of Padding (0s), 0x03, 64 bit Random and Unicast Address.
        let data = Data(repeating: 0, count: 5) + Data([0x03]) + random + node.primaryUnicastAddress.bigEndian
        
        for networkKey in node.networkKeys {
            let calculatedHash = Crypto.calculateHash(from: data,
                                                      usingIdentityKey: networkKey.keys.identityKey)
            if calculatedHash == hash {
                return true
            }
            // If the Key Refresh Procedure is in place, the identity might have been
            // generated with the old key.
            if let oldIdentityKey = networkKey.oldKeys?.identityKey {
                let calculatedHash = Crypto.calculateHash(from: data,
                                                          usingIdentityKey: oldIdentityKey)
                if calculatedHash == hash {
                    return true
                }
            }
        }
        return false
    }
}

extension PublicNodeIdentity: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return "Node Identity (hash: 0x\(hash.hex), random: 0x\(random.hex))"
    }
    
}

extension PrivateNodeIdentity: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return "Private Node Identity (hash: 0x\(hash.hex), random: 0x\(random.hex))"
    }
    
}
