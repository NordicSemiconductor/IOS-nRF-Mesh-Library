//
//  GenericOnOffClientHandler.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 01/10/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import nRFMeshProvision

class GenericOnOffClientHandler: ModelHandler {
    let messageTypes: [UInt32 : MeshMessage.Type]
    
    init() {
        let types: [GenericMessage.Type] = [
            GenericOnOffStatus.self
        ]
        messageTypes = types.toMap()
    }
    
    // MARK: - Message handlers
    
    func handle(acknowledgedMessage request: AcknowledgedMeshMessage,
                sentFrom source: Address, to model: Model) -> MeshMessage {
        fatalError("Not possible")
    }
    
    func handle(unacknowledgedMessage message: MeshMessage,
                sentFrom source: Address, to model: Model) {
        // Not possible.
    }
    
    func handle(response: MeshMessage, toAcknowledgedMessage request: AcknowledgedMeshMessage,
                sentFrom source: Address, to model: Model) {
        // Ignore.
    }
    
}
