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
@testable import NordicMesh

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
        XCTAssertEqual(meshNetwork.groups[0].parentAddress, "0000")
        XCTAssertEqual(meshNetwork.groups[0].groupAddress, "C000")
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
