/*
* Copyright (c) 2021, Nordic Semiconductor
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

class DataTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testBitReader() throws {
        let data = Data([0x35, 0xC7, 0xC3, 0x07, 0x3F])

        // First and last byte
        XCTAssertEqual(data.readBits(8, fromOffset: 0), 0x35)
        XCTAssertEqual(data.readBits(8, fromOffset: 32), 0x3F)

        // Partial byte from byte boundary
        XCTAssertEqual(data.readBits(1, fromOffset: 0), 0x01)
        XCTAssertEqual(data.readBits(2, fromOffset: 0), 0x01)
        XCTAssertEqual(data.readBits(3, fromOffset: 0), 0x05)
        XCTAssertEqual(data.readBits(4, fromOffset: 0), 0x05)
        XCTAssertEqual(data.readBits(5, fromOffset: 0), 0x15)
        XCTAssertEqual(data.readBits(6, fromOffset: 0), 0x35)
        XCTAssertEqual(data.readBits(7, fromOffset: 0), 0x35)

        // Partial byte not from byte boundary
        XCTAssertEqual(data.readBits(1, fromOffset: 6), 0x00)
        XCTAssertEqual(data.readBits(2, fromOffset: 5), 0x01)
        XCTAssertEqual(data.readBits(3, fromOffset: 3), 0x06)
        XCTAssertEqual(data.readBits(4, fromOffset: 2), 0x0D)
        XCTAssertEqual(data.readBits(5, fromOffset: 1), 0x1A)

        // Multi byte from byte boundary
        XCTAssertEqual(data.readBits(9, fromOffset: 0), 0xC735-0xC600)
        XCTAssertEqual(data.readBits(15, fromOffset: 0), 0xC735-0x8000)
        XCTAssertEqual(data.readBits(16, fromOffset: 0), 0xC735)
        XCTAssertEqual(data.readBits(24, fromOffset: 0), 0xC3C735)
        XCTAssertEqual(data.readBits(32, fromOffset: 0), 0x07C3C735)
        XCTAssertEqual(data.readBits(40, fromOffset: 0), 0x3F07C3C735)

        // Multi byte not from byte boundary
        XCTAssertEqual(data.readBits(9, fromOffset: 1), 0x19A)
        XCTAssertEqual(data.readBits(4, fromOffset: 7), 0x0E)
        XCTAssertEqual(data.readBits(20, fromOffset: 10), 0x1F0F1)
    }

    func testBitWriter() throws {

        // First byte
        var oneByteData = Data(count: 1)
        oneByteData.writeBits(value: UInt8(0x35), numBits: 8, atOffset: 0)
        XCTAssertEqual(oneByteData, Data([0x35]))

        // Partial byte to byte boundary
        var partialByteBoundaryData = Data(count: 1)
        partialByteBoundaryData.writeBits(value: UInt8(0x35), numBits: 1, atOffset: 0)
        XCTAssertEqual(partialByteBoundaryData, Data([0x01]))
        partialByteBoundaryData.writeBits(value: UInt8(0x35), numBits: 2, atOffset: 0)
        XCTAssertEqual(partialByteBoundaryData, Data([0x01]))
        partialByteBoundaryData.writeBits(value: UInt8(0x35), numBits: 3, atOffset: 0)
        XCTAssertEqual(partialByteBoundaryData, Data([0x05]))
        partialByteBoundaryData.writeBits(value: UInt8(0x35), numBits: 4, atOffset: 0)
        XCTAssertEqual(partialByteBoundaryData, Data([0x05]))
        partialByteBoundaryData.writeBits(value: UInt8(0x35), numBits: 5, atOffset: 0)
        XCTAssertEqual(partialByteBoundaryData, Data([0x15]))
        partialByteBoundaryData.writeBits(value: UInt8(0x35), numBits: 6, atOffset: 0)
        XCTAssertEqual(partialByteBoundaryData, Data([0x35]))
        partialByteBoundaryData.writeBits(value: UInt8(0x35), numBits: 7, atOffset: 0)
        XCTAssertEqual(partialByteBoundaryData, Data([0x35]))

        // Partial byte not to byte boundary
        var partialByteNonBoundaryData = Data(count: 6)
        partialByteNonBoundaryData.writeBits(value: UInt8(0x35), numBits: 1, atOffset: 6)
        XCTAssertEqual(partialByteNonBoundaryData[0], 0x40)
        partialByteNonBoundaryData.writeBits(value: UInt8(0x35), numBits: 2, atOffset: 8+5)
        XCTAssertEqual(partialByteNonBoundaryData[1], 0x20)
        partialByteNonBoundaryData.writeBits(value: UInt8(0x35), numBits: 3, atOffset: 16+3)
        XCTAssertEqual(partialByteNonBoundaryData[2], 0x28)
        partialByteNonBoundaryData.writeBits(value: UInt8(0x35), numBits: 4, atOffset: 24+2)
        XCTAssertEqual(partialByteNonBoundaryData[3], 0x14)
        partialByteNonBoundaryData.writeBits(value: UInt8(0x35), numBits: 5, atOffset: 32+1)
        XCTAssertEqual(partialByteNonBoundaryData[4], 0x2A)

        // Multi byte from byte boundary
        var multiByteBoundaryData = Data(count: 5)
        multiByteBoundaryData.writeBits(value: UInt64(0x3F07C3C735), numBits: 9, atOffset: 0)
        XCTAssertEqual(multiByteBoundaryData, Data([0x35, 0x01, 0x00, 0x00, 0x00]))
        multiByteBoundaryData.writeBits(value: UInt64(0x3F07C3C735), numBits: 15, atOffset: 0)
        XCTAssertEqual(multiByteBoundaryData, Data([0x35, 0x47, 0x00, 0x00, 0x00]))
        multiByteBoundaryData.writeBits(value: UInt64(0x3F07C3C735), numBits: 16, atOffset: 0)
        XCTAssertEqual(multiByteBoundaryData, Data([0x35, 0xC7, 0x00, 0x00, 0x00]))
        multiByteBoundaryData.writeBits(value: UInt64(0x3F07C3C735), numBits: 24, atOffset: 0)
        XCTAssertEqual(multiByteBoundaryData, Data([0x35, 0xC7, 0xC3, 0x00, 0x00]))
        multiByteBoundaryData.writeBits(value: UInt64(0x3F07C3C735), numBits: 32, atOffset: 0)
        XCTAssertEqual(multiByteBoundaryData, Data([0x35, 0xC7, 0xC3, 0x07, 0x00]))
        multiByteBoundaryData.writeBits(value: UInt64(0x3F07C3C735), numBits: 40, atOffset: 0)
        XCTAssertEqual(multiByteBoundaryData, Data([0x35, 0xC7, 0xC3, 0x07, 0x3F]))

        // Multi byte not from byte boundary
        var multiByteNonBoundaryData = Data(count: 4)
        multiByteNonBoundaryData.writeBits(value: UInt64(0xC3C735), numBits: 9, atOffset: 1)
        XCTAssertEqual(multiByteNonBoundaryData, Data([0x6A, 0x02, 0x00, 0x00]))

        multiByteNonBoundaryData = Data(count: 4)
        multiByteNonBoundaryData.writeBits(value: UInt64(0xC3C735), numBits: 4, atOffset: 7)
        XCTAssertEqual(multiByteNonBoundaryData, Data([0x80, 0x02, 0x00, 0x00]))

        multiByteNonBoundaryData = Data(count: 4)
        multiByteNonBoundaryData.writeBits(value: UInt64(0xC3C735), numBits: 20, atOffset: 10)
        XCTAssertEqual(multiByteNonBoundaryData, Data([0x00, 0xD4, 0x1C, 0x0F]))
    }
}
