//
//  GattBearer.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 02/05/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import CoreBluetooth

open class GattBearer: BaseGattProxyBearer<MeshProxyService>, MeshBearer {
    
    public var supportedMesasgeTypes: MessageTypes {
        return [.networkPdu, .meshBeacon, .proxyConfiguration]
    }
    
}
