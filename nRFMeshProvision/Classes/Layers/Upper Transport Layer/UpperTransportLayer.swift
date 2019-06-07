//
//  UpperTransportLayer.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 28/05/2019.
//

import Foundation

internal class UpperTransportLayer {
    let networkManager: NetworkManager
    let meshNetwork: MeshNetwork
    
    init(_ networkManager: NetworkManager) {
        self.networkManager = networkManager
        self.meshNetwork = networkManager.meshNetwork!
    }
    
    func handle(lowerTransportPdu: LowerTransportPdu) {
        switch lowerTransportPdu.type {
        case .accessMessage:
            let accessMessage = lowerTransportPdu as! AccessMessage
            if let upperTransportPdu = UpperTransportPdu.decode(accessMessage, for: meshNetwork) {
                networkManager.accessLayer.handle(upperTransportPdu: upperTransportPdu)
            }
        case .controlMessage:
            let controlMessage = lowerTransportPdu as! ControlMessage
            switch controlMessage.opCode {
            case 0x0A:
                if let heartbeat = HearbeatMessage(fromControlMessage: controlMessage) {
                    handle(hearbeat: heartbeat)
                }
            default:
                // Other Control Messages are not supported.
                break
            }
        }
    }
    
    private func handle(hearbeat: HearbeatMessage) {
        // TODO: Implement handling Heartbeat messages
    }
}
