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

// MARK: - RangeMessageStatus

/// Enumeration of available statuses of a generic message.
public enum RangeMessageStatus: UInt8 {
    /// The operation was successful.
    case success           = 0x00
    /// The operation failed. Min range cannot be set.
    case cannotSetRangeMin = 0x01
    /// The operation failed. Max range cannot be set.
    case cannotSetRangeMax = 0x02
}

/// A base protocol for generic status messages.
public protocol RangeStatusMessage: StatusMessage {
    /// Operation status.
    var status: RangeMessageStatus { get }
}

public extension RangeStatusMessage {
    
    /// Whether the operation was successful.
    var isSuccess: Bool {
        return status == .success
    }
    
    /// String representation of the status property.
    var message: String {
        return "\(status)"
    }
    
}

extension RangeMessageStatus: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .success:
            return "Success"
        case .cannotSetRangeMin:
            return "Cannot Set Range Min"
        case .cannotSetRangeMax:
            return "Cannot Set Range Max"
        }
    }
    
}

// MARK: - SceneMessageStatus

/// Enumeration of available statuses of a scene message.
public enum SceneMessageStatus: UInt8 {
    /// The operation was successful.
    case success           = 0x00
    /// The scene register is full and cannot store any mode scenes.
    case sceneRegisterFull = 0x01
    /// A scene cannot be recalled, as it has not been found.
    case sceneNotFound     = 0x02
}

/// a base protocol for scene status messages.
public protocol SceneStatusMessage: StatusMessage {
    /// Operation status.
    var status: SceneMessageStatus { get }
}

public extension SceneStatusMessage {
    
    /// Whether the operation was successful.
    var isSuccess: Bool {
        return status == .success
    }
    
    /// String representation of the status property.
    var message: String {
        return "\(status)"
    }
    
}

extension SceneMessageStatus: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .success:
            return "Success"
        case .sceneRegisterFull:
            return "Scene Register Full"
        case .sceneNotFound:
            return "Scene Not Found"
        }
    }
    
}
