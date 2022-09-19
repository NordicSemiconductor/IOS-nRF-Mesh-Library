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

/// This protocol extends ``BearerDelegate`` and adds GATT specific
/// event handlers.
public protocol GattBearerDelegate: BearerDelegate {
    
    /// Callback called when the GATT device has connected.
    ///
    /// - parameter bearer: The Bearer.
    func bearerDidConnect(_ bearer: Bearer)
    
    /// Callback called when the services of the GATT device
    /// have been discovered.
    ///
    /// - parameter bearer: The Bearer.
    func bearerDidDiscoverServices(_ bearer: Bearer)
    
    /// Callback called periodically when a RSSI value to the
    /// GATT Bearer has been obtained.
    ///
    /// - parameters:
    ///   - bearer: The Bearer.
    ///   - RSSI:   The Received Signal Strength Indication
    ///             value, from -127 to around 4.
    func bearer(_ bearer: Bearer, didReadRSSI RSSI: NSNumber)
}

public extension GattBearerDelegate {
    
    func bearerDidConnect(_ bearer: Bearer) {
        // This method is optional.
    }

    func bearerDidDiscoverServices(_ bearer: Bearer) {
        // This method is optional.
    }
    
    func bearer(_ bearer: Bearer, didReadRSSI RSSI: NSNumber) {
        // This method is optional.
    }
    
}
