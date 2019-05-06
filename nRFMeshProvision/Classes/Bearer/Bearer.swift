//
//  Bearer.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 02/05/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation

protocol BearerDelegate: class {
    
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
    ///
    /// - parameter bearer: The Bearer on which the data were received.
    /// - parameter data:   The data received.
    func bearer(_ bearer: Bearer, didDeliverData data: Data)
}

protocol Bearer: class {
    /// The Bearer delegate object will receive callbacks when a message
    /// has been obtained from the Bearer.
    var delegate: BearerDelegate? { get set }
    
    /// This method sends the given data over the bearer.
    /// If the data length exceeds the MTU, it should
    /// be segmented before calling this method.
    ///
    /// - parameter data: The data to be sent over the Bearer.
    func send(_ data: Data)
}
