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

public struct SceneStatus: GenericMessage, SceneStatusMessage, TransitionStatusMessage {
    public static let opCode: UInt32 = 0x5E
    
    public var parameters: Data? {
        let data = Data([status.rawValue]) + scene
        if let targetScene = targetScene, let remainingTime = remainingTime {
            return data + targetScene + remainingTime.rawValue
        } else {
            return data
        }
    }
    
    public let status: SceneMessageStatus
    /// The number of the current scene.
    public let scene: Scene
    /// The number of the target scene.
    public let targetScene: Scene?
    
    public let remainingTime: TransitionTime?
    
    /// Creates the Scene Status message.
    ///
    /// - parameter scene: The number of the current scene.
    public init(report scene: Scene) {
        self.status = .success
        self.scene = scene
        self.targetScene = nil
        self.remainingTime = nil
    }
    
    /// Creates the Scene Status message.
    ///
    /// - parameters:
    ///   - scene: The number of the current scene.
    ///   - targetScene: The number of the target scene.
    ///   - remainingTime: The time that an element will take to transition
    ///                    to the target state from the present state.
    public init(report scene: Scene, targetScene: Scene, remainingTime: TransitionTime) {
        self.status = .success
        self.scene = scene
        self.targetScene = targetScene
        self.remainingTime = remainingTime
    }
    
    /// Creates the Scene Status message.
    ///
    /// - parameters:
    ///   - status: Operation status.
    ///   - scene: The number of the current scene.
    public init(_ status: SceneMessageStatus, for scene: Scene) {
        self.status = status
        self.scene = scene
        self.targetScene = nil
        self.remainingTime = nil
    }
    
    /// Creates the Scene Status message.
    ///
    /// - parameters:
    ///   - status: Operation status.
    ///   - scene: The number of the current scene.
    ///   - targetScene: The number of the target scene.
    ///   - remainingTime: The time that an element will take to transition
    ///                    to the target state from the present state.
    public init(_ status: SceneMessageStatus, for scene: Scene, targetScene: Scene,
                remainingTime: TransitionTime) {
        self.status = status
        self.scene = scene
        self.targetScene = targetScene
        self.remainingTime = remainingTime
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 3 || parameters.count == 6 else {
            return nil
        }
        guard let status = SceneMessageStatus(rawValue: parameters[0]) else {
            return nil
        }
        self.status = status
        scene = parameters.read(fromOffset: 1)
        if parameters.count == 6 {
            targetScene = parameters.read(fromOffset: 3)
            remainingTime = TransitionTime(rawValue: parameters[5])
        } else {
            targetScene = nil
            remainingTime = nil
        }
    }
    
}
