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
import NordicMesh

/// Model class for firmware information specified in Mesh DFU specification.
///
/// This object is parsed from a JSON returned from an online resource
/// pointed by a Node in its Firmware Image List state.
struct UpdatedFirmwareInformation: Codable {
    let manifest: Manifest

    struct Manifest: Codable {
        let firmware: Firmware
     
        struct Firmware: Codable {
            let firmwareIdString: String
            let dfuChainSize: Int
            let firmwareImageFileSize: Int
            
            /// The Firmware ID of the firmware image.
            var firmwareId: FirmwareId? {
                let data = Data(hex: firmwareIdString)
                return FirmwareId(data: data)
            }
            
            // MARK: - Codable
            
            /// Coding keys used to export / import Application Keys.
            enum CodingKeys: String, CodingKey {
                case firmwareIdString = "firmware_id"
                case dfuChainSize = "dfu_chain_size"
                case firmwareImageFileSize = "firmware_image_file_size"
            }
        }
    }
}
