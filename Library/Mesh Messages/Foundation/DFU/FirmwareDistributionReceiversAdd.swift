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

/// The Firmware Distribution Receivers Add message is an acknowledged message sent by
/// a Firmware Distribution Client to add new entries to the Distribution Receivers List state of
/// a Firmware Distribution Server.
public struct FirmwareDistributionReceiversAdd: StaticAcknowledgedMeshMessage {
    public static let opCode: UInt32 = 0x8311
    public static let responseType: StaticMeshResponse.Type = FirmwareDistributionReceiversStatus.self
    
    /// List of Receiver Entry fields.
    ///
    /// The Receivers List field shall contain at least one Receiver Entry field.
    /// For each Receiver Entry field in the Receivers List field, the value of the
    /// Address field shall be unique.
    public let receivers: [Receiver]
    
    public var parameters: Data? {
        return receivers.reduce(Data()) { data, receiver in data + receiver.address + receiver.imageIndex }
    }
    
    /// The Receiver Entry field.
    public struct Receiver: Sendable {
        /// The Unicast Address of the Target Node.
        ///
        /// For each Receiver Entry field in the Receivers List field, the value of the Address field shall be unique.
        public let address: Address
        /// The index of the firmware image in the Firmware Information List state to be updated.
        public let imageIndex: UInt8
        
        /// Creates the Receiver Entry field.
        ///
        /// - parameters:
        ///   - address: The Unicast Address of the Target Node.
        ///   - imageIndex: The index of the firmware image in the Firmware Information List state to be updated.
        public init(address: Address, imageIndex: UInt8) {
            self.address = address
            self.imageIndex = imageIndex
        }
    }
    
    /// Creates the Firmware Distribution Receivers Add message.
    ///
    /// - parameter receiver: A Receiver Entry field.
    public init(receiver: Receiver) {
        self.receivers = [receiver]
    }
    
    /// Creates the Firmware Distribution Receivers Add message.
    ///
    /// - parameter receivers: List of Receiver Entry fields. The list shall contain at least one receiver.
    ///                        For each Receiver Entry field in the Receivers List field, the value of the
    ///                        ``Receiver/address`` field shall be unique.
    public init(receivers: [Receiver]) {
        self.receivers = receivers
    }
    
    public init?(parameters: Data) {
        // The list shall contain at least one receiver.
        guard parameters.count < 3 else {
            return nil
        }
        
        var receivers: [Receiver] = []
        var index = 0
        while index < parameters.count {
            guard index + 3 <= parameters.count else {
                return nil
            }
            let address: Address = parameters.read(fromOffset: index)
            let imageIndex = parameters[index + 2]
            receivers.append(Receiver(address: address, imageIndex: imageIndex))
            index += 3
        }
        self.receivers = receivers
    }
}
