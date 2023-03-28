/*
* Copyright (c) 2019, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

import XCTest
@testable import nRFMeshProvision

class Models: XCTestCase {
    var node: Node!
    
    override func setUp() {
        node = Node(name: "Test Node", unicastAddress: 0x0001, elements: 0)
        node.add(elements: [
            Element(models: [
                // Base models
                Model(sigModelId: .configurationServerModelId),
                Model(sigModelId: .healthServerModelId),
                Model(sigModelId: .genericLevelServerModelId),
                Model(sigModelId: .genericOnOffServerModelId),
                Model(sigModelId: .genericDefaultTransitionTimeServerModelId),
                // Extends Generic OnOff Server model:
                Model(sigModelId: .genericPowerOnOffServerModelId),
                // Extends Generic Power OnOff Server model:
                Model(sigModelId: .genericPowerOnOffSetupServerModelId),
                // Extends Generic Power OnOff Server and Generic Level Server models:
                Model(sigModelId: .lightLightnessServerModelId),
                // Extends Light Lightness Server model:
                Model(sigModelId: .lightLightnessSetupServerModelId),
            ]),
            Element(models: [
                // Base model:
                Model(sigModelId: .genericOnOffServerModelId),
                // Extends Generic OnOff Server on this Element
                // and Light Lightness Server on Element 0:
                Model(sigModelId: .lightLCServerModelId),
                // Extends Light LC Server model:
                Model(sigModelId: .lightLCSetupServerModelId),
            ]),
            Element(models: [
                // Base models
                Model(sigModelId: .genericLevelServerModelId),
                Model(sigModelId: .genericOnOffServerModelId),
                Model(sigModelId: .genericDefaultTransitionTimeServerModelId),
                // Extends Generic OnOff Server model:
                Model(sigModelId: .genericPowerOnOffServerModelId),
                // Extends Generic Power OnOff Server model:
                Model(sigModelId: .genericPowerOnOffSetupServerModelId),
                // Extends Generic Power OnOff Server and Generic Level Server models:
                Model(sigModelId: .lightLightnessServerModelId),
                // Extends Light Lightness Server model:
                Model(sigModelId: .lightLightnessSetupServerModelId),
            ]),
            Element(models: [
                // Base model:
                Model(sigModelId: .genericOnOffServerModelId),
                // Extends Generic OnOff Server on this Element
                // and Light Lightness Server on Element 0:
                Model(sigModelId: .lightLCServerModelId),
                // Extends Light LC Server model:
                Model(sigModelId: .lightLCSetupServerModelId),
            ])
        ])
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testConfigServerModel() throws {
        let configServerModel = node.elements[0].model(withSigModelId: .configurationServerModelId)
        XCTAssertNotNil(configServerModel)
        
        let otherModels = node.elements
            .flatMap { $0.models }
            .filter { $0.modelIdentifier != .configurationServerModelId }
        
        XCTAssertFalse(otherModels.contains { $0.extendsDirectly(configServerModel!) })
        XCTAssertFalse(otherModels.contains { configServerModel!.extendsDirectly($0) })
        XCTAssertFalse(otherModels.contains { $0.extends(configServerModel!) })
        XCTAssertFalse(otherModels.contains { configServerModel!.extends($0) })
    }
    
    func testGenericPowerOnOffServerModelId() throws {
        let powerOnOffSetupServer = node.elements[0].model(withSigModelId: .genericPowerOnOffSetupServerModelId)
        XCTAssertNotNil(powerOnOffSetupServer)
        
        let otherModels = node.elements
            .flatMap { $0.models }
            .filter { $0.modelIdentifier != .genericPowerOnOffSetupServerModelId }
        
        // Generic Power OnOff Setup Server model extends:
        // - Generic Power OnOff Server model
        // - Default Transition Time Server model
        let directBaseModels = otherModels
            .filter { powerOnOffSetupServer!.extendsDirectly($0) }
        XCTAssertEqual(directBaseModels.count, 2)
        // Additionally, Power OnOff Server model extends:
        // - Generic OnOff Server
        let baseModels = otherModels
            .filter { powerOnOffSetupServer!.extends($0) }
        XCTAssertEqual(baseModels.count, 3)
    }
    
    func testLightLCServer() throws {
        let lightLCServer = node.elements[3].model(withSigModelId: .lightLCServerModelId)
        XCTAssertNotNil(lightLCServer)
        
        let extendedModels = lightLCServer!.baseModels
        XCTAssertEqual(extendedModels.count, 5)
        
        let extendingModels = lightLCServer!.extendingModels
        XCTAssertEqual(extendingModels.count, 1)
    }
    
    func testLightLightnessServer() throws {
        let lightLightnessServer = node.elements[0]
            .model(withSigModelId: .lightLightnessServerModelId)
        XCTAssertNotNil(lightLightnessServer)
        
        let extendedModels = lightLightnessServer!.baseModels
        XCTAssertEqual(extendedModels.count, 3)
        
        let extendingModels = lightLightnessServer!.extendingModels
        XCTAssertEqual(extendingModels.count, 3)
    }
    
}

