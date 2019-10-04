//
//  GenericLevelServerDelegate.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 02/10/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import nRFMeshProvision

class GenericLevelServerDelegate: ModelDelegate {
    let messageTypes: [UInt32 : MeshMessage.Type]
    
    private(set) var level: Int16 = Int16.min
    
    init() {
        let types: [GenericMessage.Type] = [
            GenericLevelGet.self,
            GenericLevelSet.self,
            GenericLevelSetUnacknowledged.self
        ]
        messageTypes = types.toMap()
    }
    
    // MARK: - Message handlers
    
    func model(_ model: Model, didReceiveAcknowledgedMessage request: AcknowledgedMeshMessage,
               from source: Address, sentTo destination: MeshAddress) -> MeshMessage {
        switch request {
        case let request as GenericLevelSet:
            level = request.level
            fallthrough
        default:
            return GenericLevelStatus(level: level)
        }
    }
    
    func model(_ model: Model, didReceiveUnacknowledgedMessage message: MeshMessage,
               from source: Address, sentTo destination: MeshAddress) {
        switch message {
        case let request as GenericLevelSetUnacknowledged:
        level = request.level
        default:
            break
        }
    }
    
    func model(_ model: Model, didReceiveResponse response: MeshMessage,
               toAcknowledgedMessage request: AcknowledgedMeshMessage,
               from source: Address) {
        // Not possible.
    }
    
}
