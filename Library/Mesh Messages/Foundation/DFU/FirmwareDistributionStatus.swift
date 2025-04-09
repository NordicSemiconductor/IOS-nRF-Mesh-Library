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

/// The Firmware Distribution Status message is an unacknowledged message sent by
/// a Firmware Distribution Server to report the status of a firmware image distribution.
///
/// A Firmware Distribution Status message is sent as a response to any of:
/// * ``FirmwareDistributionGet``,
/// * ``FirmwareDistributionStart``,
/// * ``FirmwareDistributionSuspend``,
/// * ``FirmwareDistributionCancel``,
/// * ``FirmwareDistributionApply``.
public struct FirmwareDistributionStatus: StaticMeshResponse {
    public static let opCode: UInt32 = 0x831D
    
    /// Status for the requesting message.
    public let status: FirmwareDistributionMessageStatus
    /// Phase of the firmware image distribution.
    public let phase: FirmwareDistributionPhase
    /// Multicast address used in a firmware image distribution.
    ///
    /// The value of the Distribution Multicast Address field shall be a Group Address
    /// or the Unassigned Address. When using a Label UUID, the status
    /// message provides this value as a Virtual Address.
    public let multicastAddress: Address?
    /// Index of the application key used in a firmware image distribution
    public let applicationKeyIndex: KeyIndex?
    /// Time To Live (TTL) value used in a firmware image distribution.
    ///
    /// The TTL value is the maximum number of hops the message is allowed to go through.
    /// Value 0 means, that messages won't be relied and will only be processed by the Nodes
    /// that are in direct range or the connected GATT Proxy Node.
    ///
    /// Valid values are in the range 0...127 (`0x00 - 0x7F`). Value 255 (`0xFF`) means that
    /// the default TTL value is to be used. Other values are Prohibited.
    public let ttl: UInt8?
    /// The value that is used to calculate when firmware image distribution will be suspended.
    ///
    /// The Timeout is calculated using the following formula:
    /// `Timeout = (10,000 × (Timeout Base + 2)) + (100 × Transfer TTL)` milliseconds.
    public let timeoutBase: UInt16?
    /// Mode of the transfer.
    public let transferMode: TransferMode?
    /// Firmware update policy.
    ///
    /// The update policy that the Firmware Distribution Server will use for this firmware image distribution.
    public let updatePolicy: FirmwareUpdatePolicy?
    /// Index of the firmware image in the Firmware Images List state to use during firmware image distribution.
    public let firmwareImageIndex: UInt16?
    
    public var parameters: Data? {
        var data = Data([status.rawValue, phase.rawValue])
        
        // Optional fields shall be present when the distribution address is present.
        if let address = multicastAddress,
           let keyIndex = applicationKeyIndex,
           let ttl = ttl,
           let timeoutBase = timeoutBase,
           let mode = transferMode,
           let policy = updatePolicy,
           let imageIndex = firmwareImageIndex {
            data += address
            data += keyIndex
            data += ttl
            data += timeoutBase
            // This takes 2 + 1 bit, 5 bits are Reserved for Future Use:
            data += UInt8(mode.rawValue | (policy.rawValue << 2))
            data += imageIndex
        }
        return data
    }
    
    /// Creates the Firmware Distribution Status message for the Idle state.
    ///
    /// - parameter status: Status for the requesting message.
    public init(report status: FirmwareDistributionMessageStatus) {
        self.status = status
        // The following fields shall only be omitted in .idle state.
        self.phase = .idle
        self.multicastAddress = nil
        self.applicationKeyIndex = nil
        self.ttl = nil
        self.timeoutBase = nil
        self.transferMode = nil
        self.updatePolicy = nil
        self.firmwareImageIndex = nil
    }
    
    /// Creates the Firmware Distribution Start message.
    ///
    /// This constructor SHALL NOT be used for ``FirmwareDistributionPhase/idle`` phase,
    /// as then all the parameters shall be omitted. Use ``init(report:)`` instead.
    ///
    /// - parameters:
    ///   - status: Status for the requesting message.
    ///   - phase: Phase of the firmware image distribution.
    ///   - firmwareImageIndex: Index of the firmware image in the Firmware Images List state to use
    ///                         during firmware image distribution.
    ///   - multicastAddress: Multicast or Unicast Address used in a firmware image distribution.
    ///                       When using a Label UUID, the status message provides this value as
    ///                       a Virtual Address.
    ///   - applicationKeyIndex: Index of the application key used in a firmware image distribution.
    ///   - distributionTtl: Time To Live (TTL) value used in a firmware image distribution.
    ///   - distributionTransferMode: Mode of the transfer.
    ///   - updatePolicy: Firmware update policy.
    ///   - distributionTimeoutBase: The value that is used to calculate when firmware image distribution
    ///                              will be suspended.
    public init(
        report status: FirmwareDistributionMessageStatus,
        andPhase phase: FirmwareDistributionPhase,
        ofDistributingFirmwareWithImageIndex firmwareImageIndex: UInt16,
        to multicastAddress: Address,
        usingKeyIndex applicationKeyIndex: KeyIndex,
        ttl distributionTtl: UInt8,
        mode distributionTransferMode: TransferMode,
        updatePolicy: FirmwareUpdatePolicy,
        distributionTimeoutBase: UInt16
    ) {
        self.status = status
        self.phase = phase
        self.firmwareImageIndex = firmwareImageIndex
        self.multicastAddress = multicastAddress
        self.applicationKeyIndex = applicationKeyIndex
        self.ttl = distributionTtl
        self.timeoutBase = distributionTimeoutBase
        self.transferMode = distributionTransferMode
        self.updatePolicy = updatePolicy
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 2 || parameters.count == 12 else {
            return nil
        }
        guard let status = FirmwareDistributionMessageStatus(rawValue: parameters[0]) else {
            return nil
        }
        self.status = status
        guard let phase = FirmwareDistributionPhase(rawValue: parameters[1]) else {
            return nil
        }
        self.phase = phase
        
        if parameters.count == 12 {
            self.multicastAddress = parameters.read(fromOffset: 2)
            self.applicationKeyIndex = parameters.read(fromOffset: 4)
            self.ttl = parameters[6]
            self.timeoutBase = parameters.read(fromOffset: 7)
            
            guard let mode = TransferMode(rawValue: parameters[9] & 0x03) else {
                return nil
            }
            self.transferMode = mode
            guard let policy = FirmwareUpdatePolicy(rawValue: (parameters[9] >> 2) & 0x01) else {
                return nil
            }
            self.updatePolicy = policy
            self.firmwareImageIndex = parameters.read(fromOffset: 10)
        } else {
            self.multicastAddress = nil
            self.applicationKeyIndex = nil
            self.ttl = nil
            self.timeoutBase = nil
            self.transferMode = nil
            self.updatePolicy = nil
            self.firmwareImageIndex = nil
        }
    }
}
