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
                                      allocatedUnicastRange: [ AddressRange(1...0x7FFF) ],
                                      allocatedGroupRange: [], allocatedSceneRange: [])
        
        let address = meshNetwork.nextAvailableUnicastAddress(for: 6, elementsUsing: provisioner)
        
        XCTAssertNotNil(address)
        XCTAssertEqual(address!, 1)
    }
    
    func testAssigningUnicastAddress_basic() {
        let meshNetwork = MeshNetwork(name: "Test network")
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 0", unicastAddress: 1, elements: 9)))
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 1", unicastAddress: 10, elements: 9)))
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 2", unicastAddress: 20, elements: 9)))
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 3", unicastAddress: 30, elements: 9)))
        
        let provisioner = Provisioner(name: "Test provisioner",
                                      allocatedUnicastRange: [
                                        AddressRange(100...200)
                                      ],
                                      allocatedGroupRange: [], allocatedSceneRange: [])
        
        let address = meshNetwork.nextAvailableUnicastAddress(for: 6, elementsUsing: provisioner)
        
        XCTAssertNotNil(address)
        XCTAssertEqual(address!, 100)
    }
    
    func testAssigningUnicastAddress_complex() {
        let meshNetwork = MeshNetwork(name: "Test network")
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 0", unicastAddress: 1, elements: 9)))
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 1", unicastAddress: 10, elements: 9)))
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 2", unicastAddress: 20, elements: 9)))
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 3", unicastAddress: 30, elements: 9)))
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 4", unicastAddress: 103, elements: 5)))
        
        let provisioner = Provisioner(name: "Test provisioner",
                                      allocatedUnicastRange: [
                                        AddressRange(100...200)
                                      ],
                                      allocatedGroupRange: [], allocatedSceneRange: [])
        
        let address = meshNetwork.nextAvailableUnicastAddress(for: 6, elementsUsing: provisioner)
        
        XCTAssertNotNil(address)
        XCTAssertEqual(address!, 108)
    }

    func testAssigningUnicastAddress_advanced() {
        let meshNetwork = MeshNetwork(name: "Test network")
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 0", unicastAddress: 1, elements: 10)))
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 1", unicastAddress: 12, elements: 18)))
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 2", unicastAddress: 30, elements: 11)))
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 3", unicastAddress: 55, elements: 10)))
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 4", unicastAddress: 65, elements: 5)))
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 5", unicastAddress: 73, elements: 5)))
        
        let provisioner = Provisioner(name: "Test provisioner",
                                      allocatedUnicastRange: [
                                        AddressRange(8...38),
                                        AddressRange(50...100),
                                        AddressRange(120...150)
                                      ],
                                      allocatedGroupRange: [], allocatedSceneRange: [])
        
        let address = meshNetwork.nextAvailableUnicastAddress(for: 6, elementsUsing: provisioner)
        
        XCTAssertNotNil(address)
        XCTAssertEqual(address!, 78)
    }
    
    func testAssigningUnicastAddress_none() {
        let meshNetwork = MeshNetwork(name: "Test network")
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 0", unicastAddress: 1, elements: 10)))
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 1", unicastAddress: 12, elements: 18)))
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 2", unicastAddress: 30, elements: 11)))
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 3", unicastAddress: 55, elements: 10)))
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 4", unicastAddress: 65, elements: 5)))
        XCTAssertNoThrow(try meshNetwork.add(node: Node(name: "Node 5", unicastAddress: 73, elements: 5)))
        
        let provisioner = Provisioner(name: "Test provisioner",
                                      allocatedUnicastRange: [
                                        AddressRange(8...38),
                                        AddressRange(50...80)
                                      ],
                                      allocatedGroupRange: [], allocatedSceneRange: [])
        
        let address = meshNetwork.nextAvailableUnicastAddress(for: 6, elementsUsing: provisioner)
        
        XCTAssertNil(address)
    }
    
    func testAssigningUnicastAdderessRanges() {
        let meshNetwork = MeshNetwork(name: "Test network")
        XCTAssertNoThrow(try meshNetwork.add(provisioner:
            Provisioner(name: "P0",
                        allocatedUnicastRange: [AddressRange(0x0001...0x00FF),
                                                AddressRange(0x0120...0x0FFF),
                                                AddressRange(0x2000...0x2FFF),
                                                AddressRange(0x6000...0x7FFF)],
                        allocatedGroupRange: [],
                        allocatedSceneRange: [])))
        
        let newRange0 = meshNetwork.nextAvailableUnicastAddressRange(ofSize: 1)
        XCTAssertNotNil(newRange0)
        XCTAssertEqual(newRange0?.lowerBound, 0x0100)
        XCTAssertEqual(newRange0?.upperBound, 0x0100)
        
        let newRange1 = meshNetwork.nextAvailableUnicastAddressRange(ofSize: 0x51)
        XCTAssertNotNil(newRange1)
        XCTAssertEqual(newRange1?.lowerBound, 0x1000)
        XCTAssertEqual(newRange1?.upperBound, 0x1050)
        
        let newRange2 = meshNetwork.nextAvailableUnicastAddressRange(ofSize: 0x1000)
        XCTAssertNotNil(newRange2)
        XCTAssertEqual(newRange2?.lowerBound, 0x1000)
        XCTAssertEqual(newRange2?.upperBound, 0x1FFF)
        
        let newRange3 = meshNetwork.nextAvailableUnicastAddressRange(ofSize: 0x2000)
        XCTAssertNotNil(newRange3)
        XCTAssertEqual(newRange3?.lowerBound, 0x3000)
        XCTAssertEqual(newRange3?.upperBound, 0x4FFF)
        
        let newRangeMax = meshNetwork.nextAvailableUnicastAddressRange()
        XCTAssertNotNil(newRangeMax)
        XCTAssertEqual(newRangeMax?.lowerBound, 0x3000)
        XCTAssertEqual(newRangeMax?.upperBound, 0x5FFF)
    }
    
    func testAssigningUnicastAdderessRanges_none() {
        let meshNetwork = MeshNetwork(name: "Test network")
        XCTAssertNoThrow(try meshNetwork.add(provisioner:
            Provisioner(name: "P0",
                        allocatedUnicastRange: [AddressRange(0x0001...0x7FFF)],
                        allocatedGroupRange: [],
                        allocatedSceneRange: [])))
        
        let newRange0 = meshNetwork.nextAvailableUnicastAddressRange(ofSize: 1)
        XCTAssertNil(newRange0)
    }
}
