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

@testable import nRFMeshProvision
import XCTest

private struct TestStorage: Storage {
    
    func load() -> Data? {
        return nil
    }
    
    func save(_ data: Data) -> Bool {
        return true
    }
    
}

class CreatingMeshNetwork: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCreateMeshNetwork() {
        let manager = MeshNetworkManager(using: TestStorage())
        let network = manager.createNewMeshNetwork(withName: "Test network", by: "Test Provisioner")
        XCTAssertNotNil(manager.meshNetwork)
        XCTAssertEqual(network.meshName, "Test network")
        XCTAssertEqual(network.provisioners.count, 1)
        XCTAssertEqual(network.provisioners.first?.name, "Test Provisioner")
        XCTAssertEqual(network.networkKeys.count, 1)
        XCTAssertEqual(network.nodes.count, 1)
        XCTAssertEqual(network.nodes.first?.name, "Test Provisioner")
        XCTAssertEqual(network.nodes.first?.networkKeys.first?.index, 0)
        XCTAssertEqual(network.nodes.first?.netKeys.count, 1)
        // By default only the Primary Element is added
        XCTAssertEqual(network.nodes.first?.elements.count, 1)
        XCTAssertEqual(network.nodes.first?.elementsCount, 1)
        XCTAssert(network.nodes.first?.elements.contains(modelWithSigModelId: .configurationServerModelId) ?? false)
        XCTAssert(network.nodes.first?.elements.contains(modelWithSigModelId: .configurationClientModelId) ?? false)
        XCTAssert(network.nodes.first?.elements.contains(modelWithSigModelId: .healthServerModelId) ?? false)
    }
    
    func testCreateMeshNetwork_withLocalElements() {
        let manager = MeshNetworkManager(using: TestStorage())
        let network = manager.createNewMeshNetwork(withName: "Test network", by: "Test Provisioner")
        
        let element0 = Element(location: .first)
        element0.add(model: Model(sigModelId: 0x1001)) // Generic On/Off Client
        element0.add(model: Model(sigModelId: 0x1003)) // Generic Level Client
        
        let element1 = Element(location: .second)
        element1.add(model: Model(sigModelId: 0x1005)) // Generic Default Transition Time Client
        element1.add(model: Model(sigModelId: 0x1007)) // Generic Power OnOff Setup Server
        element1.add(model: Model(sigModelId: 0x1009)) // Generic Power Level Server
        
        // Define local Elements. A Primary Element will be added automatically at index 0.
        manager.localElements = [element0, element1]
        
        XCTAssertEqual(network.nodes.count, 1)
        XCTAssertEqual(network.nodes.first?.elements.count, 2)
        XCTAssertEqual(network.nodes.first?.elementsCount, 2)
        // Verify the Primary Element.
        XCTAssertEqual(network.nodes.first?.elements[0].models.count, 8)
        XCTAssert(network.nodes.first?.elements[0].contains(modelWithSigModelId: 0x1001) ?? false)
        XCTAssert(network.nodes.first?.elements[0].contains(modelWithSigModelId: 0x1003) ?? false)
        // Verify element 1 and 2.
        XCTAssertEqual(network.nodes.first?.elements[1].models.count, 3)
        XCTAssertFalse(network.nodes.first?.elements[1].contains(modelWithSigModelId: 0x1001) ?? true)
        XCTAssertFalse(network.nodes.first?.elements[1].contains(modelWithSigModelId: 0x1003) ?? true)
        XCTAssert(network.nodes.first?.elements[1].contains(modelWithSigModelId: 0x1005) ?? false)
        XCTAssert(network.nodes.first?.elements[1].contains(modelWithSigModelId: 0x1007) ?? false)
        XCTAssert(network.nodes.first?.elements[1].contains(modelWithSigModelId: 0x1009) ?? false)
    }
    
    func testNextAvailableUnicastAddress() {
        let manager = MeshNetworkManager(using: TestStorage())
        let network = manager.createNewMeshNetwork(withName: "Test network", by: "Test Provisioner")
        
        let element0 = Element(location: .first)
        element0.add(model: Model(sigModelId: 0x1001)) // Generic On/Off Client
        element0.add(model: Model(sigModelId: 0x1003)) // Generic Level Client
        
        let element1 = Element(location: .second)
        element1.add(model: Model(sigModelId: 0x1005)) // Generic Default Transition Time Client
        element1.add(model: Model(sigModelId: 0x1007)) // Generic Power OnOff Setup Server
        element1.add(model: Model(sigModelId: 0x1009)) // Generic Power Level Server
        
        // Define local Elements. Required models will automatically be added to element 0.
        manager.localElements = [element0, element1]
        
        let provisioner = network.localProvisioner
        XCTAssertNotNil(provisioner)
        XCTAssertEqual(network.nextAvailableUnicastAddress(for: provisioner!), 0x0003)
    }
    
    func testCuttingElements() {
        let manager = MeshNetworkManager(using: TestStorage())
        let network = manager.createNewMeshNetwork(withName: "Test network", by: "Test Provisioner")
        
        let node = Node(insecureNode: "Test Node", with: 3,
                        elementsDeviceKey: Data.random128BitKey(),
                        andAssignedNetworkKey: network.networkKeys.first!, andAddress: 0x0003)
        XCTAssertNotNil(node)
        XCTAssertNoThrow(try network.add(node: node!))
        
        let element0 = Element(location: .first)
        element0.add(model: Model(sigModelId: 0x1001)) // Generic On/Off Client
        element0.add(model: Model(sigModelId: 0x1003)) // Generic Level Client
        
        let element1 = Element(location: .second)
        element1.add(model: Model(sigModelId: 0x1005)) // Generic Default Transition Time Client
        element1.add(model: Model(sigModelId: 0x1007)) // Generic Power OnOff Setup Server
        element1.add(model: Model(sigModelId: 0x1009)) // Generic Power Level Server
        
        let element2 = Element(location: .third)
        let element3 = Element(location: .fourth)
        element3.add(model: Model(sigModelId: 0x1009)) // Generic Power Level Server
        
        // Define local Elements.
        // Configuration Server and Client, Health Server and Client,
        // and Scene Client will be added automatically to the first element.
        // The element 2 will be removed, as it has 0 Models.
        manager.localElements = [element0, element1, element2, element3]
        
        // Only the empty element should be removed.
        XCTAssertEqual(manager.localElements.count, 3)
        XCTAssertEqual(manager.localElements[0].location, .first)
        XCTAssertEqual(manager.localElements[1].location, .second)
        XCTAssertEqual(manager.localElements[2].location, .fourth)
        
        let cutElements = network.localProvisioner?.node?.elements
        XCTAssertNotNil(cutElements)
        XCTAssertEqual(cutElements!.count, 2) // There were only 2 addresses available.
        XCTAssertEqual(cutElements![0].models.count, 8)
        XCTAssert(cutElements![0].contains(modelWithSigModelId:  .configurationServerModelId))
        XCTAssert(cutElements![0].contains(modelWithSigModelId: .configurationClientModelId))
        XCTAssert(cutElements![0].contains(modelWithSigModelId: .healthServerModelId))
        XCTAssert(cutElements![0].contains(modelWithSigModelId: .healthClientModelId))
        XCTAssert(cutElements![0].contains(modelWithSigModelId: . privateBeaconClientModelId))
        XCTAssert(cutElements![0].contains(modelWithSigModelId: .sceneClientModelId))
        XCTAssertEqual(cutElements![0].models[6].modelIdentifier, 0x1001)
        XCTAssertEqual(cutElements![0].models[7].modelIdentifier, 0x1003)
        XCTAssertEqual(cutElements![1].models.count, 3)
        XCTAssertEqual(cutElements![1].models[0].modelIdentifier, 0x1005)
        XCTAssertEqual(cutElements![1].models[1].modelIdentifier, 0x1007)
        XCTAssertEqual(cutElements![1].models[2].modelIdentifier, 0x1009)
    }

}
