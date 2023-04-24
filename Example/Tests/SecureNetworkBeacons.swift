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

class SecureNetworkBeacons: XCTestCase {
    private let networkKey =
        try! NetworkKey(name: "Primary Network Key", index: 0,
                        key: Data(hex: "8D65C0771C83FAC39E256F697EA3AAE1"))

    func testDecodingSecureNordicBeacon() throws {
        let data = Data(hex: "0102EE6C0EFF5298ECFF000000025E5AA7B268B5E044")
        let snb = SecureNetworkBeacon(decode: data, usingNetworkKey: networkKey)
        
        XCTAssertNotNil(snb)
        XCTAssertEqual(snb?.beaconType, BeaconType.secureNetwork)
        XCTAssertEqual(snb?.networkKey, networkKey)
        XCTAssertEqual(snb?.networkKey.networkId, Data(hex: "EE6C0EFF5298ECFF"))
        XCTAssertEqual(snb?.ivIndex.index, 2)
        XCTAssertEqual(snb?.ivIndex.updateActive, true)
        XCTAssertEqual(snb?.ivIndex.transmitIndex, 1)
        XCTAssertEqual(snb?.ivIndex.index(for: 0x01), 1)
        XCTAssertEqual(snb?.ivIndex.index(for: 0x00), 2)
        XCTAssertEqual(snb?.keyRefreshFlag, false)
    }
    
    func testOverwritingWithTheSameIvIndex() {
        let data = Data(hex: "0102EE6C0EFF5298ECFF000000025E5AA7B268B5E044")
        let snb = SecureNetworkBeacon(decode: data, usingNetworkKey: networkKey)
        let ivIndex = IvIndex(index: 2, updateActive: true)
        
        let oneHourAgo = Date(hoursAgo: 1)
        let result = snb?.canOverwrite(ivIndex: ivIndex, updatedAt: oneHourAgo,
                                       withIvRecovery: false, testMode: false,
                                       andUnlimitedIvRecoveryAllowed: false)
        
        XCTAssert(result == true)
    }
    
    func testOverwritingWithNextIvIndex() {
        let data = Data(hex: "0102EE6C0EFF5298ECFF000000025E5AA7B268B5E044")
        let snb = SecureNetworkBeacon(decode: data, usingNetworkKey: networkKey)
        let ivIndex = IvIndex(index: 1, updateActive: false)
        
        let ninetySixHoursAgo = Date(hoursAgo: 96)
        let almostNinetySixHoursAgo = Date(timeInterval: +10.0, since: ninetySixHoursAgo)
        let moreThanNinetySixHoursAgo = Date(timeInterval: -10.0, since: ninetySixHoursAgo)
        
        // Less than 96 hours - test should fail
        let result0 = snb?.canOverwrite(ivIndex: ivIndex, updatedAt: almostNinetySixHoursAgo,
                                        withIvRecovery: false, testMode: false,
                                        andUnlimitedIvRecoveryAllowed: false)
                                        
        // When previous IV Index was updated using IV Recovery, 96h requirement
        // does not apply. Test should pass.
        let result1 = snb?.canOverwrite(ivIndex: ivIndex, updatedAt: almostNinetySixHoursAgo,
                                        withIvRecovery: true, testMode: false,
                                        andUnlimitedIvRecoveryAllowed: false)
        
        // It's ok. 96 hours have passed.
        let result2 = snb?.canOverwrite(ivIndex: ivIndex, updatedAt: ninetySixHoursAgo,
                                        withIvRecovery: false, testMode: false,
                                        andUnlimitedIvRecoveryAllowed: false)
        
        // Now even more time passed, so updating IV Index is ok.
        let result3 = snb?.canOverwrite(ivIndex: ivIndex, updatedAt: moreThanNinetySixHoursAgo,
                                        withIvRecovery: false, testMode: false,
                                        andUnlimitedIvRecoveryAllowed: false)
        
        XCTAssert(result0 == false)
        XCTAssert(result1 == true)
        XCTAssert(result2 == true)
        XCTAssert(result3 == true)
    }
    
