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

class SceneRanges: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testNoMerging() {
        var scenes = [
            SceneRange(1...10),
            SceneRange(20...30),
            SceneRange(40...50)
        ]
        scenes.merge()
        
        // The array should contain 3 elements.
        XCTAssertEqual(scenes.count, 3)
        
        // They should be ordered by range.
        XCTAssertEqual(scenes[0].firstScene, 1)
        XCTAssertEqual(scenes[1].firstScene, 20)
        XCTAssertEqual(scenes[2].firstScene, 40)
    }
    
    func testMergingLowerBound() {
        var scenes = [
            SceneRange(5...10),
            SceneRange(5...20)
        ]
        scenes.merge()
        
        // The array should contain 1 element.
        XCTAssertEqual(scenes.count, 1)
        
        // The ranges should be merged.
        XCTAssertEqual(scenes[0].firstScene, 5)
        XCTAssertEqual(scenes[0].lastScene, 20)
    }
    
    func testMergingUpperBound() {
        var scenes = [
            SceneRange(5...10),
            SceneRange(1...10)
        ]
        scenes.merge()
        
        // The array should contain 1 element.
        XCTAssertEqual(scenes.count, 1)
        
        // The ranges should be merged.
        XCTAssertEqual(scenes[0].firstScene, 1)
        XCTAssertEqual(scenes[0].lastScene, 10)
    }
    
    func testMerging() {
        var scenes = [
            SceneRange(1...10),
            SceneRange(20...30),
            SceneRange(9...25)
        ]
        scenes.merge()
        
        // The array should contain 1 element.
        XCTAssertEqual(scenes.count, 1)
        
        // The ranges should be merged.
        XCTAssertEqual(scenes[0].firstScene, 1)
        XCTAssertEqual(scenes[0].lastScene, 30)
    }
    
    func testMergingTouchingRanges() {
        var scenes = [
            SceneRange(1...10),
            SceneRange(11...30)
        ]
        scenes.merge()
        
        // The array should contain 1 element.
        XCTAssertEqual(scenes.count, 1)
        
        // The ranges should be merged.
        XCTAssertEqual(scenes[0].firstScene, 1)
        XCTAssertEqual(scenes[0].lastScene, 30)
    }
    
    func testWithSorting() {
        var scenes = [
            SceneRange(20...30),
            SceneRange(15...20),
            SceneRange(1...10)
        ]
        scenes.merge()
        
        // The array should now contain 2 elements.
        XCTAssertEqual(scenes.count, 2)
        
        // The ranges should be sorted.
        XCTAssertEqual(scenes[0].firstScene, 1)
        XCTAssertEqual(scenes[0].lastScene,  10)
        XCTAssertEqual(scenes[1].firstScene, 15)
        XCTAssertEqual(scenes[1].lastScene,  30)
    }
    
    func testAddingArrays() {
        let array1 = [SceneRange(1...10), SceneRange(20...30)]
        let array2 = [SceneRange(8...15), SceneRange(19...25)]
        
        let sum = (array1 + array2).merged()
        
        XCTAssertEqual(sum.count, 2)
    }
    
    func testOverlapping() {
        let array1 = [SceneRange(1...10), SceneRange(20...30)]
        let array2 = [SceneRange(8...15), SceneRange(19...25)]
        
        let overlap = array1.overlaps(array2)
        
        XCTAssert(overlap)
    }
    
    func testOverlapping2() {
        let array1 = [SceneRange(1...10)]
        let array2 = [SceneRange(10...10)]
        
        let overlap = array1.overlaps(array2)
        
        XCTAssert(overlap)
    }
    
    func testOverlapping3() {
        let array1 = [SceneRange(1...10)]
        let array2 = [SceneRange(11...20)]
        
        let overlap = array1.overlaps(array2)
        
        XCTAssertFalse(overlap)
    }
    
    func testOverlapping4() {
        let array1 = [SceneRange(5...10)]
        let array2 = [SceneRange(1...20)]
        
        let overlap = array1.overlaps(array2)
        
        XCTAssert(overlap)
    }

}
