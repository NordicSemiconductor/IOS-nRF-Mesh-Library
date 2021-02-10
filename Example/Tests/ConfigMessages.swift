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

class ConfigMessages: XCTestCase {

    func testEncodingConfigNetKeyAdd() {
        let networkKey = try! NetworkKey(name: "Test", index: 0x123, key: Data(hex: "00112233445566778899AABBCCDDEEFF"))
        let message = ConfigNetKeyAdd(networkKey: networkKey)
        
        XCTAssertEqual(message.networkKeyIndex, 0x123)
        XCTAssertEqual(message.parameters, Data(hex: "230100112233445566778899AABBCCDDEEFF"))
    }
    
    func testDecodingConfigNetKeyAdd() {
        let message = ConfigNetKeyAdd(parameters: Data(hex: "230100112233445566778899AABBCCDDEEFF"))
        
        XCTAssertNotNil(message)
        XCTAssertEqual(message?.networkKeyIndex, 0x123)
        XCTAssertEqual(message?.key, Data(hex: "00112233445566778899AABBCCDDEEFF"))
    }
    
    func testEncodingConfigAppKeyAdd() {
        let networkKey = try! NetworkKey(name: "Test", index: 0x123, key: Data(hex: "00112233445566778899AABBCCDDEEFF"))
        let applicationKey = try! ApplicationKey(name: "Test", index: 0x456, key: Data(hex: "0123456789ABCDEF0123456789ABCDEF"), boundTo: networkKey)
        
        let meshNetwork = MeshNetwork(name: "Test Network")
        meshNetwork.networkKeys.append(networkKey)
        meshNetwork.applicationKeys.append(applicationKey)
        applicationKey.meshNetwork = meshNetwork
        
        let message = ConfigAppKeyAdd(applicationKey: applicationKey)
        
        XCTAssertEqual(message.networkKeyIndex, 0x123)
        XCTAssertEqual(message.applicationKeyIndex, 0x456)
        XCTAssertEqual(message.parameters, Data(hex: "2361450123456789ABCDEF0123456789ABCDEF"))
    }
    
    func testDecodingConfigAppKeyAdd() {
        let message = ConfigAppKeyAdd(parameters: Data(hex: "2361450123456789ABCDEF0123456789ABCDEF"))
        
        XCTAssertNotNil(message)
        XCTAssertEqual(message?.networkKeyIndex, 0x123)
        XCTAssertEqual(message?.applicationKeyIndex, 0x456)
        XCTAssertEqual(message?.key, Data(hex: "0123456789ABCDEF0123456789ABCDEF"))
    }
    
    func testEncodingConfigAppKeyList() {
        let networkKey = try! NetworkKey(name: "Test", index: 0x123, key: Data(hex: "00112233445566778899AABBCCDDEEFF"))
        let applicationKey = try! ApplicationKey(name: "Test", index: 0x456, key: Data(hex: "0123456789ABCDEF0123456789ABCDEF"), boundTo: networkKey)
        
        let meshNetwork = MeshNetwork(name: "Test Network")
        meshNetwork.networkKeys.append(networkKey)
        meshNetwork.applicationKeys.append(applicationKey)
        applicationKey.meshNetwork = meshNetwork
        
        let request = ConfigAppKeyGet(networkKey: networkKey)
        let message = ConfigAppKeyList(responseTo: request, with: [applicationKey])
        
        XCTAssertEqual(message.networkKeyIndex, 0x123)
        XCTAssertEqual(message.applicationKeyIndexes, [0x456])
        XCTAssertEqual(message.parameters, Data(hex: "0023015604"))
    }
    
    func testDecodingConfigAppKeyList() {
        let message = ConfigAppKeyList(parameters: Data(hex: "0023015604"))
        
        XCTAssertNotNil(message)
        XCTAssertEqual(message?.networkKeyIndex, 0x123)
        XCTAssertEqual(message?.applicationKeyIndexes, [0x456])
        XCTAssertEqual(message?.status, .success)
    }

}
