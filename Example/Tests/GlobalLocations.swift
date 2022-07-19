/*
* Copyright (c) 2022, Nordic Semiconductor
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

class GlobalLocations: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testIncomingLatitude() {
        let noConfig = Latitude(raw: -1)
        XCTAssertNil(noConfig.position())

        let minValue = Latitude(raw: Int32.min)
        XCTAssertEqual(minValue.position() ?? 0.0, -90.0, accuracy: 0.01)

        let maxValue = Latitude(raw: Int32.max)
        XCTAssertEqual(maxValue.position() ?? 0.0, 90, accuracy: 0.01)

        let positiveSweden = Latitude(raw: 1523043124)
        XCTAssertEqual(positiveSweden.position() ?? 0.0, 63.83, accuracy: 0.01)

        let negativeSydney = Latitude(raw: -807453851)
        XCTAssertEqual(negativeSydney.position() ?? 0.0, -33.84, accuracy: 0.01)
    }
    
    func testOutgoingLatitude() {
        let noConfig = Latitude.notConfigured
        XCTAssertEqual(noConfig.encode(), -1)

        let minValue = Latitude(position: -90.0)
        XCTAssertEqual(minValue?.encode() ?? 0, Int32.min + 1)

        let maxValue = Latitude(position: 90.0)
        XCTAssertEqual(maxValue?.encode() ?? 0, Int32.max - 1)

        let positiveSweden = Latitude(position: 63.83)
        XCTAssertEqual(positiveSweden?.encode() ?? 0, 1523043124)

        // Not identical to the incoming test above due to float precision.
        let negativeSydney = Latitude(position: -33.84)
        XCTAssertEqual(negativeSydney?.encode() ?? 0, -807453852)
    }

    func testIncomingLongitude() {
        let noConfig = Longitude(raw: -1)
        XCTAssertNil(noConfig.position())

        let minValue = Longitude(raw: Int32.min)
        XCTAssertEqual(minValue.position() ?? 0.0, -180.0, accuracy: 0.01)

        let maxValue = Longitude(raw: Int32.max)
        XCTAssertEqual(maxValue.position() ?? 0.0, 180, accuracy: 0.01)

        let positiveSweden = Longitude(raw: 241591910)
        XCTAssertEqual(positiveSweden.position() ?? 0.0, 20.25, accuracy: 0.01)

        let negativeLosAngeles = Longitude(raw: -1411373974)
        XCTAssertEqual(negativeLosAngeles.position() ?? 0.0, -118.30, accuracy: 0.01)
    }
    
    func testOutgoingLongitude() {
        let noConfig = Longitude.notConfigured
        XCTAssertEqual(noConfig.encode(), -1)

        let minValue = Longitude(position: -180.0)
        XCTAssertEqual(minValue?.encode() ?? 0, Int32.min + 1)

        let maxValue = Longitude(position: 180.0)
        XCTAssertEqual(maxValue?.encode() ?? 0, Int32.max - 1)

        let positiveSweden = Longitude(position: 20.25)
        XCTAssertEqual(positiveSweden?.encode() ?? 0, 241591910)

        // Not identical to the incoming test above due to float precision.
        let negativeLosAngeles = Longitude(position: -118.30)
        XCTAssertEqual(negativeLosAngeles?.encode() ?? 0, -1411373975)
    }

    func testIncomingAltitude() {
        let noConfig = Altitude(raw: 0x7FFF)
        XCTAssertEqual(noConfig, Altitude.notConfigured)

        let tooLarge = Altitude(raw: 0x7FFE)
        XCTAssertEqual(tooLarge, Altitude.tooLarge)

        let minValue = Altitude(raw: -32768)
        XCTAssertEqual(minValue.altitude(), -32768)

        let maxValue = Altitude(raw: 0x7FFD)
        XCTAssertEqual(maxValue.altitude(), 0x7FFD)
    }
    
    func testOutgoingAltitude() {
        let noConfig = Altitude.notConfigured
        XCTAssertEqual(noConfig.encode(), 0x7FFF)

        let tooLarge = Altitude.tooLarge
        XCTAssertEqual(tooLarge.encode(), 0x7FFE)

        let minValue = Altitude.altitude(-32768)
        XCTAssertEqual(minValue.encode(), -32768)

        let maxValue = Altitude.altitude(0x7FFD)
        XCTAssertEqual(maxValue.encode(), 0x7FFD)
    }
}
