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

import Foundation
import CoreBluetooth

// MARK: - Mesh service identifires

public protocol MeshService {
    static var uuid: CBUUID { get }
    static var dataInUuid:  CBUUID { get }
    static var dataOutUuid: CBUUID { get }
    
    static func matches(_ service: CBService) -> Bool
}

public struct MeshProvisioningService: MeshService {
    public static let uuid        = CBUUID(string: "1827")
    public static let dataInUuid  = CBUUID(string: "2ADB")
    public static let dataOutUuid = CBUUID(string: "2ADC")
    
    public static func matches(_ service: CBService) -> Bool {
        return service.isMeshProvisioningService
    }
    
    private init() {}
}

public struct MeshProxyService: MeshService {
    public static let uuid        = CBUUID(string: "1828")
    public static let dataInUuid  = CBUUID(string: "2ADD")
    public static let dataOutUuid = CBUUID(string: "2ADE")
    
    public static func matches(_ service: CBService) -> Bool {
        return service.isMeshProxyService
    }
    
    private init() {}
}

public extension CBService {
    
    var isMeshProvisioningService: Bool {
        return uuid == MeshProvisioningService.uuid
    }
    
    var isMeshProxyService: Bool {
        return uuid == MeshProxyService.uuid
    }
    
}

public extension CBCharacteristic {
    
    var isMeshProvisioningDataInCharacteristic: Bool {
        return uuid == MeshProvisioningService.dataInUuid
    }
    
    var isMeshProvisioningDataOutCharacteristic: Bool {
        return uuid == MeshProvisioningService.dataOutUuid
    }
    
    var isMeshProxyDataInCharacteristic: Bool {
        return uuid == MeshProxyService.dataInUuid
    }
    
    var isMeshProxyDataOutCharacteristic: Bool {
        return uuid == MeshProxyService.dataOutUuid
    }
    
}
