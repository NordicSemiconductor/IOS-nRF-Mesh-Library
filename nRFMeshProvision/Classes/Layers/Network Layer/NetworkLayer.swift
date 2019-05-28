//
//  NetworkLayer.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 27/05/2019.
//

import Foundation

internal class NetworkLayer {
    var meshNetworkManager: MeshNetworkManager
    let networkMessageCache: NSCache<NSData, NSNull>
    
    init(_ meshNetworkManager: MeshNetworkManager) {
        self.networkMessageCache = NSCache()
        self.meshNetworkManager = meshNetworkManager
    }
    
    func handleIncomingPdu(_ pdu: Data, ofType type: PduType) {
        guard let meshNetwork = meshNetworkManager.meshNetwork else {
            return
        }
        
        if case .provisioningPdu = type {} else {
            // Provisioning is handled using ProvisioningManager.
            return
        }
        
        // Ensure the PDU has not been handled already.
        guard networkMessageCache.object(forKey: pdu as NSData) == nil else {
            // PDU has already been handled.
            return
        }
        networkMessageCache.setObject(NSNull(), forKey: pdu as NSData)
        
        // Try decoding the PDU.
        guard let networkPdu = NetworkPdu.decode(pdu, for: meshNetwork) else {
            return
        }
    }
    
}
