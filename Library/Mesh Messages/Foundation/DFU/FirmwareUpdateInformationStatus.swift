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

/// The Firmware Update Information Status message is an unacknowledged message
/// used to report information about firmware images installed on a Node.
///
/// The Firmware Update Information Status message is sent in response to a
/// ``FirmwareUpdateInformationGet`` message.
public struct FirmwareUpdateInformationStatus: StaticMeshResponse {
    public static let opCode: UInt32 = 0x8309
    
    /// Index of the first requested entry from the Firmware Information List state.
    public let firstIndex: UInt8
    /// List of entries.
    public let entries: [Entry]
    
    public var parameters: Data? {
        return entries.reduce(into: Data([UInt8(entries.count), firstIndex])) { result, entry in
            return result += entry
        }
    }
    
    /// The Firmware Information Entry field shall identify the information for a firmware
    /// subsystem on the Node from the Firmware Information List state.
    public struct Entry: DataConvertible {
        /// Identifies the firmware image on the Node or any subsystem on the Node.
        public let currentFirmwareId: FirmwareId
        /// URI used to retrieve a new firmware image (optional).
        public let updateUri: URL?
        
        public init(currentFirmwareId: FirmwareId, updateUri: URL?) {
            self.currentFirmwareId = currentFirmwareId
            self.updateUri = updateUri
        }
        
        public static func + (lhs: Data, rhs: Entry) -> Data {
            let idLength = UInt8(rhs.currentFirmwareId.version.count + 2)
            let uriLength = UInt8(rhs.updateUri?.absoluteString.lengthOfBytes(using: .utf8) ?? 0)
            return lhs + idLength + rhs.currentFirmwareId + uriLength + (rhs.updateUri?.absoluteString.data(using: .utf8) ?? Data())
        }
    }
    
    /// Creates a Firmware Update Information Status message with given parameters.
    ///
    /// - parameters:
    ///   - firstIndex:Index of the first requested entry from the Firmware Information List state.
    ///   - entries:List of entries.
    public init(from firstIndex: UInt8, entries: [Entry]) {
        self.firstIndex = firstIndex
        self.entries = entries
    }
    
    public init?(parameters: Data) {
        guard parameters.count >= 2 else {
            return nil
        }
        let count = parameters[0]
        let firstIndex = parameters[1]
        
        var entries: [Entry] = []
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
            
            let entry = Entry(currentFirmwareId: currentFirmwareId, updateUri: updateUri)
            entries.append(entry)
        }
        guard count == entries.count else {
            return nil
        }
        self.firstIndex = firstIndex
        self.entries = entries
    }
}
