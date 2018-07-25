//
//  StateRestoration.swift
//  nRFMeshProvision_Tests
//
//  Created by Mostafa Berg on 06/03/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
import nRFMeshProvision

class StateRestoration: XCTestCase {
    let testTimestamp1 = Date()
    let testTimestamp2 = Date().addingTimeInterval(10)
    let testTimestamp3 = Date().addingTimeInterval(30)
    var nodes = [MeshNodeEntry]()

    func testSerialization() {
        //Test data        
        nodes.append(MeshNodeEntry(withName: "Node 1", provisionDate: testTimestamp1,
                                   nodeId: Data([0xDE, 0xAD]), andDeviceKey: Data([0xBE, 0xEF])))
        nodes.append(MeshNodeEntry(withName: "Node 2",
                                   provisionDate: testTimestamp2, nodeId: Data([0xDE, 0xAF]),
                                   andDeviceKey: Data([0xBE, 0xEA])))
        nodes.append(MeshNodeEntry(withName: "Node 3",
                                   provisionDate: testTimestamp3, nodeId: Data([0xFE, 0xAF]),
                                   andDeviceKey: Data([0xDE, 0xEA])))
        let appKeys = [["testKey1": Data([0x00, 0x01, 0x02])],
                       ["testKey2": Data([0x03, 0x04, 0x05])]]
        let state = MeshState(withNodeList: nodes,
                              netKey: Data([0xFF, 0xAA, 0xFF]), keyIndex: Data([0x0F]),
                              IVIndex: Data([0x12, 0x34, 0x56]), globalTTL: 0x0A, unicastAddress: Data([0x00, 0x01]),
                              flags: Data([0x0A]), appKeys: appKeys, andName: "My Mesh")

        //Preservation
        let manager = MeshStateManager(withState: state)
        manager.saveState()

        //Restoration
        XCTAssert(MeshStateManager.stateExists() == true, "Mesh state has not been stored!")
        let anotherManager = MeshStateManager.restoreState()!
        //Assert all properties are equal
        XCTAssert(anotherManager.state().name == state.name, "State name did not match test data")
        XCTAssert(anotherManager.state().globalTTL == state.globalTTL, "State TTL did not match test data")
        XCTAssert(anotherManager.state().IVIndex == state.IVIndex, "State IVIndex did not match test data")
        XCTAssert(anotherManager.state().keyIndex == state.keyIndex, "State Key Index did not match test data")
        XCTAssert(anotherManager.state().netKey == state.netKey, "State NetKey did not match test data")
        XCTAssert(anotherManager.state().unicastAddress == state.unicastAddress,
                  "State Unicast address did not match test data")
        XCTAssert(anotherManager.state().flags == state.flags, "State flags did not match test data")
        XCTAssert(anotherManager.state().provisionedNodes.count == state.provisionedNodes.count,
                  "State node count did not match test data")
        //Assert appkeys are correct
        XCTAssert(anotherManager.state().appKeys[0] == state.appKeys[0], "State AppKey 0 did not match")
        XCTAssert(anotherManager.state().appKeys[1] == state.appKeys[1], "State AppKey 1 did not match")
        //Assert provisioned node data is correct
        let anotherStateNodes = anotherManager.state().provisionedNodes
        let stateNodes = state.provisionedNodes
        for i in 0..<nodes.count {
            XCTAssert(anotherStateNodes[i].nodeName == stateNodes[i].nodeName, "\(i)'s name did not match")
            XCTAssert(anotherStateNodes[i].nodeId == stateNodes[i].nodeId, "\(i)'s id did not match")
            XCTAssert(anotherStateNodes[i].deviceKey == stateNodes[i].deviceKey, "\(i)'s devkey did not match")
            XCTAssert(anotherStateNodes[i].provisionedTimeStamp == stateNodes[i].provisionedTimeStamp,
                      "\(i)'s provision timestamp did not match")
        }
   }
}
