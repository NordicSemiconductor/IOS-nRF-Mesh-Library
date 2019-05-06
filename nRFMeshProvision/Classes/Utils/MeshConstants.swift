//
//  MeshConstants.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 02/05/2019.
//

import Foundation
import CoreBluetooth

// MARK: - Mesh service identifires
public struct MeshProvisioningService {
    public static let serviceUUID = CBUUID(string: "1827")
    public static let dataInUUID  = CBUUID(string: "2ADB")
    public static let dataOutUUID = CBUUID(string: "2ADC")
    
    private init() {}
}

public struct MeshProxyService {
    public static let serviceUUID = CBUUID(string: "1828")
    public static let dataInUUID  = CBUUID(string: "2ADD")
    public static let dataOutUUID = CBUUID(string: "2ADE")
    
    private init() {}
}

public extension CBService {
    
    var isMeshProvisioningService: Bool {
        return uuid == MeshProvisioningService.serviceUUID
    }
    
    var isMeshProxyService: Bool {
        return uuid == MeshProxyService.serviceUUID
    }
    
}

public extension CBCharacteristic {
    
    var isMeshProvisioningDataInCharacteristic: Bool {
        return uuid == MeshProvisioningService.dataInUUID
    }
    
    var isMeshProvisioningDataOutCharacteristic: Bool {
        return uuid == MeshProvisioningService.dataOutUUID
    }
    
    var isMeshProxyDataInCharacteristic: Bool {
        return uuid == MeshProxyService.dataInUUID
    }
    
    var isMeshProxyDataOutCharacteristic: Bool {
        return uuid == MeshProxyService.dataOutUUID
    }
    
}
