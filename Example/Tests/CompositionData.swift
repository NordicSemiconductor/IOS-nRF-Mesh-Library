//
//  CompositionData.swift
//  nRFMeshProvision_Tests
//
//  Created by Aleksander Nowakowski on 17/06/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import nRFMeshProvision

class CompositionData: XCTestCase {

    func testParsing() {
        let data = Data(hex: "0034127856CDAB05000A00060102010000010078563412")!
        let compositionData = ConfigCompositionDataStatus(parameters: data)
        
        XCTAssertNotNil(compositionData)
        XCTAssertEqual(compositionData?.opCode, 0x02)
        XCTAssertNotNil(compositionData?.page)
        XCTAssertEqual(compositionData?.page?.page, 0)
        let page0 = compositionData?.page as? Page0
        XCTAssertNotNil(page0)
        XCTAssertEqual(page0?.companyIdentifier, 0x1234)
        XCTAssertEqual(page0?.productIdentifier, 0x5678)
        XCTAssertEqual(page0?.versionIdentifier, 0xABCD)
        XCTAssertEqual(page0?.minimumNumberOfReplayProtectionList, 0x0005)
        XCTAssertEqual(page0?.features.relay, .notSupported)
        XCTAssertEqual(page0?.features.proxy, .notEnabled)
        XCTAssertEqual(page0?.features.friend, .notSupported)
        XCTAssertEqual(page0?.features.lowPower, .notEnabled)
        XCTAssertEqual(page0?.elements.count, 1)
        let element = page0?.elements[0]
        XCTAssertEqual(element?.location, .main)
        XCTAssertEqual(element?.index, 0)
        XCTAssertEqual(element?.models.count, 3)
        XCTAssertEqual(element?.models[0].modelId, 0x0000)
        XCTAssert(element?.models[0].isBluetoothSIGAssigned ?? false)
        XCTAssertEqual(element?.models[1].modelId, 0x0001)
        XCTAssert(element?.models[1].isBluetoothSIGAssigned ?? false)
        XCTAssertEqual(element?.models[2].modelId, 0x12345678)
        XCTAssertFalse(element?.models[2].isBluetoothSIGAssigned ?? true)
        XCTAssertEqual(compositionData?.parameters, data)
    }

}
