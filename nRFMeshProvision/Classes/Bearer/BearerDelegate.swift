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

/// A beared data delegate processes mesh messages received by the bearer.
public protocol BearerDataDelegate: AnyObject {
    
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

/// The bearer delegate will receive events when the bearer has been opened
/// or closed.
public protocol BearerDelegate: AnyObject {
    
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
