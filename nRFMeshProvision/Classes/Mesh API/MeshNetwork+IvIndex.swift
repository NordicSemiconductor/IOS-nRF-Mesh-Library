/*
* Copyright (c) 2021, Nordic Semiconductor
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

public extension MeshNetwork {
    
    /// Restores the last value of IV Index.
    func restoreIvIndex() {
        let defaults = UserDefaults(suiteName: uuid.uuidString)!
        let map = defaults.object(forKey: IvIndex.indexKey) as? [String : Any]
        ivIndex = IvIndex.fromMap(map) ?? IvIndex()
    }
 
    /// Sets new value of IV Index and IV Update flag.
    ///
    /// This method allows setting the IV Index of the mesh network when the provisioner
    /// is not connected to the network and did not receive the Secure Network beacon,
    /// for example to provision a Node.
    ///
    /// Otherwise, if the local Node is connecting to the mesh network using GATT Proxy,
    /// it will obtain the current IV Index automatically just after connection using the
    /// Secure Network beacon, in which case calling this method is not necessary.
    ///
    /// - important: Mind, that it is no possible to revert IV Index to smaller value
    ///              (at least not using the public API). If you set too high IV Index
    ///              the phone will not be able to communicate with the mesh network.
    ///              Always use the current IV Index of the mesh network.
    ///
    /// - parameters:
    ///   - index: The new value of IV Index.
    ///   - updateActive: IV Update Active flag.
    /// - throws: ``MeshNetworkError/ivIndexTooSmall`` when the new IV Index is
    ///           lower than the current one.
    func setIvIndex(_ index: UInt32, updateActive: Bool) throws {
        let newIvIndex = IvIndex(index: index, updateActive: updateActive)
        
        // Verify that the new IV Index is greater than or equal to the current one.
        guard newIvIndex >= ivIndex else {
            throw MeshNetworkError.ivIndexTooSmall
        }
        // If they are equal, we're done.
        if ivIndex == newIvIndex {
            return
        }
        // Update and save the IV Index.
        ivIndex = newIvIndex
        
        let defaults = UserDefaults(suiteName: uuid.uuidString)!
        defaults.set(ivIndex.asMap, forKey: IvIndex.indexKey)
        // As the IV Index was set using abnormal operation, we have to assume that the
        // IV Recovery is active.
        defaults.set(true, forKey: IvIndex.ivRecoveryKey)
        defaults.set(Date(), forKey: IvIndex.timestampKey)
    }
    
}
