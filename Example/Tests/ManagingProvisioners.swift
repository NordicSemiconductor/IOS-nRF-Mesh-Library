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

class ManagingProvisioners: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testAddAndRemoveProvisioner() {
        let meshNetwork = MeshNetwork(name: "Test network")
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 0", unicastAddress: 1, elements: 10)))
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 1", unicastAddress: 12, elements: 18)))
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 2", unicastAddress: 30, elements: 11)))
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 3", unicastAddress: 55, elements: 10)))
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 4", unicastAddress: 65, elements: 5)))
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 5", unicastAddress: 73, elements: 5)))
        
        let provisioner = Provisioner(name: "Main provisioner",
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
        XCTAssertEqual(meshNetwork.nodes[6].primaryUnicastAddress, 11)
        XCTAssertEqual(meshNetwork.nodes[6].lastUnicastAddress, 11)
        
        // This will throw, as it's not possible to remove the last Provisioner object.
        XCTAssertThrowsError(try meshNetwork.remove(provisioner: provisioner))
        XCTAssertEqual(meshNetwork.provisioners.count, 1)
        XCTAssertEqual(meshNetwork.nodes.count, 7)

        let otherProvisioner = Provisioner(name: "New provisioner",
                                           allocatedUnicastRange: [
                                            AddressRange(100...200)
                                           ],
                                           allocatedGroupRange: [],
                                           allocatedSceneRange: [])
        XCTAssertNoThrow(try meshNetwork.add(provisioner: otherProvisioner))
        XCTAssertEqual(meshNetwork.provisioners.count, 2)
        XCTAssertEqual(meshNetwork.nodes.count, 8)
        XCTAssertEqual(meshNetwork.nodes[7].primaryUnicastAddress, 100)
        XCTAssertEqual(meshNetwork.nodes[7].lastUnicastAddress, 100)
        
        XCTAssertNoThrow(try meshNetwork.remove(provisioner: otherProvisioner))
        XCTAssertEqual(meshNetwork.provisioners.count, 1)
        XCTAssertEqual(meshNetwork.nodes.count, 7)
    }
    
    func testAddProvisioner_missingRanges() {
        let meshNetwork = MeshNetwork(name: "Test network")
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 0", unicastAddress: 1, elements: 10)))
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 1", unicastAddress: 12, elements: 18)))
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 2", unicastAddress: 30, elements: 11)))
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 3", unicastAddress: 55, elements: 10)))
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 4", unicastAddress: 65, elements: 5)))
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 5", unicastAddress: 73, elements: 5)))
        
        let provisioner = Provisioner(name: "New provisioner",
                                      allocatedUnicastRange: [
                                        AddressRange(8...38),
                                        AddressRange(50...80)
                                      ],
                                      allocatedGroupRange: [],
                                      allocatedSceneRange: [])
        XCTAssertNoThrow(try provisioner.allocate(sceneRange: SceneRange.allScenes))
        // Group ranges not allocated, but that's OK. They are not required.
        XCTAssertNoThrow(try meshNetwork.add(provisioner: provisioner))
    }
    
    func testAddProvisioner_noAddress() {
        let meshNetwork = MeshNetwork(name: "Test network")
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 0", unicastAddress: 1, elements: 11)))
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 1", unicastAddress: 12, elements: 18)))
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 2", unicastAddress: 30, elements: 11)))
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 3", unicastAddress: 55, elements: 10)))
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 4", unicastAddress: 65, elements: 5)))
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 5", unicastAddress: 73, elements: 5)))
        
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
