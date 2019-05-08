//
//  MeshConstants.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 02/05/2019.
//

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
    public static var dataInUuid  = CBUUID(string: "2ADB")
    public static var dataOutUuid = CBUUID(string: "2ADC")
    
    public static func matches(_ service: CBService) -> Bool {
        return service.isMeshProvisioningService
    }
    
    private init() {}
}

public struct MeshProxyService: MeshService {
    public static let uuid        = CBUUID(string: "1828")
    public static var dataInUuid  = CBUUID(string: "2ADD")
    public static var dataOutUuid = CBUUID(string: "2ADE")
    
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
