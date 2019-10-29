//
//  AssigningGroupAddresses.swift
//  nRFMeshProvision_Tests
//
//  Created by Aleksander Nowakowski on 29/07/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import nRFMeshProvision

class AssigningGroupAddresses: XCTestCase {
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testAssigningGroupAddress_empty() {
        let meshNetwork = MeshNetwork(name: "Test network")
        
        let provisioner = Provisioner(name: "Test provisioner",
                                      allocatedUnicastRange: [ AddressRange(1...0x7FFF) ],
                                      allocatedGroupRange: [ AddressRange(0xC000...0xC008) ],
                                      allocatedSceneRange: [])
        
        let address = meshNetwork.nextAvailableGroupAddress(for: provisioner)
        
        XCTAssertNotNil(address)
        XCTAssertEqual(address!, 0xC000)
    }
    
    func testAssigningGroupAddress_basic() {
        let meshNetwork = MeshNetwork(name: "Test network")
        
        let provisioner = Provisioner(name: "Test provisioner",
                                      allocatedUnicastRange: [ AddressRange(1...0x7FFF) ],
                                      allocatedGroupRange: [ AddressRange(0xD015...0xD0FF) ],
                                      allocatedSceneRange: [])
        
        let address = meshNetwork.nextAvailableGroupAddress(for: provisioner)
        
        XCTAssertNotNil(address)
        XCTAssertEqual(address!, 0xD015)
    }
    
    func testAssigningGroupAddress_some() {
        let meshNetwork = MeshNetwork(name: "Test network")
        
        let provisioner = Provisioner(name: "Test provisioner",
                                      allocatedUnicastRange: [ AddressRange(1...0x7FFF) ],
                                      allocatedGroupRange: [ AddressRange(0xC000...0xC001), AddressRange(0xC00F...0xC00F) ],
                                      allocatedSceneRange: [])
        XCTAssertNoThrow(try meshNetwork.add(group: Group(name: "Group 1", address: 0xC000)))
        XCTAssertNoThrow(try meshNetwork.add(group: Group(name: "Group 2", address: 0xC001)))
        
        let address = meshNetwork.nextAvailableGroupAddress(for: provisioner)
        
        XCTAssertNotNil(address)
        XCTAssertEqual(address!, 0xC00F)
    }
    
    func testAssigningGroupAddress_no_more() {
        let meshNetwork = MeshNetwork(name: "Test network")
        
        let provisioner = Provisioner(name: "Test provisioner",
                                      allocatedUnicastRange: [ AddressRange(1...0x7FFF) ],
                                      allocatedGroupRange: [ AddressRange(0xC000...0xC001), AddressRange(0xC00F...0xC00F) ],
                                      allocatedSceneRange: [])
        XCTAssertNoThrow(try meshNetwork.add(group: Group(name: "Group 1", address: 0xC000)))
        XCTAssertNoThrow(try meshNetwork.add(group: Group(name: "Group 2", address: 0xC001)))
        XCTAssertNoThrow(try meshNetwork.add(group: Group(name: "Group 3", address: 0xC00F)))
        
        let address = meshNetwork.nextAvailableGroupAddress(for: provisioner)
        
        XCTAssertNil(address)
    }

}
