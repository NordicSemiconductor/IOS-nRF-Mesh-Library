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
    
    func testDistance() {
        XCTAssertEqual(AddressRange(10...20).distance(to: AddressRange(21...40)), 0)
        XCTAssertEqual(AddressRange(10...20).distance(to: AddressRange(22...40)), 1)
        XCTAssertEqual(AddressRange(10...20).distance(to: AddressRange(30...40)), 9)
        XCTAssertEqual(AddressRange(10...20).distance(to: AddressRange(15...40)), 0)
        XCTAssertEqual(AddressRange(10...20).distance(to: AddressRange(0...40)), 0)
        XCTAssertEqual(AddressRange(10...20).distance(to: AddressRange(0...9)), 0)
        XCTAssertEqual(AddressRange(10...20).distance(to: AddressRange(0...8)), 1)
        XCTAssertEqual(AddressRange(10...20).distance(to: AddressRange(10...10)), 0)
        XCTAssertEqual(AddressRange(10...20).distance(to: AddressRange(0...2)), 7)
    }
    
    func testOperatorAdd() {
        let ranges = AddressRange(10...20) + AddressRange(30...40)
        XCTAssertEqual(ranges.count, 2)
    }
    
    func testOperatorAddAdjacent() {
        let ranges = AddressRange(10...20) + AddressRange(21...40)
        XCTAssertEqual(ranges.count, 1)
    }
    
    func testOperatorAddOverlapping() {
        let ranges = AddressRange(10...20) + AddressRange(15...40)
        XCTAssertEqual(ranges.count, 1)
    }
    
    func testOperatorRemove() {
        var ranges = [
            AddressRange(10...20),
            AddressRange(30...40)
        ]
        ranges -= AddressRange(15...35)
        
        XCTAssertEqual(ranges.count, 2)
        
        XCTAssertEqual(ranges[0].lowAddress, 10)
        XCTAssertEqual(ranges[0].highAddress, 14)
        XCTAssertEqual(ranges[1].lowAddress, 36)
        XCTAssertEqual(ranges[1].highAddress, 40)
    }
    
    func testOperatorRemove2() {
        var ranges = [
            AddressRange(10...20),
            AddressRange(30...40)
        ]
        ranges -= AddressRange(40...40)
        
        XCTAssertEqual(ranges.count, 2)
        
        XCTAssertEqual(ranges[0].lowAddress, 10)
        XCTAssertEqual(ranges[0].highAddress, 20)
        XCTAssertEqual(ranges[1].lowAddress, 30)
        XCTAssertEqual(ranges[1].highAddress, 39)
    }
    
    func testOperatorRemove3() {
        var ranges = [
            AddressRange(1...32767)
        ]
        ranges -= AddressRange(12289...28671)
        ranges -= AddressRange(1...12288)
        
        XCTAssertEqual(ranges.count, 1)
        
        XCTAssertEqual(ranges[0].lowAddress, 28672)
        XCTAssertEqual(ranges[0].highAddress, 32767)
    }
}
