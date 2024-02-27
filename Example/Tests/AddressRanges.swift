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
    
    func testAdd() {
        let ranges = [
            AddressRange(1...1000),
            AddressRange(2000...3000)
        ]
        
        let result = ranges + AddressRange(4000...5000)
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].lowerBound, 1)
        XCTAssertEqual(result[0].upperBound, 1000)
        XCTAssertEqual(result[1].lowerBound, 2000)
        XCTAssertEqual(result[1].upperBound, 3000)
        XCTAssertEqual(result[2].lowerBound, 4000)
        XCTAssertEqual(result[2].upperBound, 5000)
        
        let result2 = ranges + AddressRange(1001...1999)
        XCTAssertEqual(result2.count, 1)
        XCTAssertEqual(result2[0].lowerBound, 1)
        XCTAssertEqual(result2[0].upperBound, 3000)
    }
    
    func testAddArray() {
        let ranges = [
            AddressRange(1...1000),
            AddressRange(2000...3000)
        ]
        let otherRanges = [
            AddressRange(500...800),
            AddressRange(1999...2003),
            AddressRange(2500...3000)
        ]
        let result = ranges + otherRanges
        
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].lowerBound, 1)
        XCTAssertEqual(result[0].upperBound, 1000)
        XCTAssertEqual(result[1].lowerBound, 1999)
        XCTAssertEqual(result[1].upperBound, 3000)
    }
    
    func testMinus() {
        let ranges = [
            RangeObject(1...1000),
            RangeObject(2000...3000)
        ]
        
        let result2 = ranges - RangeObject(4000...5000)
        XCTAssertEqual(result2.count, 2)
        XCTAssertEqual(result2[0].lowerBound, 1)
        XCTAssertEqual(result2[0].upperBound, 1000)
        XCTAssertEqual(result2[1].lowerBound, 2000)
        XCTAssertEqual(result2[1].upperBound, 3000)
        
        let result3 = ranges - RangeObject(500...2500)
        XCTAssertEqual(result3.count, 2)
        XCTAssertEqual(result3[0].lowerBound, 1)
        XCTAssertEqual(result3[0].upperBound, 499)
        XCTAssertEqual(result3[1].lowerBound, 2501)
        XCTAssertEqual(result3[1].upperBound, 3000)
    }
    
    func testMinusArray() {
        let ranges = [
            RangeObject(1...1000),
            RangeObject(2000...3000)
        ]
        let otherRanges = [
            RangeObject(500...800),
            RangeObject(1999...2003),
            RangeObject(2500...3000)
        ]
        let result = ranges - otherRanges
        
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].lowerBound, 1)
        XCTAssertEqual(result[0].upperBound, 499)
        XCTAssertEqual(result[1].lowerBound, 801)
        XCTAssertEqual(result[1].upperBound, 1000)
        XCTAssertEqual(result[2].lowerBound, 2004)
        XCTAssertEqual(result[2].upperBound, 2499)
    }
}
