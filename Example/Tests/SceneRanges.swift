//
//  SceneRanges.swift
//  nRFMeshProvision_Tests
//
//  Created by Aleksander Nowakowski on 25/03/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import nRFMeshProvision

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

}
