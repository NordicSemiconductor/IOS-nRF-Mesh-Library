//
//  UpperTransportLayer.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 28/05/2019.
//

import Foundation

internal class UpperTransportLayer {
    let lowerTransportLayer: LowerTransportLayer
    
    init(_ networkManager: NetworkManager) {
        self.lowerTransportLayer = networkManager.lowerTransportLayer!
    }
    
    func handleLowerTransportPdu(_ LowerTransportPdu: LowerTransportPdu) {
        
    }
    
}
