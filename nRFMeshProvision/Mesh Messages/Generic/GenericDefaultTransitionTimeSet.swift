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

public struct GenericDefaultTransitionTimeSet: StaticAcknowledgedMeshMessage {
    public static let opCode: UInt32 = 0x820E
    public typealias ResponseType = GenericDefaultTransitionTimeStatus
    
    public var parameters: Data? {
        return Data([transitionTime.rawValue])
    }
    
    /// The Default Transition Time field identifies the default time that an
    /// element will take to transition to the target state from the present state.
    public let transitionTime: TransitionTime
    
    /// Creates the Generic Default Transition Time Set message.
    ///
    /// - parameter transitionTime: The default time that an element will take to transition
    ///                             to the target state from the present state.
    public init(transitionTime: TransitionTime) {
        self.transitionTime = transitionTime
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 1 else {
            return nil
        }
        transitionTime = TransitionTime(rawValue: parameters[0])
    }
    
}
