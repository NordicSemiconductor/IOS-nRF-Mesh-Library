//
//  GenericLevelServerHandler.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 02/10/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import nRFMeshProvision

class GenericLevelServerHandler: ModelHandler {
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
    
    func handle(acknowledgedMessage request: AcknowledgedMeshMessage,
                sentFrom source: Address, to model: Model) -> MeshMessage {
        switch request {
        case let request as GenericLevelSet:
            level = request.level
            fallthrough
        default:
            return GenericLevelStatus(level: level)
        }
    }
    
    func handle(unacknowledgedMessage message: MeshMessage,
                sentFrom source: Address, to model: Model) {
        switch message {
        case let request as GenericLevelSetUnacknowledged:
        level = request.level
        default:
            break
        }
    }
    
    func handle(response: MeshMessage, toAcknowledgedMessage request: AcknowledgedMeshMessage,
                sentFrom source: Address, to model: Model) {
        // Not possible.
    }
    
}
