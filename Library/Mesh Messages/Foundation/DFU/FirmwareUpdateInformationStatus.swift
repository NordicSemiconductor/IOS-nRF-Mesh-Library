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

/// The Firmware Update Information Status message is an unacknowledged message
/// used to report information about firmware images installed on a Node.
///
/// The Firmware Update Information Status message is sent in response to a
/// ``FirmwareUpdateInformationGet`` message.
public struct FirmwareUpdateInformationStatus: StaticMeshResponse {
    public static let opCode: UInt32 = 0x8309
    
    /// The total number of entries in the Firmware Information List state.
    public let totalCount: UInt8
    /// Index of the first requested entry from the Firmware Information List state.
    public let firstIndex: UInt8
    /// List of entries.
    ///
    /// The list starts at ``FirmwareUpdateInformationGet/firstIndex``
    /// and contains at most ``FirmwareUpdateInformationGet/entriesLimit`` entries.
    ///
    /// The list is empty if no Entries were found within the requested range.
    public let list: [FirmwareInformation]
    
    public var parameters: Data? {
        let initial = Data([totalCount, firstIndex])
        return list.reduce(initial) { data, entry in
            let idLength = UInt8(entry.currentFirmwareId.version.count + 2)
            let uriLength = UInt8(entry.updateUri?.absoluteString.lengthOfBytes(using: .utf8) ?? 0)
            let uriData = entry.updateUri?.absoluteString.data(using: .utf8) ?? Data()
            return data + Data([idLength]) + entry.currentFirmwareId.companyIdentifier + entry.currentFirmwareId.version + uriLength + uriData
        }
    }
    
    /// The Firmware Information Entry field shall identify the information for a firmware
    /// subsystem on the Node from the Firmware Information List state.
    public struct FirmwareInformation: Sendable, CustomDebugStringConvertible {
        /// Identifies the firmware image on the Node or any subsystem on the Node.
        public let currentFirmwareId: FirmwareId
        /// URI used to retrieve a new firmware image (optional).
        ///
        /// The Update URI state indicates the location of the new firmware archive file.
        /// The Update URI state shall be either a URI, or it shall be empty. If the Update URI
        /// state is not empty, then it shall be formatted as the URI data type is defined in CSS
        /// and shall use the `https` scheme.
        public let updateUri: URL?
        
        /// Creates a new Firmware Information Entry.
        ///
        /// - parameters:
        ///  - currentFirmwareId: Identifies the firmware image on the Node or any subsystem on the Node.
        ///  - updateUri: URI used to retrieve a new firmware image (optional).
        public init(currentFirmwareId: FirmwareId, updateUri: URL?) {
            self.currentFirmwareId = currentFirmwareId
            self.updateUri = updateUri
        }
        
        public var debugDescription: String {
            let companyId = "0x\(currentFirmwareId.companyIdentifier.hex)"
            let versionString = currentFirmwareId.version.isEmpty ? "nil" : "0x\(currentFirmwareId.version.hex)"
            return "FirmwareInformation(companyId: \(companyId), version: \(versionString), updateUri: \(updateUri?.absoluteString ?? "nil"))"
        }
    }
    
    /// Creates a Firmware Update Information Status message with given parameters.
    ///
    /// This initiator returns the given list of receivers. User is responsible for
    /// providing the correct list of entries, the first index and the total size of the
    /// Firmware Information List state.
    ///
    /// - parameters:
    ///   - list:List of entries to be reported.  This should be a sublist of the Firmware
    ///          Information List state starting at index `firstIndex` and contain at most
    ///          `totalCount` entries.
    ///   - firstIndex:Index of the first requested entry from the Firmware Information List state.
    ///   - totalCount: The total number of entries in the Firmware Information List state.
    public init(list: [FirmwareInformation], from firstIndex: UInt8, outOf totalCount: UInt8) {
        self.list = list
        self.firstIndex = firstIndex
        self.totalCount = totalCount
    }
    
    /// Creates the Firmware Update Information Status message.
    ///
    /// This initiator takes the complete Firmware Information List and returns a sublist using the
    /// criteria from the `request`.
    ///
    /// - parameters:
    ///  - request: The received request.
    ///  - list: Complete list of entries in the Firmware Information List state.
    public init(responseTo request: FirmwareUpdateInformationGet, using list: [FirmwareInformation]) {
        self.totalCount = UInt8(list.count)
        self.firstIndex = request.firstIndex
        if request.firstIndex < list.count {
            self.list = Array(list[Int(request.firstIndex)..<Int(request.firstIndex) + Int(request.entriesLimit)])
        } else {
            self.list = []
        }
    }
    
    public init?(parameters: Data) {
        guard parameters.count >= 2 else {
            return nil
        }
        self.totalCount = parameters[0]
        self.firstIndex = parameters[1]
        
        var list: [FirmwareInformation] = []
        var offset = 2
        while offset < parameters.count {
            // Decode Firmware ID
            let currentFirmwareIdLength = Int(parameters[offset])
            offset += 1
            
            guard currentFirmwareIdLength >= 2 && currentFirmwareIdLength <= 2 + 106,
                  parameters.count >= offset + currentFirmwareIdLength else {
                return nil
            }
            let cid: UInt16 = parameters.read(fromOffset: offset)
            let version: Data = parameters.subdata(in: offset + 2..<offset + currentFirmwareIdLength)
            let currentFirmwareId = FirmwareId(companyIdentifier: cid, version: version)
            offset += currentFirmwareIdLength
            
            // Decode Update URI
            guard parameters.count >= offset + 1 else {
                return nil
            }
            
            let updateUriLength = Int(parameters[offset])
            offset += 1
            
            guard updateUriLength >= 0,
                  parameters.count >= offset + updateUriLength else {
                return nil
            }
            var updateUri: URL? = nil
            if (updateUriLength > 0) {
                let updateUriString = String(decoding: parameters.subdata(in: offset..<offset + updateUriLength), as: UTF8.self)
                updateUri = URL(string: updateUriString)
            }
            offset += updateUriLength
            
            let entry = FirmwareInformation(currentFirmwareId: currentFirmwareId, updateUri: updateUri)
            list.append(entry)
        }
        self.list = list
    }
}
