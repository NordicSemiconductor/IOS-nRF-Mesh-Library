//
//  Addresses.swift
//  nRFMeshProvision_Tests
//
//  Created by Aleksander Nowakowski on 24/05/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import nRFMeshProvision

class Addresses: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testVirtualAddress() {
        let virtualLabel = UUID(uuidString: "0073e7e4-d8b9-440f-af84-15df4c56c0e1")!
        let address = MeshAddress(virtualLabel)
        
        XCTAssertEqual(address.address, 0xB529)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
