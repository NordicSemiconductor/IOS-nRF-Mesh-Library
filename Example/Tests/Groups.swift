//
//  Groups.swift
//  nRFMeshProvision_Tests
//
//  Created by Aleksander Nowakowski on 16/07/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import nRFMeshProvision

class Groups: XCTestCase {

    func testAdding() throws {
        let meshNetwork = MeshNetwork(name: "Test")
        
        let group = try Group(name: "Group 1", address: 0xC000)
        XCTAssertNoThrow(try meshNetwork.add(group: group))
        
        XCTAssertEqual(meshNetwork.groups.count, 1)
        XCTAssertEqual(meshNetwork.groups[0], group)
        XCTAssertEqual(meshNetwork.groups[0].name, "Group 1")
        XCTAssertNotNil(meshNetwork.groups[0].meshNetwork)
        XCTAssertNil(meshNetwork.groups[0].parent)
        XCTAssertEqual(meshNetwork.groups[0]._parentAddress, "0000")
        XCTAssertEqual(meshNetwork.groups[0]._address, "C000")
        XCTAssert(meshNetwork.groups[0].meshNetwork === meshNetwork)
    }
    
    func testAddingAgain() throws {
        let meshNetwork = MeshNetwork(name: "Test")
        
        XCTAssertNoThrow(try meshNetwork.add(group: try Group(name: "Group 1", address: 0xC000)))
        XCTAssertThrowsError(try meshNetwork.add(group: try Group(name: "Other group with the same address", address: 0xC000)))
        XCTAssertEqual(meshNetwork.groups.count, 1)
        XCTAssertEqual(meshNetwork.groups[0].name, "Group 1")
    }
    
    func testInvalidGroup() {
        XCTAssertThrowsError(try Group(name: "Invalid address", address: 0x0001))
        XCTAssertThrowsError(try Group(name: "Invalid address", address: 0xFF00))
        XCTAssertThrowsError(try Group(name: "Invalid address", address: 0xFFF0))
        XCTAssertThrowsError(try Group(name: "Invalid address", address: 0xFFFB))
        
        // Also, a Group may not be created for special groups.
        XCTAssertThrowsError(try Group(name: "All Proxies", address: 0xFFFC))
        XCTAssertThrowsError(try Group(name: "All Friends", address: 0xFFFD))
        XCTAssertThrowsError(try Group(name: "All Relays", address: 0xFFFE))
        XCTAssertThrowsError(try Group(name: "All Nodes", address: 0xFFFF))
    }
    
    func testRemoving() throws {
        let meshNetwork = MeshNetwork(name: "Test")
        
        let group = try Group(name: "Group 2", address: MeshAddress(0xC000))
        XCTAssertNoThrow(try meshNetwork.add(group: group))
        
        XCTAssertEqual(meshNetwork.groups.count, 1)
        
        XCTAssertNoThrow(try meshNetwork.remove(group: group))
        XCTAssert(meshNetwork.groups.isEmpty)
    }
    
    func testRelationships() throws {
        let meshNetwork = MeshNetwork(name: "Kaczka")
        
        let root = try Group(name: "Root", address: 0xC000)
        let child1 = try Group(name: "Child 1", address: 0xC001)
        let child2 = try Group(name: "Child 2", address: 0xC002)
        let childOfAChild = try Group(name: "Inner child", address: 0xC100)
        
        XCTAssertNoThrow(try meshNetwork.add(group: root))
        XCTAssertNoThrow(try meshNetwork.add(group: child1))
        XCTAssertNoThrow(try meshNetwork.add(group: child2))
        XCTAssertNoThrow(try meshNetwork.add(group: childOfAChild))
        XCTAssert(meshNetwork.groups.count == 4)
        
        child1.parent = root
        child2.parent = root
        childOfAChild.parent = child2
        
        XCTAssertEqual(child1.parent, root)
        XCTAssertEqual(child2.parent, root)
        XCTAssertEqual(childOfAChild.parent, child2)
        
        XCTAssertTrue(root.isDirectParentOf(child1))
        XCTAssertTrue(root.isDirectParentOf(child2))
        XCTAssertFalse(root.isDirectParentOf(childOfAChild))
        XCTAssertTrue(child1.isDirectChildOf(root))
        XCTAssertTrue(child2.isDirectChildOf(root))
        XCTAssertTrue(childOfAChild.isDirectChildOf(child2))
        XCTAssertTrue(root.isParentOf(childOfAChild))
        XCTAssertTrue(childOfAChild.isChildOf(root))
        XCTAssertTrue(childOfAChild.isChildOf(child2))
        XCTAssertFalse(childOfAChild.isChildOf(child1))
        
        XCTAssertTrue(root.isUsed)
        XCTAssertFalse(child1.isUsed)
        XCTAssertTrue(child2.isUsed)
        XCTAssertFalse(childOfAChild.isUsed)
    }

}
