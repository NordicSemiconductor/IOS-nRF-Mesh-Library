/*
* Copyright (c) 2023, Nordic Semiconductor
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

/// A Remote Provisioning Extended Scan Start message is an unacknowledged message
/// that is used by the Remote Provisioning Client to request additional information
/// about a specific unprovisioned device or about the Remote Provisioning Server itself.
public struct RemoteProvisioningExtendedScanStart: UnacknowledgedRemoteProvisioningMessage {
    public static let opCode: UInt32 = 0x8056
    
    /// Number of AD Types in the ADTypeFilter field.
    ///
    /// The value must be in range from 1 to 16.
    public let adTypeFilterCount: UInt8
    /// List of AD Types to be reported.
    ///
    /// The list shall not contain the following AD Types:
    /// - Shortened Local Name AD Type,
    /// - Incomplete List of  16-bit Service UUIDs AD Type,
    /// - Incomplete List of  32-bit Service UUIDs AD Type,
    /// - Incomplete List of 128-bit Service UUIDs AD Type.
    ///
    /// The filter shall not contain more than one of the same AD type values.
    ///
    /// If the filter contains the Complete Local Name AD Type, the client is
    /// requesting either the Complete Local Name or the Shortened Local Name.
    public let adTypeFilter: [UInt8]
    /// If present, the UUID field identifies the Device UUID of the unprovisioned
    /// device for which additional information is requested. If the UUID field
    /// is `nil`, the request retrieves information about the Remote Provisioning Server.
    public let uuid: UUID?
    /// Time limit for a scan (in seconds) in range from 1 to 21 (0x15).
    ///
    /// The value will be rounded down to whole seconds.
    public let timeout: TimeInterval?
    
    public var parameters: Data? {
        let data = Data([adTypeFilterCount]) + adTypeFilter
        if let uuid = uuid, let timeout = timeout {
            return data + uuid.data + Data([UInt8(timeout)])
        }
        return data
    }
    
    /// Creates Remote Provisioning Scan Start message to request advertisement
    /// information from the unprovisioned device identified by the UUID.
    ///
    /// The following AD Types will be removed from the list as Prohibited:
    /// - Shortened Local Name AD Type,
    /// - Incomplete List of  16-bit Service UUIDs AD Type,
    /// - Incomplete List of  32-bit Service UUIDs AD Type,
    /// - Incomplete List of 128-bit Service UUIDs AD Type.
    ///
    /// Duplicate items will not be added.
    ///
    /// The initiator returns `nil` if the filtered list is empty, or has more than
    /// 16 AD Types.
    ///
    /// If the filter contains the Complete Local Name AD Type, the client is
    /// requesting either the Complete Local Name or the Shortened Local Name.
    ///
    /// - parameters:
    ///   - filter: List of AD Types to be reported.
    ///   - uuid: The Device UUID of the unprovisioned device for which additional
    ///           information is requested.
    ///   - timeout: Time limit for a scan (in seconds). The value will be rounded down
    ///              to whole seconds.
    public init?(filter: [UInt8], uuid: UUID, timeout: TimeInterval) {
        // Remove duplicates and prohibited values.
        var set = Set<UInt8>()
        let filter = filter
            .filter {
                $0 != 0x08 && // Shortened Local Name
                $0 != 0x02 && // Incomplete List of  16­-bit Service Class UUIDs
                $0 != 0x04 && // Incomplete List of  32-bit Service Class UUIDs
                $0 != 0x06    // Incomplete List of 128-bit Service Class UUIDs
            }
            .filter { set.insert($0).inserted }
        // Validate.
        guard filter.count > 0 && filter.count <= 0x10 else {
            return nil
        }
        self.adTypeFilterCount = UInt8(filter.count)
        self.adTypeFilter = filter
        self.timeout = timeout
        self.uuid = uuid
    }
    
    /// Creates Remote Provisioning Scan Start message to request information
    /// from the Remote Provisioning Server.
    ///
    /// The following AD Types will be removed from the list as Prohibited:
    /// - Shortened Local Name AD Type,
    /// - Incomplete List of  16-bit Service UUIDs AD Type,
    /// - Incomplete List of  32-bit Service UUIDs AD Type,
    /// - Incomplete List of 128-bit Service UUIDs AD Type.
    ///
    /// Duplicate items will not be added.
    ///
    /// The initiator returns `nil` if the filtered list is empty, or has more than
    /// 16 AD Types.
    ///
    /// If the filter contains the Complete Local Name AD Type, the client is
    /// requesting either the Complete Local Name or the Shortened Local Name.
    ///
    /// - parameter filter: List of AD Types to be reported.
    public init?(filter: [UInt8]) {
        // Remove duplicates and prohibited values.
        var set = Set<UInt8>()
        let filter = filter
            .filter {
                $0 != 0x08 && // Shortened Local Name
                $0 != 0x02 && // Incomplete List of  16­-bit Service Class UUIDs
                $0 != 0x04 && // Incomplete List of  32-bit Service Class UUIDs
                $0 != 0x06    // Incomplete List of 128-bit Service Class UUIDs
            }
            .filter { set.insert($0).inserted }
        // Validate.
        guard filter.count > 0 && filter.count <= 0x10 else {
            return nil
        }
        self.adTypeFilterCount = UInt8(filter.count)
        self.adTypeFilter = filter
        self.timeout = nil
        self.uuid = nil
    }
    
    /// Creates Remote Provisioning Scan Start message to request advertisement
    /// information from the unprovisioned device identified by the UUID.
    ///
    /// If the filter contains the ``AdTypes/localName`` AD Type, the client is
    /// requesting either the Complete Local Name or the Shortened Local Name.
    ///
    /// - note: It is not possible to request more than 16 AD Types using this method.
    ///
    /// - parameters:
    ///   - filter: AD Types to be reported.
    ///   - uuid: The Device UUID of the unprovisioned device for which additional
    ///           information is requested.
    ///   - timeout: Time limit for a scan (in seconds). The value will be rounded down
    ///              to whole seconds.
    public init(filter: AdTypes, uuid: UUID, timeout: TimeInterval) {
        self.init(filter: [filter], uuid: uuid, timeout: timeout)
    }
    
    /// Creates Remote Provisioning Scan Start message to request advertisement
    /// information from the unprovisioned device identified by the UUID.
    ///
    /// If the filter contains the ``AdTypes/localName`` AD Type, the client is
    /// requesting either the Complete Local Name or the Shortened Local Name.
    ///
    /// - note: It is not possible to request more than 16 AD Types using this method.
    ///
    /// - parameters:
    ///   - filter: AD Types to be reported.
    ///   - uuid: The Device UUID of the unprovisioned device for which additional
    ///           information is requested.
    ///   - timeout: Time limit for a scan (in seconds). The value will be rounded down
    ///              to whole seconds.
    public init(filter: [AdTypes], uuid: UUID, timeout: TimeInterval) {
        let types = filter.flatMap { $0.adTypes }
        self.adTypeFilterCount = UInt8(types.count)
        self.adTypeFilter = types.map { $0.rawValue }
        self.timeout = timeout
        self.uuid = uuid
    }
    
    /// Creates Remote Provisioning Scan Start message to request advertisement
    /// information from the unprovisioned device identified by the UUID.
    ///
    /// If the filter contains the ``AdTypes/localName`` AD Type, the client is
    /// requesting either the Complete Local Name or the Shortened Local Name.
    ///
    /// - note: It is not possible to request more than 16 AD Types using this method.
    ///
    /// - parameter adTypeFilter: AD Types to be reported.
    public init(filter: AdTypes) {
        self.init(filter: [filter])
    }
    
    /// Creates Remote Provisioning Scan Start message to request advertisement
    /// information from the unprovisioned device identified by the UUID.
    ///
    /// If the filter contains the ``AdTypes/localName`` AD Type, the client is
    /// requesting either the Complete Local Name or the Shortened Local Name.
    ///
    /// - note: It is not possible to request more than 16 AD Types using this method.
    ///
    /// - parameter adTypeFilter: AD Types to be reported.
    public init(filter: [AdTypes]) {
        let types = filter.flatMap { $0.adTypes }
        self.adTypeFilterCount = UInt8(types.count)
        self.adTypeFilter = types.map { $0.rawValue }
        self.timeout = nil
        self.uuid = nil
    }
    
    public init?(parameters: Data) {
        guard parameters.count > 1 else {
            return nil
        }
        let count = Int(parameters[0])
        guard parameters.count == 1 + count || parameters.count == 1 + count + 17 else {
            return nil
        }
        adTypeFilterCount = parameters[0]
        adTypeFilter = parameters.subdata(in: 1..<1 + count).map { $0 }
        if parameters.count > 1 + count {
            uuid = UUID(data: parameters.subdata(in: 1 + count ..< 1 + count + 16))
            timeout = TimeInterval(parameters[1 + count + 16])
        } else {
            uuid = nil
            timeout = nil
        }
    }
}
