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

internal protocol NetworkBeaconPdu: BeaconPdu {
    /// The Network Key related to this beacon.
    var networkKey: NetworkKey { get }
    /// A flag indicating whether the beacon has been secured using the
    /// new Network Key during Key Refresh Procedure.
    var validForKeyRefreshProcedure: Bool { get }
    /// Key Refresh flag value.
    ///
    /// When this flag is active, the Node shall set the Key Refresh
    /// Phase for this Network Key to ``KeyRefreshPhase/usingNewKeys``.
    ///
    /// When in this phase:
    /// * the Node shall only transmit messages and beacons using the new keys,
    /// * shall receive messages using the old keys and the new keys,
    /// * shall only receive Secure Network and Private beacons secured using
    ///   the new Network Key.
    var keyRefreshFlag: Bool { get }
    /// The IV Index carried by this beacon.
    var ivIndex: IvIndex { get }
    
    /// Creates beacon PDU object from received PDU.
    ///
    /// - parameters:
    ///   - pdu: The data received from mesh network.
    ///   - networkKey: The Network Key to validate the beacon.
    /// - returns: The beacon object, or `nil` if the data are invalid.
    init?(decode pdu: Data, usingNetworkKey networkKey: NetworkKey)
}

internal extension NetworkBeaconPdu {
    
    /// This method returns whether the received network beacon can override the current IV Index.
    ///
    /// The following restrictions apply:
    /// 1. Normal Operation state must last for at least 96 hours.
    /// 2. IV Update In Progress state must take at least 96 hours and may not be longer than 144h.
    /// 3. IV Index must not decrease.
    /// 4. If received Secure Network beacon or Private beacon has IV Index greater than current
    ///    IV Index + 1, the device will go into IV Index Recovery procedure. In this state,
    ///    the 96h rule does not apply and the IV Index or IV Update Active flag may change before 96 hours.
    /// 5. If received Secure Network beacon or Private beacon has IV Index greater than current
    ///    IV Index + 42, the beacon should be ignored (unless a setting
    ///    ``MeshNetworkManager/ivUpdateTestMode`` is set to disable this rule).
    /// 6. The node shall not execute more than one IV Index Recovery within a period of 192 hours.
    ///
    /// Note: Library versions before 2.2.2 did not store the last IV Index, so the date and IV Recovery
    ///       flag are optional.
    ///
    /// - parameters:
    ///   - target: The IV Index to compare.
    ///   - date: The date of the most recent transition to the current IV Index.
    ///   - ivRecoveryActive: True if the IV Recovery procedure was used to restore
    ///                       the IV Index on the previous connection.
    ///   - ivTestMode: True, if IV Update test mode is enabled; false otherwise.
    ///   - ivRecoveryOver42Allowed: Whether the IV Index Recovery procedure should be limited
    ///                              to allow maximum increase of IV Index by 42.
    /// - returns: True, if the network information can be applied; false otherwise.
    /// - since: 2.2.2
    /// - seeAlso: Bluetooth Mesh Profile 1.0.1, section 3.10.5.
    func canOverwrite(ivIndex target: IvIndex, updatedAt date: Date?,
                      withIvRecovery ivRecoveryActive: Bool,
                      testMode: Bool,
                      andUnlimitedIvRecoveryAllowed ivRecoveryOver42Allowed: Bool) -> Bool {
        // IV Index must increase, or, in case it's equal to the current one,
        // the IV Update Active flag must change from true to false.
        // The new index must not be greater than the current one + 42,
        // unless this rule is disabled.
        guard (ivIndex.index > target.index &&
                (ivRecoveryOver42Allowed || ivIndex.index <= target.index + 42)
              ) ||
              (ivIndex.index == target.index &&
                (target.updateActive || !ivIndex.updateActive)
              ) else {
            return false
        }
        // Staring from version 2.2.2 the date will not be nil.
        if let date = date {
            // Let's define a "state" as a pair of IV and IV Update Active flag.
            // "States" change as follows:
            // 1. IV = X,   IVUA = false (Normal Operation)
            // 2. IV = X+1, IVUA = true  (Update In Progress)
            // 3. IV = X+1, IVUA = false (Normal Operation)
            // 4. IV = X+2, IVUA = true  (Update In Progress)
            // 5. ...
            
            // Calculate number of states between the state defined by the target
            // IV Index and this Secure Network Beacon.
            let stateDiff = Int(ivIndex.index - target.index) * 2 - 1
                + (target.updateActive ? 1 : 0)
                + (ivIndex.updateActive ? 0 : 1)
                - (ivRecoveryActive || testMode ? 1 : 0) // this may set stateDiff = -1
            
            // Each "state" must last for at least 96 hours.
            // Calculate the minimum number of hours that had to pass since last state
            // change for the beacon to be assumed valid.
            // If more has passed, it's also valid, as Normal Operation has no maximum
            // time duration.
            let numberOfHoursRequired = stateDiff * 96
            
            // Get the number of hours since the state changed last time.
            let numberOfHoursSinceDate = Int(-date.timeIntervalSinceNow / 3600)
            
            // The node shall not execute more than one IV Index Recovery within a
            // period of 192 hours.
            if ivRecoveryActive && stateDiff > 1 && numberOfHoursSinceDate < 192 {
                return false
            }
            
            return numberOfHoursSinceDate >= numberOfHoursRequired
        }
        // Before version 2.2.2 the timestamp was not stored.
        // The initial Secure Network beacon or Private beacon is assumed to be valid.
        return true
    }
    
}

internal struct NetworkBeaconDecoder {
    private init() {}
    
    /// This method goes over all Network Keys in the mesh network and tries
    /// to parse the beacon.
    ///
    /// - parameters:
    ///   - pdu:         The received PDU.
    ///   - meshNetwork: The mesh network for which the PDU should be decoded.
    /// - returns: The beacon object.
    static func decode(_ pdu: Data, for meshNetwork: MeshNetwork) -> NetworkBeaconPdu? {
        guard pdu.count > 1, let beaconType = BeaconType(rawValue: pdu[0]) else {
            return nil
        }
        switch beaconType {
        case .secureNetwork:
            for networkKey in meshNetwork.networkKeys {
                if let beacon = SecureNetworkBeacon(decode: pdu, usingNetworkKey: networkKey) {
                    return beacon
                }
            }
            return nil
        case .private:
            for networkKey in meshNetwork.networkKeys {
                if let beacon = PrivateBeacon(decode: pdu, usingNetworkKey: networkKey) {
                    return beacon
                }
            }
            return nil
        default:
            return nil
        }
    }
    
}
