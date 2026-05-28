/*
* Copyright (c) 2026, Nordic Semiconductor
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

import NordicMesh

public extension FirmwareId {
    
    /// A struct representing the version fields required by nRF Cloud Powered by Memfault.
    ///
    /// This version is composed of: HW Version, SW Version and SW Type.
    /// Additionally, the Device Serial is set to the Device UUID.
    struct MemfaultVersion: CustomStringConvertible {
        /// The hardware version.
        let hwVersion: String
        /// The software version.
        let swVersion: String
        /// The software type.
        let swType: String
    
        public var description: String {
            return "\(hwVersion), \(swVersion) (\(swType))"
        }
            
    }
    
    var memfaultVersion: MemfaultVersion? {
        // The current format is as follows:
        // - FWID Type (as per company) (1 byte) - 0xFF - this will change in the future.
        // - HW Version Length (1 byte)
        // - SW Version Length (1 byte)
        // - SW Type Length (1 byte)
        // - HW Version (variable length, at least 1 byte)
        // - SW Version (variable length, at least 1 byte)
        // - SW Type (variable length, at least 1 byte)
        guard version.count >= 7 else {
            return nil
        }
        
        /// The first byte of the version is the type.
        ///
        /// In the initial version the type should be 0xFF. Later this will indicate a format version.
        let type = version[0]
        guard type == 0xFF else {
            return nil
        }
        
        /// The next three bytes indicate the length of the HW version, SW version and SW type strings.
        let hwVersionLength = Int(version[1])
        let swVersionLength = Int(version[2])
        let swTypeLength    = Int(version[3])
        
        // The total length of the version should be equal to the sum of the
        // lengths of the HW version, SW version and SW type strings plus 4 bytes
        // for the type and length fields.
        guard version.count == 4 + hwVersionLength + swVersionLength + swTypeLength else {
            return nil
        }
        
        // If we reach this point, we can safely parse the version string.
        return MemfaultVersion(
            hwVersion: String(data: version[4..<(4 + hwVersionLength)], encoding: .utf8)!,
            swVersion: String(data: version[(4 + hwVersionLength)..<(4 + hwVersionLength + swVersionLength)], encoding: .utf8)!,
            swType: String(data: version[(4 + hwVersionLength + swVersionLength)..<version.endIndex], encoding: .utf8)!
        )
    }
    
}
