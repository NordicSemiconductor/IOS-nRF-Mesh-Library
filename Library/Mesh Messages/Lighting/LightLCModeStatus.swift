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

/// The Light LC Mode Status is an unacknowledged message used to report the
/// Light LC Mode state of an Element.
///
/// Light LC Mode is a binary state that determines the mode of operation of the controller,
/// and the state of the binding between the Light LC Linear Output state and the
/// Light Lightness Linear state. 
public struct LightLCModeStatus: StaticMeshResponse {
    public static let opCode: UInt32 = 0x8294
    
    /// Whether the controller is turned on and the binding with the Light Lightness
    /// state is enabled.
    public let controllerStatus: Bool
    
    public var parameters: Data? {
        return Data() + controllerStatus
    }
    
    /// Creates the Light LC Mode Status message.
    ///
    /// - parameter status: The present value of the Light LC Mode state.
    public init(_ status: Bool) {
        self.controllerStatus = status
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 1 else {
            return nil
        }
        self.controllerStatus = parameters[0] == 0x01
    }
    
}
