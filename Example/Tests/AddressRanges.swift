//
//  AddressRanges.swift
//  nRFMeshProvision_Tests
//
//  Created by Aleksander Nowakowski on 25/03/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import nRFMeshProvision

class AddressRanges: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testMerging() {
        let ranges = [
            AddressRange(10...20),
            AddressRange(30...40),
            AddressRange(1...5),
            AddressRange(15...50)
        ].merged()
        
        // Ranges should be merge into 2 separate ranges.
        XCTAssertEqual(ranges.count, 2)
        
        // Result should be also ordered.
        XCTAssertEqual(ranges[0].lowAddress, 1)
        XCTAssertEqual(ranges[0].highAddress, 5)
        XCTAssertEqual(ranges[1].lowAddress, 10)
        XCTAssertEqual(ranges[1].highAddress, 50)
    }

}
