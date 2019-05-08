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
    public static let uuid = CBUUID(string: "1827")
    
    public struct DataInCharacteristic {
        public static let uuid  = CBUUID(string: "2ADB")
        private init() {}
    }
    public struct DataOutCharacteristic {
        public static let uuid  = CBUUID(string: "2ADC")
        private init() {}
    }
    
    private init() {}
}

public struct MeshProxyService {
    public static let uuid = CBUUID(string: "1828")
    
    public struct DataInCharacteristic {
        public static let uuid  = CBUUID(string: "2ADD")
        private init() {}
    }
    public struct DataOutCharacteristic {
        public static let uuid  = CBUUID(string: "2ADE")
        private init() {}
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
        return uuid == MeshProvisioningService.DataInCharacteristic.uuid
    }
    
    var isMeshProvisioningDataOutCharacteristic: Bool {
        return uuid == MeshProvisioningService.DataOutCharacteristic.uuid
    }
    
    var isMeshProxyDataInCharacteristic: Bool {
        return uuid == MeshProxyService.DataInCharacteristic.uuid
    }
    
    var isMeshProxyDataOutCharacteristic: Bool {
        return uuid == MeshProxyService.DataInCharacteristic.uuid
    }
    
}
