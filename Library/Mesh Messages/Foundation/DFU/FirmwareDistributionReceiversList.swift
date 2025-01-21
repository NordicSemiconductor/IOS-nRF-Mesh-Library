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

/// The Firmware Distribution Receivers List message is an unacknowledged message sent by
/// the Firmware Distribution Server to report the firmware distribution status of each receiver.
///
/// A Firmware Distribution Receivers List message is sent as a response to
/// a ``FirmwareDistributionReceiversGet`` message.
public struct FirmwareDistributionReceiversList: StaticMeshResponse {
    public static let opCode: UInt32 = 0x8315
    
    /// The total number of entries in the Distribution Receivers List state.
    public let totalCount: UInt16
    /// Index of the first requested entry from the Distribution Receivers List state.
    public let firstIndex: UInt16
    /// List of receivers requested from the Distribution Receivers List state.
    ///
    /// The list starts at ``FirmwareDistributionReceiversGet/firstIndex``
    /// and contains at most ``FirmwareDistributionReceiversGet/entriesLimit`` entries.
    ///
    /// The list is empty if no Entries were found within the requested range.
    public let receivers: [TargetNode]
    
    public var parameters: Data? {
        let initial = Data() + totalCount + firstIndex
        return receivers.reduce(initial) { data, target in
            // Encoding is specified in Table 5.20 in Mesh DFU Specification.
            let byte0: UInt8 = UInt8(target.address & 0xFF)
            let byte1: UInt8 = UInt8((target.address >> 7) & 0xFE) | UInt8((target.phase.rawValue >> 3) & 0x01)
            let byte2: UInt8 = UInt8((target.phase.rawValue << 5) | (target.updateStatus.rawValue << 2) | (target.transferStatus.rawValue >> 2))
            let byte3: UInt8 = UInt8(target.transferStatus.rawValue << 6) | UInt8((target.transferProgress >> 1) & 0x3F)
            let byte4: UInt8 = target.imageIndex
            return data + Data([byte0, byte1, byte2, byte3, byte4])
        }
    }
    
    /// A structure of an entry from the Distribution Receivers List state
    public struct TargetNode: Sendable {
        /// The unicast address of the Target Node.
        public let address: Address
        /// Retrieved Update Phase state of the Target Node.
        public let phase: RetrievedUpdatePhase
        /// Status of the last operation with the Firmware Update Server.
        public let updateStatus: FirmwareUpdateMessageStatus
        /// Status of the last operation with the BLOB Transfer Server.
        public let transferStatus: BLOBTransferMessageStatus
        /// Progress of the BLOB transfer, in percent.
        ///
        /// Due to the message encoding this value will always be even: 0%, 2%, .., 100%.
        public let transferProgress: Int
        /// Index of the firmware image on the Firmware Information List state that is being updated.
        public let imageIndex: UInt8
        
        /// Creates a new Target Node entry.
        ///
        /// - parameters:
        ///  - address: The unicast address of the Target Node.
        ///  - phase: Retrieved Update Phase state of the Target Node.
        ///  - updateStatus: Status of the last operation with the Firmware Update Server.
        ///  - transferStatus: Status of the last operation with the BLOB Transfer Server.
        ///  - transferProgress: Progress of the BLOB transfer, in percent.
        ///  - imageIndex: Index of the firmware image on the Firmware Information List state that is being updated.
        public init(address: Address,
                    phase: RetrievedUpdatePhase,
                    updateStatus: FirmwareUpdateMessageStatus,
                    transferStatus: BLOBTransferMessageStatus,
                    transferProgress: Int,
                    imageIndex: UInt8) {
            self.address = address
            self.phase = phase
            self.updateStatus = updateStatus
            self.transferStatus = transferStatus
            self.transferProgress = (transferProgress / 2) * 2 // Ensure the value is even.
            self.imageIndex = imageIndex
        }
    }
    
    /// Creates the Firmware Distribution Receivers List message.
    ///
    /// This initiator returns the given list of receivers. User is responsible for
    /// providing the correct list of receivers, the first index and the total number
    /// of receivers in the Distribution Receivers List state.
    ///
    /// - parameters:
    ///  - receivers: List of receivers to be returned. This should be a sublist of the Distribution
    ///               Receivers List state starting at index `firstIndex` and contain at most
    ///               `totalCount` entries.
    ///  - firstIndex: Index of the first requested entry from the Distribution Receivers List state.
    ///  - totalCount: The total number of receivers in the Distribution Receivers List state.
    public init(receivers: [TargetNode], from firstIndex: UInt16, outOf totalCount: UInt16) {
        self.totalCount = totalCount
        self.firstIndex = firstIndex
        self.receivers = receivers
    }
    
    /// Creates the Firmware Distribution Receivers List message.
    ///
    /// This initiator takes the complete list of receivers and returns a sublist using the
    /// criteria from the `request`.
    ///
    /// - parameters:
    ///  - request: The received request.
    ///  - receivers: Complete list of receivers in the Distribution Receivers List state.
    public init(responseTo request: FirmwareDistributionReceiversGet, using receivers: [TargetNode]) {
        self.totalCount = UInt16(receivers.count)
        self.firstIndex = request.firstIndex
        if request.firstIndex < receivers.count {
            self.receivers = Array(receivers[Int(request.firstIndex)..<Int(request.firstIndex) + Int(request.entriesLimit)])
        } else {
            self.receivers = []
        }
    }
    
    public init?(parameters: Data) {
        // The receivers list may be omitted if firstIndex was higher then
        // the number of entries. At least 4 bytes are required.
        // Each entry is 5 bytes long.
        guard parameters.count >= 4, (parameters.count - 4) % 5 == 0 else {
            return nil
        }
        self.totalCount = parameters.read(fromOffset: 0)
        self.firstIndex = parameters.read(fromOffset: 2)
        
        var receivers: [TargetNode] = []
        var offset = 4
        while offset < parameters.count {
            let address = Address(parameters[offset]) | (Address(parameters[offset + 1] & 0xFE) << 7)
            let phaseValue = ((parameters[offset + 1] & 0x01) << 3) | ((parameters[offset + 2] & 0xE0) >> 5)
            guard let phase = RetrievedUpdatePhase(rawValue: phaseValue) else {
                return nil
            }
            let updateStateValue = (parameters[offset + 2] & 0x1C) >> 2
            guard let updateStatus = FirmwareUpdateMessageStatus(rawValue: updateStateValue) else {
                return nil
            }
            let transferStateValue = ((parameters[offset + 2] & 0x03) << 2) | ((parameters[offset + 3] & 0xC0) >> 6)
            guard let transferStatus = BLOBTransferMessageStatus(rawValue: transferStateValue) else {
                return nil
            }
            let transferProgress = Int(parameters[offset + 3] & 0x3F) * 2
            let imageIndex = parameters[offset + 4]
            offset += 5
            
            let receiver = TargetNode(address: address,
                                      phase: phase,
                                      updateStatus: updateStatus,
                                      transferStatus: transferStatus,
                                      transferProgress: transferProgress,
                                      imageIndex: imageIndex)
            receivers.append(receiver)
        }
        self.receivers = receivers
    }
}
