/*
* Copyright (c) 2025, Nordic Semiconductor
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

/// The Firmware Update Information Get message is an acknowledged message used
/// to get information about the firmware images installed on a Node.
public struct FirmwareUpdateInformationGet: StaticAcknowledgedMeshMessage {
    public static let opCode: UInt32 = 0x8308
    public static let responseType: StaticMeshResponse.Type = FirmwareUpdateInformationStatus.self
    
    /// The First Index field shall indicate the first entry on the Firmware Information List
    /// state of the Firmware Update Server to return in the Firmware Update Information
    /// Status message.
    public let firstIndex: UInt8
    /// The Entries Limit field shall indicate the maximum number of Firmware Information
    /// Entry fields to return in the Firmware Update Information Status message.
    public let entriesLimit: UInt8
    
    public var parameters: Data? {
        return Data([firstIndex, entriesLimit])
    }
    
    public init(from firstIndex: UInt8, limit entriesLimit: UInt8) {
        self.firstIndex = firstIndex
        self.entriesLimit = entriesLimit
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 2 else {
            return nil
        }
        firstIndex = parameters[0]
        entriesLimit = parameters[1]
    }
}
