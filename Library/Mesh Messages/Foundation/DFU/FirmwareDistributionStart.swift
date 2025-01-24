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

/// The Firmware Distribution Start message is an acknowledged message sent by
/// a Firmware Distribution Client to start the firmware image distribution to the Target Nodes
/// in the Distribution Receivers List.
public struct FirmwareDistributionStart: StaticAcknowledgedMeshMessage {
    public static let opCode: UInt32 = 0x8319
    public static let responseType: StaticMeshResponse.Type = FirmwareDistributionStatus.self
    
    /// Index of the application key used in a firmware image distribution
    let applicationKeyIndex: KeyIndex
    /// Time To Live (TTL) value used in a firmware image distribution.
    ///
    /// The TTL value is the maximum number of hops the message is allowed to go through.
    /// Value 0 means, that messages won't be relied and will only be processed by the Nodes
    /// that are in direct range or the connected GATT Proxy Node.
    ///
    /// Valid values are in the range 0...127 (`0x00 - 0x7F`). Value 255 (`0xFF`) means that
    /// the default TTL value is to be used. Other values are Prohibited.
    let ttl: UInt8
    /// The value that is used to calculate when firmware image distribution will be suspended.
    ///
    /// The Timeout is calculated using the following formula:
    /// `Timeout = (10,000 × (Timeout Base + 2)) + (100 × Transfer TTL)` milliseconds.
    let timeoutBase: UInt16
    /// Mode of the transfer.
    ///
    /// This has to be one of ``TransferMode/push`` or ``TransferMode/pull``.
    let transferMode: TransferMode
    /// Firmware update policy.
    ///
    /// The update policy that the Firmware Distribution Server will use for this firmware image distribution.
    let updatePolicy: FirmwareUpdatePolicy
    /// Index of the firmware image in the Firmware Images List state to use during firmware image distribution.
    ///
    /// The maximum supported Firmware Images List Size can be obtained using
    /// ``FirmwareDistributionCapabilitiesGet``.
    let firmwareImageIndex: UInt16
    /// Multicast address used in a firmware image distribution.
    ///
    /// The value of the Distribution Multicast Address field shall be a Group Address, the Label UUID
    /// of a Virtual Address, or the Unassigned Address.
    ///
    /// If the value of the Distribution Multicast Address state is the Unassigned address, then messages
    /// are not sent to a multicast address.
    let multicastAddress: MeshAddress
    
    public var parameters: Data? {
        var data = Data() + applicationKeyIndex + ttl + timeoutBase
        // This takes 2 + 1 bit, 5 bits are Reserved for Future Use:
        data += UInt8((transferMode.rawValue << 6) | (updatePolicy.rawValue << 5))
        data += firmwareImageIndex
        
        if let label = multicastAddress.virtualLabel {
            data += label.data
        } else {
            data += multicastAddress.address
        }
        return data
    }
    
    /// Creates the Firmware Distribution Start message.
    ///
    /// - parameters:
    ///   - firmwareImageIndex: Index of the firmware image in the Firmware Images List state to use
    ///                         during firmware image distribution.
    ///   - multicastAddress: Multicast Address used in a firmware image distribution. By default
    ///                       it is set to an Unassigned Address, which means the firmware will not be
    ///                       sent to a multicast address.
    ///   - applicationKeyIndex: Index of the application key used in a firmware image distribution.
    ///   - distributionTtl: Time To Live (TTL) value used in a firmware image distribution.
    ///                      By default, Distributor's Default TTL will be used.
    ///   - distributionTransferMode: Mode of the transfer, defaults to ``TransferMode/push``.
    ///   - updatePolicy: Firmware update policy, defaults to ``FirmwareUpdatePolicy/verifyAndApply``.
    ///   - distributionTimeoutBase: The value that is used to calculate when firmware image distribution
    ///                              will be suspended.
    public init(
        firmwareWithImageIndex firmwareImageIndex: UInt16,
        to multicastAddress: MeshAddress = MeshAddress(.unassignedAddress),
        usingKeyIndex applicationKeyIndex: KeyIndex,
        ttl distributionTtl: UInt8 = 0xFF,
        mode distributionTransferMode: TransferMode = .push,
        updatePolicy: FirmwareUpdatePolicy = .verifyAndApply,
        distributionTimeoutBase: UInt16
    ) {
        self.applicationKeyIndex = applicationKeyIndex
        self.ttl = distributionTtl
        self.timeoutBase = distributionTimeoutBase
        self.transferMode = distributionTransferMode
        self.updatePolicy = updatePolicy
        self.firmwareImageIndex = firmwareImageIndex
        self.multicastAddress = multicastAddress
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 10 || parameters.count == 24 else {
            return nil
        }
        self.applicationKeyIndex = parameters.read(fromOffset: 0)
        self.ttl = parameters[2]
        self.timeoutBase = parameters.read(fromOffset: 3)
        guard let mode = TransferMode(rawValue: parameters[5] >> 6) else {
            return nil
        }
        self.transferMode = mode
        guard let policy = FirmwareUpdatePolicy(rawValue: (parameters[5] >> 5) & 0x01) else {
            return nil
        }
        self.updatePolicy = policy
        self.firmwareImageIndex = parameters.read(fromOffset: 6)
        if parameters.count == 24 {
            let label = UUID(data: parameters.subdata(in: 8..<24))!
            self.multicastAddress = MeshAddress(label)
        } else {
            let address: Address = parameters.read(fromOffset: 8)
            self.multicastAddress = MeshAddress(address)
        }
    }
}
