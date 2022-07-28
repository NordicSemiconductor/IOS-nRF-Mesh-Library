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

class TimeMessages: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testIncomingTaiTime() {
        let time = TaiTime.unmarshal(Data([120, 86, 52, 18, 0, 50, 120, 255, 225, 74]))
        
        XCTAssertEqual(time.seconds, 305419896)
        XCTAssertEqual(time.subSecond, 50)
        XCTAssertEqual(time.uncertainty, 120)
        XCTAssertEqual(time.authority, true)
        XCTAssertEqual(time.taiDelta, 28672)
        XCTAssertEqual(time.tzOffset.secondsFromGMT(), 9000)
    }

    func testOutgoingTaiTime() {
        let time = TaiTime.marshal(TaiTime(seconds: 305419896, subSecond: 50, uncertainty: 120, authority: true, taiDelta: 28672, tzOffset: TimeZone(secondsFromGMT: 9000)!))
        
        XCTAssertEqual(time, Data([120, 86, 52, 18, 0, 50, 120, 255, 225, 74]))
    }

    func testIncomingTimeZoneStatus() {
        let msg = TimeZoneStatus(parameters: Data([68, 60, 213, 106, 129, 45, 0]))
        
        XCTAssertEqual(msg?.currentTzOffset.secondsFromGMT(), 3600)
        XCTAssertEqual(msg?.nextTzOffset.secondsFromGMT(), -3600)
        XCTAssertEqual(msg?.taiSeconds, 763456213)
    }

    func testOutgoingTimeZoneStatus() {
        let msg = TimeZoneStatus(currentTzOffset: TimeZone(secondsFromGMT: 5400)!, nextTzOffset: TimeZone(secondsFromGMT: -4500)!, taiSeconds: 763456213)
        
        XCTAssertEqual(msg.parameters, Data([70, 59, 213, 106, 129, 45, 0]))
    }

    func testIncomingTimeZoneSet() {
        let msg = TimeZoneSet(parameters: Data([90, 213, 106, 129, 45, 0]))
        
        XCTAssertEqual(msg?.tzOffset.secondsFromGMT(), 23400)
        XCTAssertEqual(msg?.taiSeconds, 763456213)
    }

    func testOutgoingTimeZoneSet() {
        let msg = TimeZoneSet(tzOffset: TimeZone(secondsFromGMT: -23400)!, taiSeconds: 763456213)
        
        XCTAssertEqual(msg.parameters, Data([38, 213, 106, 129, 45, 0]))
    }
}
