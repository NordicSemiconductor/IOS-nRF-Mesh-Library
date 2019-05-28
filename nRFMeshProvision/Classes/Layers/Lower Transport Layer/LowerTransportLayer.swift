//
//  LowerTransportLayer.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 28/05/2019.
//

import Foundation

internal class LowerTransportLayer {
    let networkLayer: NetworkLayer
    let upperTransportLayer: UpperTransportLayer
    
    init(_ networkManager: NetworkManager) {
        self.networkLayer = networkManager.networkLayer!
        self.upperTransportLayer = networkManager.upperTransportLayer!
    }
    
    func handleNetworkPdu(_ networkPdu: NetworkPdu) {
        
    }
    
}
