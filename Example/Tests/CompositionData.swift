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
@testable import nRFMeshProvision

class CompositionData: XCTestCase {

    func testParsing() {
        let data = Data(hex: "0034127856CDAB05000A000601020100000100785634120801000221436587AABBCCDD")
        let compositionData = ConfigCompositionDataStatus(parameters: data)
        
        XCTAssertNotNil(compositionData)
        XCTAssertNotNil(compositionData?.page)
        XCTAssertEqual(compositionData?.page?.page, 0)
        let page0 = compositionData?.page as? Page0
        XCTAssertNotNil(page0)
        XCTAssertEqual(page0?.companyIdentifier, 0x1234)
        XCTAssertEqual(page0?.productIdentifier, 0x5678)
        XCTAssertEqual(page0?.versionIdentifier, 0xABCD)
        XCTAssertEqual(page0?.minimumNumberOfReplayProtectionList, 0x0005)
        XCTAssertEqual(page0?.features.relay, .notSupported)
        XCTAssertEqual(page0?.features.proxy, nil)
        XCTAssertEqual(page0?.features.friend, .notSupported)
        XCTAssertEqual(page0?.features.lowPower, .enabled)
        XCTAssertEqual(page0?.elements.count, 2)
        
        let element0 = page0?.elements[0]
        XCTAssertEqual(element0?.location, .main)
        XCTAssertEqual(element0?.index, 0)
        XCTAssertEqual(element0?.models.count, 3)
        XCTAssertEqual(element0?.models[0].modelId, 0x0000)
        XCTAssert(element0?.models[0].isBluetoothSIGAssigned ?? false)
        XCTAssertEqual(element0?.models[1].modelId, 0x0001)
        XCTAssert(element0?.models[1].isBluetoothSIGAssigned ?? false)
        XCTAssertEqual(element0?.models[2].modelId, 0x56781234)
        XCTAssertFalse(element0?.models[2].isBluetoothSIGAssigned ?? true)
        
        let element1 = page0?.elements[1]
        XCTAssertEqual(element1?.location, .auxiliary)
        XCTAssertEqual(element1?.index, 1)
        XCTAssertEqual(element1?.models.count, 2)
        XCTAssertEqual(element1?.models[0].modelId, 0x43218765)
        XCTAssertFalse(element1?.models[0].isBluetoothSIGAssigned ?? true)
        XCTAssertEqual(element1?.models[1].modelId, 0xBBAADDCC)
        XCTAssertFalse(element1?.models[1].isBluetoothSIGAssigned ?? true)
        
        XCTAssertEqual(compositionData?.parameters, data)
    }

}
