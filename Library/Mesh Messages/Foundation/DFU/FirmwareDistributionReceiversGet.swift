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

/// The Firmware Distribution Receivers Get message is an acknowledged message sent by
/// the Firmware Distribution Client to get the firmware distribution status of each Target Node.
public struct FirmwareDistributionReceiversGet: StaticAcknowledgedMeshMessage {
    public static let opCode: UInt32 = 0x8314
    public static let responseType: StaticMeshResponse.Type = FirmwareDistributionReceiversList.self
    
    /// Index of the first requested entry from the Distribution Receivers List state.
    public let firstIndex: UInt16
    /// Maximum number of entries that the server includes in a Firmware Distribution
    /// Receivers List message.
    ///
    /// The value of the Entries Limit field shall be greater than 0.
    public let entriesLimit: UInt16
    
    public var parameters: Data? {
        return Data() + firstIndex + entriesLimit
    }
    
    /// Creates the Firmware Distribution Receivers Get message.
    ///
    /// - parameters:
    ///  - firstIndex: Index of the first requested entry from the Distribution Receivers List state.
    ///  - entriesLimit: Maximum number of entries that the server includes in a Firmware Distribution
    ///                  Receivers List message. The value of the Entries Limit field shall be greater than 0.
    public init(from firstIndex: UInt16, limit entriesLimit: UInt16) {
        self.firstIndex = firstIndex
        self.entriesLimit = entriesLimit
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 4 else {
            return nil
        }
        firstIndex = parameters.read(fromOffset: 0)
        entriesLimit = parameters.read(fromOffset: 2)
    }
}
