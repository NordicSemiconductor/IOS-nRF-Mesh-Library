//
//  AccessLayer.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 29/05/2019.
//

import Foundation

internal class AccessLayer {
    let networkManager: NetworkManager
    
    init(_ networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    func handle(upperTransportPdu: UpperTransportPdu) {
        
    }
    
    func send(_ message: MeshMessage, to destination: Address, using applicationKey: ApplicationKey) {
        networkManager.upperTransportLayer.send(message, to: destination, using: applicationKey)
    }
    
    func send(_ message: ConfigMessage, to destination: Address) {
        networkManager.upperTransportLayer.send(message, to: destination)
    }
    
}
