//
//  GattBearerDelegate.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 08/05/2019.
//

import Foundation

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
