//
//  CreatingMeshNetwork.swift
//  nRFMeshProvision_Tests
//
//  Created by Aleksander Nowakowski on 29/07/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

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
        XCTAssertEqual(network.provisioners.first?.provisionerName, "Test Provisioner")
        XCTAssertEqual(network.networkKeys.count, 1)
        XCTAssertEqual(network.nodes.count, 1)
        XCTAssertEqual(network.nodes.first?.name, "Test Provisioner")
        XCTAssertEqual(network.nodes.first?.networkKeys.first?.index, 0)
        XCTAssertEqual(network.nodes.first?.netKeys.count, 1)
        // By default only the Primary Element is added
        XCTAssertEqual(network.nodes.first?.elements.count, 1)
        XCTAssertEqual(network.nodes.first?.elementsCount, 1)
        XCTAssert(network.nodes.first?.elements.contains(model: .configurationServer) ?? false)
        XCTAssert(network.nodes.first?.elements.contains(model: .configurationClient) ?? false)
        XCTAssert(network.nodes.first?.elements.contains(model: .healthServer) ?? false)
    }
    
    func testCreateMeshNetwork_withLocalElements() {
        let manager = MeshNetworkManager(using: TestStorage())
        let network = manager.createNewMeshNetwork(withName: "Test network", by: "Test Provisioner")
        
        let element1 = Element(location: .first)
        element1.add(model: Model(sigModelId: 0x1001)) // Generic On/Off Client
        element1.add(model: Model(sigModelId: 0x1003)) // Generic Level Client
        
        let element2 = Element(location: .second)
        element2.add(model: Model(sigModelId: 0x1005)) // Generic Default Transition Time Client
        element2.add(model: Model(sigModelId: 0x1007)) // Generic Power OnOff Setup Server
        element2.add(model: Model(sigModelId: 0x1009)) // Generic Power Level Server
        
        // Define local Elements. A Primary Element will be added automatically at index 0.
        manager.localElements = [element1, element2]
        
        XCTAssertEqual(network.nodes.count, 1)
        XCTAssertEqual(network.nodes.first?.elements.count, 3)
        XCTAssertEqual(network.nodes.first?.elementsCount, 3)
        // Verify the Primary Element.
        XCTAssertEqual(network.nodes.first?.elements[1].models.count, 2)
        XCTAssert(network.nodes.first?.elements[1].contains(modelWithIdentifier: 0x1001) ?? false)
        XCTAssert(network.nodes.first?.elements[1].contains(modelWithIdentifier: 0x1003) ?? false)
        // Verify element 1 and 2.
        XCTAssertEqual(network.nodes.first?.elements[2].models.count, 3)
        XCTAssertFalse(network.nodes.first?.elements[2].contains(modelWithIdentifier: 0x1001) ?? true)
        XCTAssertFalse(network.nodes.first?.elements[2].contains(modelWithIdentifier: 0x1003) ?? true)
        XCTAssert(network.nodes.first?.elements[2].contains(modelWithIdentifier: 0x1005) ?? false)
        XCTAssert(network.nodes.first?.elements[2].contains(modelWithIdentifier: 0x1007) ?? false)
        XCTAssert(network.nodes.first?.elements[2].contains(modelWithIdentifier: 0x1009) ?? false)
    }
    
    func testNextAvailableUnicastAddress() {
        let manager = MeshNetworkManager(using: TestStorage())
        let network = manager.createNewMeshNetwork(withName: "Test network", by: "Test Provisioner")
        
        let element1 = Element(location: .first)
        element1.add(model: Model(sigModelId: 0x1001)) // Generic On/Off Client
        element1.add(model: Model(sigModelId: 0x1003)) // Generic Level Client
        
        let element2 = Element(location: .second)
        element2.add(model: Model(sigModelId: 0x1005)) // Generic Default Transition Time Client
        element2.add(model: Model(sigModelId: 0x1007)) // Generic Power OnOff Setup Server
        element2.add(model: Model(sigModelId: 0x1009)) // Generic Power Level Server
        
        // Define local Elements. A Primary Element will be added automatically at index 0.
        manager.localElements = [element1, element2]
        
        let provisioner = network.localProvisioner
        XCTAssertNotNil(provisioner)
        XCTAssertEqual(network.nextAvailableUnicastAddress(for: provisioner!), 0x0004)
    }
    
    func testCuttingElements() {
        let manager = MeshNetworkManager(using: TestStorage())
        let network = manager.createNewMeshNetwork(withName: "Test network", by: "Test Provisioner")
        
        let node = Node(lowSecurityNode: "Test Node", with: 3,
                        elementsDeviceKey: OpenSSLHelper().generateRandom(),
                        andAssignedNetworkKey: network.networkKeys.first!, andAddress: 0x0003)
        XCTAssertNotNil(node)
        XCTAssertNoThrow(try network.add(node: node!))
        
        let element1 = Element(location: .first)
        element1.add(model: Model(sigModelId: 0x1001)) // Generic On/Off Client
        element1.add(model: Model(sigModelId: 0x1003)) // Generic Level Client
        
        let element2 = Element(location: .second)
        element2.add(model: Model(sigModelId: 0x1005)) // Generic Default Transition Time Client
        element2.add(model: Model(sigModelId: 0x1007)) // Generic Power OnOff Setup Server
        element2.add(model: Model(sigModelId: 0x1009)) // Generic Power Level Server
        
        let element3 = Element(location: .third)
        
        // Define local Elements. A Primary Element will be added automatically at index 0.
        // The element3 will be removed, as it has 0 Models.
        manager.localElements = [element1, element2, element3]
        
        XCTAssertEqual(manager.localElements.count, 3)
        XCTAssertEqual(manager.localElements[1].location, .first)
        XCTAssertEqual(manager.localElements[2].location, .second)
        
        let cutElements = network.localProvisioner?.node?.elements
        XCTAssertNotNil(cutElements)
        XCTAssertEqual(cutElements!.count, 2) // There were only 2 addreses available.
        XCTAssertGreaterThan(cutElements![0].models.count, 3)
        XCTAssert(cutElements![0].contains(model: .configurationServer))
        XCTAssert(cutElements![0].contains(model: .configurationClient))
        XCTAssert(cutElements![0].contains(model: .healthServer))
        XCTAssertEqual(cutElements![1].models.count, 2)
        XCTAssertEqual(cutElements![1].models[0].modelIdentifier, 0x1001)
        XCTAssertEqual(cutElements![1].models[1].modelIdentifier, 0x1003)
    }

}
