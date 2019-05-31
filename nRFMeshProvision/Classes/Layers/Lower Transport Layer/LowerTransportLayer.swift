//
//  LowerTransportLayer.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 28/05/2019.
//

import Foundation

internal class LowerTransportLayer {
    let networkLayer: NetworkLayer
    
    init(_ networkManager: NetworkManager) {
        self.networkLayer = networkManager.networkLayer!
    }
    
    func handle(networkPdu: NetworkPdu) {
        
    }
    
    func handle(unprovisionedDeviceBeacon: UnprovisionedDeviceBeacon) {
        
    }
    
    func handle(secureNetworkBeacon: SecureNetworkBeacon) {
        
    }
    
}