    func testOverwritingWithNextIvIndexInTestMode() {
        let data = Data(hex: "0102EE6C0EFF5298ECFF000000025E5AA7B268B5E044")
        let snb = SecureNetworkBeacon(decode: data, usingNetworkKey: networkKey)
        let ivIndex = IvIndex(index: 1, updateActive: false)
        
        let ninetySixHoursAgo = Date(hoursAgo: 96)
        let almostNinetySixHoursAgo = Date(timeInterval: +10.0, since: ninetySixHoursAgo)
        let moreThanNinetySixHoursAgo = Date(timeInterval: -10.0, since: ninetySixHoursAgo)
        
        // In test mode the 96h requirement does not apply.
        let result0 = snb?.canOverwrite(ivIndex: ivIndex, updatedAt: almostNinetySixHoursAgo,
                                        withIvRecovery: false, testMode: true,
                                        andUnlimitedIvRecoveryAllowed: false)
        
        let result1 = snb?.canOverwrite(ivIndex: ivIndex, updatedAt: ninetySixHoursAgo,
                                        withIvRecovery: false, testMode: true,
                                        andUnlimitedIvRecoveryAllowed: false)
        
        let result2 = snb?.canOverwrite(ivIndex: ivIndex, updatedAt: moreThanNinetySixHoursAgo,
                                        withIvRecovery: false, testMode: true,
                                        andUnlimitedIvRecoveryAllowed: false)
        
        XCTAssert(result0 == true)
        XCTAssert(result1 == true)
        XCTAssert(result2 == true)
    }
    
    func testOverwritingWithFarIvIndex() {
        let data = Data(hex: "0102EE6C0EFF5298ECFF000000025E5AA7B268B5E044")
        let snb = SecureNetworkBeacon(decode: data, usingNetworkKey: networkKey)
        let ivIndex = IvIndex(index: 0, updateActive: false)
        
        let ninetySixHoursAgo = Date(hoursAgo: 96)
        let almostNinetySixHoursAgo = Date(timeInterval: +10.0, since: ninetySixHoursAgo)
        let moreThanNinetySixHoursAgo = Date(timeInterval: -10.0, since: ninetySixHoursAgo)
        let twoHundredEightyEightHoursAgo = Date(hoursAgo: 288)
        let almostTwoHundredEightyEightHoursAgo = Date(timeInterval: +10.0, since: twoHundredEightyEightHoursAgo)
        let moreThanTwoHundredEightyEightHoursAgo = Date(timeInterval: -10.0, since: twoHundredEightyEightHoursAgo)
        
        // 3 * 96 = 288 hours are required to pass since last IV Index update
        // for the IV Index to change from 0 (normal operation) to 2 (update active).
        // The following tests check if SNB cannot be updated before that.
        let result0 = snb?.canOverwrite(ivIndex: ivIndex, updatedAt: almostNinetySixHoursAgo,
                                        withIvRecovery: false, testMode: false,
                                        andUnlimitedIvRecoveryAllowed: false)
        
        let result1 = snb?.canOverwrite(ivIndex: ivIndex, updatedAt: ninetySixHoursAgo,
                                        withIvRecovery: false, testMode: false,
                                        andUnlimitedIvRecoveryAllowed: false)
        
        let result2 = snb?.canOverwrite(ivIndex: ivIndex, updatedAt: moreThanNinetySixHoursAgo,
                                        withIvRecovery: false, testMode: false,
                                        andUnlimitedIvRecoveryAllowed: false)
        
        let result3 = snb?.canOverwrite(ivIndex: ivIndex,
                                        updatedAt: almostTwoHundredEightyEightHoursAgo,
                                        withIvRecovery: false, testMode: false,
                                        andUnlimitedIvRecoveryAllowed: false)
        
        // 3 * 96 = 288 hours have passed. IV Index can be updated
        // from 0 (normal operation) to 2 (update active) using IV Recovery
        // procedure.
        let result4 = snb?.canOverwrite(ivIndex: ivIndex,
                                        updatedAt: twoHundredEightyEightHoursAgo,
                                        withIvRecovery: false, testMode: false,
                                        andUnlimitedIvRecoveryAllowed: false)
        
        // Even more time has passed.
        let result5 = snb?.canOverwrite(ivIndex: ivIndex,
                                        updatedAt: moreThanTwoHundredEightyEightHoursAgo,
                                        withIvRecovery: false, testMode: false,
                                        andUnlimitedIvRecoveryAllowed: false)
        
        XCTAssert(result0 == false)
        XCTAssert(result1 == false)
        XCTAssert(result2 == false)
        XCTAssert(result3 == false)
        XCTAssert(result4 == true)
        XCTAssert(result5 == true)
    }
    
