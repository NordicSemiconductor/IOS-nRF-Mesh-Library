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

class ProxyProtocol: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testSimpleMessage() {
        let proxyProtocol = ProxyProtocolHandler()
        
        let data = Data([0,1,2,3,4,5,6,7,8,9])
        let packets = proxyProtocol.segment(data, ofType: .networkPdu, toMtu: 11)
        
        XCTAssertEqual(packets.count, 1)
        XCTAssert(packets[0] == Data([0,0,1,2,3,4,5,6,7,8,9]))
    }
    
    func testShortMtuMessage() {
        let proxyProtocol = ProxyProtocolHandler()
        
        let data = Data([0,1,2,3,4,5,6,7,8,9])
        let packets = proxyProtocol.segment(data, ofType: .meshBeacon, toMtu: 4)
        
        XCTAssertEqual(packets.count, 4)
        XCTAssert(packets[0] == Data([(1 << 6) | 1, 0,1,2]))
        XCTAssert(packets[1] == Data([(2 << 6) | 1, 3,4,5]))
        XCTAssert(packets[2] == Data([(2 << 6) | 1, 6,7,8]))
        XCTAssert(packets[3] == Data([(3 << 6) | 1, 9]))
    }

    func testSimpleProvisioningMessage() {
        let proxyProtocol = ProxyProtocolHandler()
        
        let request = ProvisioningRequest.invite(attentionTimer: 5)
        let packets = proxyProtocol.segment(request.pdu, ofType: .provisioningPdu, toMtu: 20)
        
        XCTAssertEqual(packets.count, 1)
        XCTAssert(packets[0] == Data([3, 0, 5]))
    }
    
    func testMediumProvisioningMessage() {
        let proxyProtocol = ProxyProtocolHandler()
        
        let data = Data([0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9])
        let packets = proxyProtocol.segment(data, ofType: .provisioningPdu, toMtu: 20)
        
        XCTAssertEqual(packets.count, 2)
        XCTAssert(packets[0] == Data([(1 << 6) | 3, 0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8]))
        XCTAssert(packets[1] == Data([(3 << 6) | 3, 9,0,1,2,3,4,5,6,7,8,9]))
    }
    
    func testLongProvisioningMessage() {
        let proxyProtocol = ProxyProtocolHandler()
        
        let data = Data([0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,
                         0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,
                         0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9])
        let packets = proxyProtocol.segment(data, ofType: .provisioningPdu, toMtu: 20)
        
        XCTAssertEqual(packets.count, 5)
        XCTAssert(packets[0] == Data([(1 << 6) | 3, 0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8]))
        XCTAssert(packets[1] == Data([(2 << 6) | 3, 9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7]))
        XCTAssert(packets[2] == Data([(2 << 6) | 3, 8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6]))
        XCTAssert(packets[3] == Data([(2 << 6) | 3, 7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5]))
        XCTAssert(packets[4] == Data([(3 << 6) | 3, 6,7,8,9,0,1,2,3,4,5,6,7,8,9]))
    }
    
    func testSimpleMessageReassembly() {
        let proxyProtocol = ProxyProtocolHandler()
        
        let data = Data([3, 0, 5])
        let result = proxyProtocol.reassemble(data)
        
        XCTAssertNotNil(result)
        XCTAssert(result!.messageType == .provisioningPdu)
        XCTAssert(result!.data == Data([0,5]))
    }
    
    func testLongMessageReassembly() {
        let proxyProtocol = ProxyProtocolHandler()
        
        var result = proxyProtocol.reassemble(Data([(1 << 6) | 3, 0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8]))
        XCTAssertNil(result)
        result = proxyProtocol.reassemble(Data([(2 << 6) | 3, 9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7]))
        XCTAssertNil(result)
        result = proxyProtocol.reassemble(Data([(2 << 6) | 3, 8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6]))
        XCTAssertNil(result)
        result = proxyProtocol.reassemble(Data([(2 << 6) | 3, 7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5]))
        XCTAssertNil(result)
        result = proxyProtocol.reassemble(Data([(3 << 6) | 3, 6,7,8,9,0,1,2,3,4,5,6,7,8,9]))
        XCTAssertNotNil(result)
        XCTAssert(result!.messageType == .provisioningPdu)
        
        let data = Data([0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,
                         0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,
                         0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9])
        XCTAssert(result!.data == data)
    }
    
    func testInvalidMessageReassembly() {
        let proxyProtocol = ProxyProtocolHandler()
        
        let data = Data([4, 0, 5])
        let result = proxyProtocol.reassemble(data)
        
        XCTAssertNil(result)
    }
    
    func testSkippingPacketInReassembly_wrongSAR() {
        let proxyProtocol = ProxyProtocolHandler()
        
        var result = proxyProtocol.reassemble(Data([(1 << 6) | 1, 0,1,2,3,4,5,6,7,8,9])) // First packet
        XCTAssertNil(result)
        result = proxyProtocol.reassemble(Data([(1 << 6) | 1, 0,1,2,3,4,5,6,7,8,9])) // Again first packet
        XCTAssertNil(result)
        result = proxyProtocol.reassemble(Data([(3 << 6) | 1, 0,1,2,3,4,5,6,7,8,9])) // Last packet
        XCTAssertNotNil(result)
        XCTAssert(result!.messageType == .meshBeacon)
        
        let data = Data([0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9])
        XCTAssert(result!.data == data)
    }
    
    func testSkippingPacketInReassembly_wrongMessageType() {
        let proxyProtocol = ProxyProtocolHandler()
        
        var result = proxyProtocol.reassemble(Data([(1 << 6) | 0, 0,1,2,3,4,5,6,7,8,9])) // First packet
        XCTAssertNil(result)
        result = proxyProtocol.reassemble(Data([(2 << 6) | 2, 0,1,2,3,4,5,6,7,8,9])) // Wrong message type
        XCTAssertNil(result)
        result = proxyProtocol.reassemble(Data([(3 << 6) | 0, 0,1,2,3,4,5,6,7,8,9])) // Last packet
        XCTAssertNotNil(result)
        XCTAssert(result!.messageType == .networkPdu)
        
        let data = Data([0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9])
        XCTAssert(result!.data == data)
    }

}
