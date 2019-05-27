//
//  NetworkPdus.swift
//  nRFMeshProvision_Tests
//
//  Created by Aleksander Nowakowski on 27/05/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import nRFMeshProvision

class NetworkPdus: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testControlMessage() {
        let networkKey = try! NetworkKey(name: "Test Key", index: 0, key: Data(hex: "7dd7364cd842ad18c17c2b820c84c3d6")!)
        let ivIndex = IvIndex()
        ivIndex.index = 0x12345678
        ivIndex.updateActive = false
        
        let data = Data(hex: "68eca487516765b5e5bfdacbaf6cb7fb6bff871f035444ce83a670df")!
        
        let networkPdu = NetworkPdu(data, using: networkKey, and: ivIndex)
        XCTAssertNotNil(networkPdu)
        XCTAssertEqual(networkPdu!.destination, 0xFFFD)
    }

}
