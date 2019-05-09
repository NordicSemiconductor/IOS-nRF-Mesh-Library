//
//  ManagingProvisioners.swift
//  nRFMeshProvision_Tests
//
//  Created by Aleksander Nowakowski on 01/04/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import nRFMeshProvision

class ManagingProvisioners: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testAddAndRemoveProvisioner() {
        let meshNetwork = MeshNetwork(name: "Test network")
        meshNetwork.nodes.append(Node(name: "Node 0", unicastAddress: 1, elements: 10))
        meshNetwork.nodes.append(Node(name: "Node 1", unicastAddress: 12, elements: 18))
        meshNetwork.nodes.append(Node(name: "Node 2", unicastAddress: 30, elements: 11))
        meshNetwork.nodes.append(Node(name: "Node 3", unicastAddress: 55, elements: 10))
        meshNetwork.nodes.append(Node(name: "Node 4", unicastAddress: 65, elements: 5))
        meshNetwork.nodes.append(Node(name: "Node 5", unicastAddress: 73, elements: 5))
        
        let provisioner = Provisioner(name: "New provisioner",
                                      allocatedUnicastRange: [
                                        AddressRange(8...38),
                                        AddressRange(50...80)
                                      ],
                                      allocatedGroupRange: [
                                        AddressRange.allGroupAddresses
                                      ],
                                      allocatedSceneRange: [
                                        SceneRange.allScenes
                                      ])
        XCTAssertNoThrow(try meshNetwork.add(provisioner: provisioner))
        XCTAssertEqual(meshNetwork.provisioners.count, 1)
        XCTAssertEqual(meshNetwork.nodes.count, 7)
        XCTAssertEqual(meshNetwork.nodes[6].unicastAddress, 11)
        XCTAssertEqual(meshNetwork.nodes[6].lastUnicastAddress, 11)
        
        meshNetwork.remove(provisioner: provisioner)
        XCTAssertEqual(meshNetwork.provisioners.count, 0)
        XCTAssertEqual(meshNetwork.nodes.count, 6)
    }
    
    func testAddProvisioner_missingRanges() {
        let meshNetwork = MeshNetwork(name: "Test network")
        meshNetwork.nodes.append(Node(name: "Node 0", unicastAddress: 1, elements: 10))
        meshNetwork.nodes.append(Node(name: "Node 1", unicastAddress: 12, elements: 18))
        meshNetwork.nodes.append(Node(name: "Node 2", unicastAddress: 30, elements: 11))
        meshNetwork.nodes.append(Node(name: "Node 3", unicastAddress: 55, elements: 10))
        meshNetwork.nodes.append(Node(name: "Node 4", unicastAddress: 65, elements: 5))
        meshNetwork.nodes.append(Node(name: "Node 5", unicastAddress: 73, elements: 5))
        
        let provisioner = Provisioner(name: "New provisioner",
                                      allocatedUnicastRange: [
                                        AddressRange(8...38),
                                        AddressRange(50...80)
                                      ],
                                      allocatedGroupRange: [],
                                      allocatedSceneRange: [])
        XCTAssertNoThrow(try provisioner.allocateSceneRange(SceneRange.allScenes))
        // Group ranges not allocated, but that's OK. They are not required.
        XCTAssertNoThrow(try meshNetwork.add(provisioner: provisioner))
    }
    
    func testAddProvisioner_noAddress() {
        let meshNetwork = MeshNetwork(name: "Test network")
        meshNetwork.nodes.append(Node(name: "Node 0", unicastAddress: 1, elements: 11))
        meshNetwork.nodes.append(Node(name: "Node 1", unicastAddress: 12, elements: 18))
        meshNetwork.nodes.append(Node(name: "Node 2", unicastAddress: 30, elements: 11))
        meshNetwork.nodes.append(Node(name: "Node 3", unicastAddress: 55, elements: 10))
        meshNetwork.nodes.append(Node(name: "Node 4", unicastAddress: 65, elements: 5))
        meshNetwork.nodes.append(Node(name: "Node 5", unicastAddress: 73, elements: 5))
        
        let provisioner = Provisioner(name: "New provisioner",
                                      allocatedUnicastRange: [
                                        AddressRange(8...38)
                                      ],
                                      allocatedGroupRange: [
                                        AddressRange.allGroupAddresses
                                      ],
                                      allocatedSceneRange: [
                                        SceneRange.allScenes
                                      ])
        // Group ranges not allocated.
        XCTAssertThrowsError(try meshNetwork.add(provisioner: provisioner))
    }

}
