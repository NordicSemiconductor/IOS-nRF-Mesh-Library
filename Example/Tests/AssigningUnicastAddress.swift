//
//  AssigningUnicastAddress.swift
//  nRFMeshProvision_Tests
//
//  Created by Aleksander Nowakowski on 28/03/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import nRFMeshProvision

class AssigningUnicastAddress: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testAssigningUnicastAddress_empty() {
        let meshNetwork = MeshNetwork(name: "Test network")
        
        let provisioner = Provisioner(name: "Test provisioner",
                                      allocatedUnicastRange: [
                                        AddressRange(1...0x7FFF)
                                      ],
                                      allocatedGroupRange: [], allocatedSceneRange: [])
        
        let address = meshNetwork.allocateNextAvailableUnicastAddress(for: 6, elementsUsing: provisioner)
        
        XCTAssertNotNil(address)
        XCTAssertEqual(address!, 1)
    }
    
    func testAssigningUnicastAddress_basic() {
        let meshNetwork = MeshNetwork(name: "Test network")
        meshNetwork.nodes.append(Node(name: "Node 0", unicastAddress: 1, elements: 9))
        meshNetwork.nodes.append(Node(name: "Node 1", unicastAddress: 10, elements: 9))
        meshNetwork.nodes.append(Node(name: "Node 2", unicastAddress: 20, elements: 9))
        meshNetwork.nodes.append(Node(name: "Node 3", unicastAddress: 30, elements: 9))
        
        let provisioner = Provisioner(name: "Test provisioner",
                                      allocatedUnicastRange: [
                                        AddressRange(100...200)
                                      ],
                                      allocatedGroupRange: [], allocatedSceneRange: [])
        
        let address = meshNetwork.allocateNextAvailableUnicastAddress(for: 6, elementsUsing: provisioner)
        
        XCTAssertNotNil(address)
        XCTAssertEqual(address!, 100)
    }
    
    func testAssigningUnicastAddress_complex() {
        let meshNetwork = MeshNetwork(name: "Test network")
        meshNetwork.nodes.append(Node(name: "Node 0", unicastAddress: 1, elements: 9))
        meshNetwork.nodes.append(Node(name: "Node 1", unicastAddress: 10, elements: 9))
        meshNetwork.nodes.append(Node(name: "Node 2", unicastAddress: 20, elements: 9))
        meshNetwork.nodes.append(Node(name: "Node 3", unicastAddress: 30, elements: 9))
        meshNetwork.nodes.append(Node(name: "Node 4", unicastAddress: 103, elements: 5))
        
        let provisioner = Provisioner(name: "Test provisioner",
                                      allocatedUnicastRange: [
                                        AddressRange(100...200)
                                      ],
                                      allocatedGroupRange: [], allocatedSceneRange: [])
        
        let address = meshNetwork.allocateNextAvailableUnicastAddress(for: 6, elementsUsing: provisioner)
        
        XCTAssertNotNil(address)
        XCTAssertEqual(address!, 108)
    }

    func testAssigningUnicastAddress_advanced() {
        let meshNetwork = MeshNetwork(name: "Test network")
        meshNetwork.nodes.append(Node(name: "Node 0", unicastAddress: 1, elements: 10))
        meshNetwork.nodes.append(Node(name: "Node 1", unicastAddress: 12, elements: 18))
        meshNetwork.nodes.append(Node(name: "Node 2", unicastAddress: 30, elements: 11))
        meshNetwork.nodes.append(Node(name: "Node 3", unicastAddress: 55, elements: 10))
        meshNetwork.nodes.append(Node(name: "Node 4", unicastAddress: 65, elements: 5))
        meshNetwork.nodes.append(Node(name: "Node 5", unicastAddress: 73, elements: 5))
        
        let provisioner = Provisioner(name: "Test provisioner",
                                      allocatedUnicastRange: [
                                        AddressRange(8...38),
                                        AddressRange(50...100),
                                        AddressRange(120...150)
                                      ],
                                      allocatedGroupRange: [], allocatedSceneRange: [])
        
        let address = meshNetwork.allocateNextAvailableUnicastAddress(for: 6, elementsUsing: provisioner)
        
        XCTAssertNotNil(address)
        XCTAssertEqual(address!, 78)
    }
    
    func testAssigningUnicastAddress_none() {
        let meshNetwork = MeshNetwork(name: "Test network")
        meshNetwork.nodes.append(Node(name: "Node 0", unicastAddress: 1, elements: 10))
        meshNetwork.nodes.append(Node(name: "Node 1", unicastAddress: 12, elements: 18))
        meshNetwork.nodes.append(Node(name: "Node 2", unicastAddress: 30, elements: 11))
        meshNetwork.nodes.append(Node(name: "Node 3", unicastAddress: 55, elements: 10))
        meshNetwork.nodes.append(Node(name: "Node 4", unicastAddress: 65, elements: 5))
        meshNetwork.nodes.append(Node(name: "Node 5", unicastAddress: 73, elements: 5))
        
        let provisioner = Provisioner(name: "Test provisioner",
                                      allocatedUnicastRange: [
                                        AddressRange(8...38),
                                        AddressRange(50...80)
                                      ],
                                      allocatedGroupRange: [], allocatedSceneRange: [])
        
        let address = meshNetwork.allocateNextAvailableUnicastAddress(for: 6, elementsUsing: provisioner)
        
        XCTAssertNil(address)
    }
}
