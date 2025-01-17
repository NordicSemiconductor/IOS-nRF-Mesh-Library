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
@testable import NordicMesh

class FirmwareUpdateMessages: XCTestCase {
    
    func testFirmwareUpdateInformationStatus() {
        let data = Data(hex: "03070559000102031A68747470733A2F2F7777772E6E6F7264696373656D692E636F6D044C00AABB2A68747470733A2F2F6D6573682E6578616D706C652E636F6D2F636865636B2D666F722D757064617465730334120100")
        
        let status = FirmwareUpdateInformationStatus(parameters: data)
        XCTAssertNotNil(status)
        XCTAssertEqual(status?.firstIndex, 7)
        XCTAssertEqual(status?.entries.count, 3)
        XCTAssertEqual(status?.entries[0].currentFirmwareId.companyIdentifier, 0x0059)
        XCTAssertEqual(status?.entries[0].currentFirmwareId.version, Data(hex: "010203"))
        XCTAssertEqual(status?.entries[0].updateUri, URL(string: "https://www.nordicsemi.com")!)
        XCTAssertEqual(status?.entries[1].currentFirmwareId.companyIdentifier, 0x004C)
        XCTAssertEqual(status?.entries[1].currentFirmwareId.version, Data(hex: "AABB"))
        XCTAssertEqual(status?.entries[1].updateUri, URL(string: "https://mesh.example.com/check-for-updates")!)
        XCTAssertEqual(status?.entries[2].currentFirmwareId.companyIdentifier, 0x1234)
        XCTAssertEqual(status?.entries[2].currentFirmwareId.version, Data(hex: "01"))
        XCTAssertNil(status?.entries[2].updateUri)
        
        let encoded = status?.parameters
        XCTAssertEqual(encoded, data)
    }
    
    func testFirmwareUpdateInformationStatus_basic() {
        let data = Data(hex: "0000")
        
        let status = FirmwareUpdateInformationStatus(parameters: data)
        XCTAssertNotNil(status)
        XCTAssertEqual(status?.firstIndex, 0)
        XCTAssertEqual(status?.entries.count, 0)
        
        let encoded = status?.parameters
        XCTAssertEqual(encoded, data)
    }
    
    func testFirmwareUpdateInformationStatus_invalid() {
        let missingLastByte = Data(hex: "03000559000102031A68747470733A2F2F7777772E6E6F7264696373656D692E636F6D044C00AABB2A68747470733A2F2F6D6573682E6578616D706C652E636F6D2F636865636B2D666F722D7570646174657303341201")
        XCTAssertNil(FirmwareUpdateInformationStatus(parameters: missingLastByte))
        
        let wrongCount = Data(hex: "04000559000102031A68747470733A2F2F7777772E6E6F7264696373656D692E636F6D044C00AABB2A68747470733A2F2F6D6573682E6578616D706C652E636F6D2F636865636B2D666F722D757064617465730334120100")
        XCTAssertNil(FirmwareUpdateInformationStatus(parameters: wrongCount))
        
        let missingRandomByte = Data(hex: "03000559000102031A68747470733A2F2F7777772E6E6F72646963736D692E636F6D044C00AABB2A68747470733A2F2F6D6573682E6578616D706C652E636F6D2F636865636B2D666F722D7570646174657303341201")
        XCTAssertNil(FirmwareUpdateInformationStatus(parameters: missingRandomByte))
    }
    
}
