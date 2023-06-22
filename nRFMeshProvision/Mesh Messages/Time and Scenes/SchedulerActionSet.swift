/*
* Copyright (c) 2022, Nordic Semiconductor
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

public struct SchedulerActionSet: StaticAcknowledgedMeshMessage {
    public static let opCode: UInt32 = 0x60
    public typealias ResponseType = SchedulerActionStatus
    
    public var parameters: Data? {
        return SchedulerRegistryEntry.marshal(index: index, entry: entry)
    }

    /// The scheduler registry index the message is for.
    public let index: UInt8
    /// The registry entry.
    public let entry: SchedulerRegistryEntry
    
    /// Creates the Scheduler Action Set message.
    ///
    /// - parameters:
    ///   - index: The index of the registry entry. Valid range is 0x00 - 0x0F.
    ///   - entry: The registry entry.
    public init(index: UInt8, entry: SchedulerRegistryEntry) {
        self.index = index
        self.entry = entry
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 80 else {
            return nil
        }
        
        let encode = SchedulerRegistryEntry.unmarshal(parameters)
        self.index = encode.index
        self.entry = encode.entry
    }

}
