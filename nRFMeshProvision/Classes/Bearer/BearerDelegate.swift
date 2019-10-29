//
//  BearerDelegate.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 08/05/2019.
//

import Foundation

public protocol BearerDataDelegate: class {
    
    /// Callback called when a packet has been received using the Bearer.
    /// Data longer than MTU will automatically be reassembled
    /// using the bearer protocol if bearer implements segmentation.
    ///
    /// - parameters:
    ///   - bearer: The Bearer on which the data were received.
    ///   - data:   The data received.
    ///   - type:   The type of the received data.
    func bearer(_ bearer: Bearer, didDeliverData data: Data, ofType type: PduType)
    
}

public protocol BearerDelegate: class {
    
    /// Callback called when the Bearer is ready for use.
    ///
    /// - parameter bearer: The Bearer.
    func bearerDidOpen(_ bearer: Bearer)
    
    /// Callback called when the Bearer is no longer open.
    ///
    /// - parameters:
    ///   - bearer: The Bearer.
    ///   - error:  The reason of closing the Bearer, or `nil`
    ///             if closing was intended.
    func bearer(_ bearer: Bearer, didClose error: Error?)
    
}