    func testOverwritingWithFarIvIndexInTestMode() {
        let data = Data(hex: "0102EE6C0EFF5298ECFF000000025E5AA7B268B5E044")
        let snb = SecureNetworkBeacon(decode: data, usingNetworkKey: networkKey)
        let ivIndex = IvIndex(index: 0, updateActive: false)
        
        let ninetySixHoursAgo = Date(hoursAgo: 96)
        let almostNinetySixHoursAgo = Date(timeInterval: +10.0, since: ninetySixHoursAgo)
        let moreThanNinetySixHoursAgo = Date(timeInterval: -10.0, since: ninetySixHoursAgo)
        
        // Test mode only removes 96h requirements to transition to the next
        // IV Index. Here we are updating from 0 (normal operation) to
        // 2 (update active), which is 3 steps. Test mode cannot help.
        let result0 = snb?.canOverwrite(ivIndex: ivIndex, updatedAt: almostNinetySixHoursAgo,
                                        withIvRecovery: false, testMode: true,
                                        andUnlimitedIvRecoveryAllowed: false)
        
        let result1 = snb?.canOverwrite(ivIndex: ivIndex, updatedAt: ninetySixHoursAgo,
                                        withIvRecovery: false, testMode: true,
                                        andUnlimitedIvRecoveryAllowed: false)
        
        let result2 = snb?.canOverwrite(ivIndex: ivIndex, updatedAt: moreThanNinetySixHoursAgo,
                                        withIvRecovery: false, testMode: true,
                                        andUnlimitedIvRecoveryAllowed: false)
        
        XCTAssert(result0 == false)
        XCTAssert(result1 == false)
        XCTAssert(result2 == false)
    }
    
    func testOverwritingWithVeryFarIvIndex() {
        // This Secure Network Beacon has IV Index 52 (update active).
        let data = Data(hex: "0102EE6C0EFF5298ECFF00000034A53312BF9198C86F")
        let snb = SecureNetworkBeacon(decode: data, usingNetworkKey: networkKey)
        let ivIndex = IvIndex(index: 9, updateActive: false)
        
        // The IV Index changes from 9 to 52, that is by 43. Also, the update active
        // flag changes from false to true, which adds one more step.
        // At least 42 * 192h + additional 96h are required for the IV Index to be
        // assumed valid. Updating IV by more than 42 is not allowed by the spec.
        // This library allows, however, to disable this check with a flag.
        let longTimeAgo = Date(hoursAgo: 42 * 192 + 96)
        let notThatLongTimeAgo = Date(timeInterval: +10.0, since: longTimeAgo)
        let longLongTimeAgo = Date(timeInterval: -10.0, since: longTimeAgo)
        
        // First, with the flag set to false. All should fail.
        let result0 = snb?.canOverwrite(ivIndex: ivIndex,
                                        updatedAt: notThatLongTimeAgo,
                                        withIvRecovery: false, testMode: false,
                                        andUnlimitedIvRecoveryAllowed: false)
        
        let result1 = snb?.canOverwrite(ivIndex: ivIndex,
                                        updatedAt: longTimeAgo,
                                        withIvRecovery: false, testMode: false,
                                        andUnlimitedIvRecoveryAllowed: false)
        
        let result2 = snb?.canOverwrite(ivIndex: ivIndex,
                                        updatedAt: longLongTimeAgo,
                                        withIvRecovery: false, testMode: false,
                                        andUnlimitedIvRecoveryAllowed: false)
        
        // Now, with the flag set to true.
        let result3 = snb?.canOverwrite(ivIndex: ivIndex,
                                        updatedAt: notThatLongTimeAgo,
                                        withIvRecovery: false, testMode: false,
                                        andUnlimitedIvRecoveryAllowed: true)
        
        let result4 = snb?.canOverwrite(ivIndex: ivIndex,
                                        updatedAt: longTimeAgo,
                                        withIvRecovery: false, testMode: false,
                                        andUnlimitedIvRecoveryAllowed: true)
        
        let result5 = snb?.canOverwrite(ivIndex: ivIndex,
                                        updatedAt: longLongTimeAgo,
                                        withIvRecovery: false, testMode: false,
                                        andUnlimitedIvRecoveryAllowed: true)
        
        // This test fails for 2 reasons: not enough time and IV Index change
        // exceeds limit of 42.
        XCTAssert(result0 == false)
        // Those tests should fails, as IV Index changed by more than 42.
        XCTAssert(result1 == false)
        XCTAssert(result2 == false)
        // This test returns false, as the time difference is not long enough.
        XCTAssert(result3 == false)
        // Those tests pass, as more than 42 * 192h + 96h have passed, and
        // the IV Index + 42 limit was turned off.
        XCTAssert(result4 == true)
        XCTAssert(result5 == true)
    }

}

private extension Date {
    
    init(hoursAgo: Double) {
        self = Date(timeIntervalSinceNow: -hoursAgo * 3600.0)
    }
    
}
