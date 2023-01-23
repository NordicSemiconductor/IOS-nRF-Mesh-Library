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

internal struct PrivateBeacon: BeaconPdu {
    let pdu: Data
    let beaconType: BeaconType = .privateBeacon
    
    /// The Network Key related to this Secure Network beacon.
    let networkKey: NetworkKey
    /// A flag indicating whether the Secure Network beacon has been
    /// secured using the new Network Key during Key Refresh Procedure.
    let validForKeyRefreshProcedure: Bool
    /// Key Refresh flag value.
    ///
    /// When this flag is active, the Node shall set the Key Refresh
    /// Phase for this Network Key to ``KeyRefreshPhase/usingNewKeys``.
    /// When in this phase, the Node shall only transmit messages and
    /// Secure Network beacons using the new keys, shall receive messages
    /// using the old keys and the new keys, and shall only receive
    /// Secure Network beacons secured using the new Network Key.
    let keyRefreshFlag: Bool
    /// The IV Index carried by this Private beacon.
    let ivIndex: IvIndex
    
    /// Creates Private beacon PDU object from received PDU.
    ///
    /// - parameters:
    ///   - pdu: The data received from mesh network.
    ///   - networkKey: The Network Key to validate the beacon.
    /// - returns: The beacon object, or `nil` if the data are invalid.
    init?(decode pdu: Data, usingNetworkKey networkKey: NetworkKey) {
        self.pdu = pdu
        guard pdu.count == 27, pdu[0] == 2 else {
            return nil
        }
        
        // Try to decode and authentice the Private beacon using current Private Beacon Key.
        var privateBeaconData = Crypto.decodeAndAuthenticate(privateBeacon: pdu, usingPrivateBeaconKey: networkKey.keys.privateBeaconKey)
        
        // If the beacon failed to be authenticated, and the old key exists, use that one.
        if privateBeaconData == nil,
           case .keyDistribution = networkKey.phase,
           let oldKeys = networkKey.oldKeys {
            privateBeaconData = Crypto.decodeAndAuthenticate(privateBeacon: pdu, usingPrivateBeaconKey: oldKeys.privateBeaconKey)
        }
        
        // If the beacon stil failed to be authenticated, discard it.
        guard let privateBeaconData = privateBeaconData else {
            return nil
        }
        
        // The beacon is authenticated.
        self.networkKey = networkKey
        self.keyRefreshFlag = privateBeaconData.keyRefreshFlag
        self.ivIndex = privateBeaconData.ivIndex
        self.validForKeyRefreshProcedure = networkKey.oldKey != nil
    }
}
