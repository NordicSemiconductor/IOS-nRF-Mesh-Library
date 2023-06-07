/*
* Copyright (c) 2019, Nordic Semiconductor
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

import nRFMeshProvision

extension Model: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return modelName
    }
    
    public var modelName: String {
        if let companyIdentifier = companyIdentifier {
            switch (companyIdentifier, modelIdentifier) {
            case (.nordicSemiconductorCompanyId, .simpleOnOffServerModelId): return "Simple OnOff Server"
            case (.nordicSemiconductorCompanyId, .simpleOnOffClientModelId): return "Simple OnOff Client"
            case (.nordicSemiconductorCompanyId, .rssiServer):               return "Rssi Server"
            case (.nordicSemiconductorCompanyId, .rssiClient):               return "Rssi Client"
            case (.nordicSemiconductorCompanyId, .rssiUtil):                 return "Rssi Util"
            case (.nordicSemiconductorCompanyId, .thingy52Server):           return "Thingy52 Server"
            case (.nordicSemiconductorCompanyId, .thingy52Client):           return "Thingy52 Client"
            case (.nordicSemiconductorCompanyId, .chatClient):               return "Chat Client"
            default:
                return "Vendor Model ID: \(modelIdentifier.asString())"
            }
        }
        return name ?? "Unknown Model ID: \(modelIdentifier.asString())"
    }
    
    public var companyName: String {
        if let companyId = companyIdentifier {
            return CompanyIdentifier.name(for: companyId) ??
                   "Unknown Company ID (\(companyId.asString()))"
        } else {
            return "Bluetooth SIG"
        }
    }
    
}
