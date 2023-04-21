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

class SchedulerMessages: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSchedulerEntryMarshalling() throws {
        let data = SchedulerRegistryEntry.marshal(
            index: 3,
            entry: SchedulerRegistryEntry(
                year: SchedulerYear.specific(year: 35),
                month: SchedulerMonth.any(of: [Month.April]),
                day: SchedulerDay.specific(day: 12),
                hour: SchedulerHour.specific(hour: 5),
                minute: SchedulerMinute.every15(),
                second: SchedulerSecond.random(),
                dayOfWeek: SchedulerDayOfWeek.any(of: [WeekDay.Saturday]),
                action: SchedulerAction.sceneRecall,
                transitionTime: TransitionTime(steps: 5, stepResolution: StepResolution.seconds),
                sceneNumber: 10)
        )
        
        XCTAssertEqual(data, Data([51, 66, 0, 86, 250, 31, 36, 69, 10, 0]))
    }

    func testSchedulerEntryUnmarshalling() throws {
        let entry = SchedulerRegistryEntry.unmarshal(Data([51, 66, 0, 86, 250, 31, 36, 69, 10, 0]))
        
        XCTAssertEqual(entry.index, 3)
        XCTAssertEqual(entry.entry.year.value, 35)
        XCTAssertEqual(entry.entry.month.value, Month.April.rawValue)

        XCTAssertEqual(entry.entry.day.value, 12)
        XCTAssertEqual(entry.entry.hour.value, 5)
        XCTAssertEqual(entry.entry.minute.value, SchedulerMinute.every15().value)
        XCTAssertEqual(entry.entry.second.value, SchedulerSecond.random().value)
        XCTAssertEqual(entry.entry.dayOfWeek.value, WeekDay.Saturday.rawValue)
        XCTAssertEqual(entry.entry.action, SchedulerAction.sceneRecall)
        XCTAssertEqual(entry.entry.transitionTime.stepResolution, StepResolution.seconds)
        XCTAssertEqual(entry.entry.transitionTime.steps, 5)
        XCTAssertEqual(entry.entry.sceneNumber, 10)
    }
}
