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

internal protocol KeySet {
    /// The Network Key used to encrypt the message.
    var networkKey: NetworkKey { get }
    /// The Access Layer key used to encrypt the message.
    var accessKey: Data { get }
    /// Application Key identifier, or `nil` for Device Key.
    var aid: UInt8? { get }
}

internal struct AccessKeySet: KeySet {
    let applicationKey: ApplicationKey
    
    var networkKey: NetworkKey {
        return applicationKey.boundNetworkKey
    }
    
    var accessKey: Data {
        if case .distributingKeys = networkKey.phase {
            return applicationKey.oldKey ?? applicationKey.key
        }
        return applicationKey.key
    }
    
    var aid: UInt8? {
        if case .distributingKeys = networkKey.phase {
            return applicationKey.oldAid ?? applicationKey.aid
        }
        return applicationKey.aid
    }
}

internal struct DeviceKeySet: KeySet {
    let networkKey: NetworkKey
    let node: Node
    
    var aid: UInt8? = nil
    var accessKey: Data {
        return node.deviceKey
    }
    
    init(networkKey: NetworkKey, node: Node) {
        self.networkKey = networkKey
        self.node = node
    }
}

extension AccessKeySet: CustomDebugStringConvertible {
    
    var debugDescription: String {
        return "\(applicationKey)"
    }
    
}

extension DeviceKeySet: CustomDebugStringConvertible {
    
    var debugDescription: String {
        return "\(node.name ?? "Unknown device")'s Device Key"
    }
    
}
