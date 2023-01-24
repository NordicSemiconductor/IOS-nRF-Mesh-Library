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

internal struct SecureNetworkBeacon: NetworkBeaconPdu {
    let pdu: Data
    let beaconType: BeaconType = .secureNetwork
    let networkKey: NetworkKey
    let validForKeyRefreshProcedure: Bool
    let keyRefreshFlag: Bool
    let ivIndex: IvIndex
    
    /// Creates Secure Network beacon PDU object from received PDU.
    ///
    /// - parameters:
    ///   - pdu: The data received from mesh network.
    ///   - networkKey: The Network Key to validate the beacon.
    /// - returns: The beacon object, or `nil` if the data are invalid.
    init?(decode pdu: Data, usingNetworkKey networkKey: NetworkKey) {
        self.pdu = pdu
        guard pdu.count == 22, pdu[0] == 1 else {
            return nil
        }
        keyRefreshFlag = pdu[1] & 0x01 != 0
        let updateActive = pdu[1] & 0x02 != 0
        let networkId = pdu.subdata(in: 2..<10)
        let index: UInt32 = pdu.read(fromOffset: 10)
        ivIndex = IvIndex(index: index.bigEndian, updateActive: updateActive)
        
        // Authenticate beacon using given Network Key.
        // During Key Refresh Procedure when in Phase 1 (key distribution) the
        // Secure Network beacon may be decoded using the old Network Key.
        if networkId == networkKey.networkId {
            guard Crypto.authenticate(secureNetworkBeaconPdu: pdu,
                                      usingBeaconKey: networkKey.keys.beaconKey) else {
                return nil
            }
            self.networkKey = networkKey
            self.validForKeyRefreshProcedure = networkKey.oldKey != nil
        } else if case .keyDistribution = networkKey.phase,
                  networkId == networkKey.oldNetworkId,
                  let oldKeys = networkKey.oldKeys {
            guard Crypto.authenticate(secureNetworkBeaconPdu: pdu,
                                      usingBeaconKey: oldKeys.beaconKey) else {
                return nil
            }
            self.networkKey = networkKey
            self.validForKeyRefreshProcedure = false
        } else {
            return nil
        }
    }
}

extension SecureNetworkBeacon: CustomDebugStringConvertible {
    
    var debugDescription: String {
        return "Secure Network beacon (Network ID: \(networkKey.networkId.hex), \(ivIndex), Key Refresh Flag: \(keyRefreshFlag))"
    }
    
}
