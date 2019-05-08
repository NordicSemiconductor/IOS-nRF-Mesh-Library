//
//  BearerDelegate.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 08/05/2019.
//

import Foundation

public protocol BearerDelegate: class {
    
    /// Callback called when the Bearer is ready for use.
    ///
    /// - parameter bearer: The Bearer.
    func bearerDidOpen(_ bearer: Bearer)
    
    /// Callback called when the Bearer is no longer open.
    ///
    /// - parameter bearer: The Bearer.
    /// - parameter error:  The reason of closing the Bearer, or `nil`
    ///                     if closing was intended.
    func bearer(_ bearer: Bearer, didClose error: Error?)
    
    /// Callback called when a packet has been received using the Bearer.
    /// Data longer than MTU will automatically be reassembled
    /// using the bearer protocol if bearer implements segmentation.
    ///
    /// - parameter bearer: The Bearer on which the data were received.
    /// - parameter data:   The data received.
    func bearer(_ bearer: Bearer, didDeliverData data: Data)
}

public extension BearerDelegate {
    
    func bearer(_ bearer: Bearer, didDeliverData data: Data) {
        // This method is optional.
    }
    
}
