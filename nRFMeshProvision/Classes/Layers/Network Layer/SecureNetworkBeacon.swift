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

internal struct SecureNetworkBeacon: BeaconPdu {
    let pdu: Data
    let beaconType: BeaconType = .secureNetwork
    
    /// The Network Key related to this Secure Network beacon.
    let networkKey: NetworkKey
    /// Key Refresh flag value.
    ///
    /// When this flag is active, the Node shall set the Key Refresh
    /// Phase for this Network Key to `.finalizing`. When in this phase,
    /// the Node shall only transmit messages and Secure Network beacons
    /// using the new keys, shall receive messages using the old keys
    /// and the new keys, and shall only receive Secure Network beacons
    /// secured using the new Network Key.
    let keyRefreshFlag: Bool
    /// This flag is set to `true` if IV Update procedure is active.
    let ivUpdateActive: Bool
    /// Contains the value of the Network ID.
    let networkId: Data
    /// Contains the current IV Index.
    let ivIndex: UInt32
    
    /// Creates Secure Network beacon PDU object from received PDU.
    ///
    /// - parameter pdu: The data received from mesh network.
    /// - parameter networkKey: The Network Key to validate the beacon.
    /// - returns: The beacon object, or `nil` if the data are invalid.
    init?(decode pdu: Data, usingNetworkKey networkKey: NetworkKey) {
        self.pdu = pdu
        guard pdu.count == 22, pdu[0] == 1 else {
            return nil
        }
        keyRefreshFlag = pdu[1] & 0x01 != 0
        ivUpdateActive = pdu[1] & 0x02 != 0
        networkId = pdu.subdata(in: 2..<10)
        ivIndex = CFSwapInt32BigToHost(pdu.read(fromOffset: 10))
        
        // Authenticate beacon using given Network Key.
        let helper = OpenSSLHelper()
        if networkId == networkKey.networkId {
            let authenticationValue = helper.calculateCMAC(pdu.subdata(in: 1..<14), andKey: networkKey.keys.beaconKey)!
            guard authenticationValue.subdata(in: 0..<8) == pdu.subdata(in: 14..<22) else {
                return nil
            }
            self.networkKey = networkKey
        } else if let oldNetworkId = networkKey.oldNetworkId, networkId == oldNetworkId {
            let authenticationValue = helper.calculateCMAC(pdu.subdata(in: 1..<14), andKey: networkKey.oldKeys!.beaconKey)!
            guard authenticationValue.subdata(in: 0..<8) == pdu.subdata(in: 14..<22) else {
                return nil
            }
            self.networkKey = networkKey
        } else {
            return nil
        }
    }
}

internal extension SecureNetworkBeacon {
    
    /// This method goes over all Network Keys in the mesh network and tries
    /// to parse the beacon.
    ///
    /// - parameter pdu:         The received PDU.
    /// - parameter meshNetwork: The mesh network for which the PDU should be decoded.
    /// - returns: The beacon object.
    static func decode(_ pdu: Data, for meshNetwork: MeshNetwork) -> SecureNetworkBeacon? {
        guard pdu.count > 1 else {
            return nil
        }
        let beaconType = BeaconType(rawValue: pdu[0])
        switch beaconType {
        case .some(.secureNetwork):
            for networkKey in meshNetwork.networkKeys {
                if let beacon = SecureNetworkBeacon(decode: pdu, usingNetworkKey: networkKey) {
                    return beacon
                }
            }
            return nil
        default:
            return nil
        }
    }
    
}

extension SecureNetworkBeacon: CustomDebugStringConvertible {
    
    var debugDescription: String {
        return "Secure Network beacon (Network ID: \(networkId.hex), IV Index: \(ivIndex), Key Refresh Flag: \(keyRefreshFlag), IV Update active: \(ivUpdateActive))"
    }
    
}
