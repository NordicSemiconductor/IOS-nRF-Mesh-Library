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
        let data = Data(hex: "07030559000102031A68747470733A2F2F7777772E6E6F7264696373656D692E636F6D044C00AABB2A68747470733A2F2F6D6573682E6578616D706C652E636F6D2F636865636B2D666F722D757064617465730334120100")
        
        let status = FirmwareUpdateInformationStatus(parameters: data)
        XCTAssertNotNil(status)
        XCTAssertEqual(status?.totalCount, 7)
        XCTAssertEqual(status?.firstIndex, 3)
        XCTAssertEqual(status?.list.count, 3)
        XCTAssertEqual(status?.list[0].currentFirmwareId.companyIdentifier, 0x0059)
        XCTAssertEqual(status?.list[0].currentFirmwareId.version, Data(hex: "010203"))
        XCTAssertEqual(status?.list[0].updateUri, URL(string: "https://www.nordicsemi.com")!)
        XCTAssertEqual(status?.list[1].currentFirmwareId.companyIdentifier, 0x004C)
        XCTAssertEqual(status?.list[1].currentFirmwareId.version, Data(hex: "AABB"))
        XCTAssertEqual(status?.list[1].updateUri, URL(string: "https://mesh.example.com/check-for-updates")!)
        XCTAssertEqual(status?.list[2].currentFirmwareId.companyIdentifier, 0x1234)
        XCTAssertEqual(status?.list[2].currentFirmwareId.version, Data(hex: "01"))
        XCTAssertNil(status?.list[2].updateUri)
        
        let encoded = status?.parameters
        XCTAssertEqual(encoded, data)
        
        let status2 = FirmwareUpdateInformationStatus(
            list: [
                .init(currentFirmwareId: FirmwareId(companyIdentifier: 0x0059, version: Data(hex: "010203")), updateUri: URL(string: "https://www.nordicsemi.com")),
                .init(currentFirmwareId: FirmwareId(companyIdentifier: 0x004C, version: Data(hex: "AABB")), updateUri: URL(string: "https://mesh.example.com/check-for-updates")),
                .init(currentFirmwareId: FirmwareId(companyIdentifier: 0x1234, version: Data(hex: "01")), updateUri: nil)
            ],
            from: 3,
            outOf: 7
        )
        XCTAssertEqual(status2.parameters, encoded)
        XCTAssertEqual(status2.totalCount, status?.totalCount)
        XCTAssertEqual(status2.firstIndex, status?.firstIndex)
        XCTAssertEqual(status2.list.count, status?.list.count)
        XCTAssertEqual(status2.list[0].currentFirmwareId.companyIdentifier, status?.list[0].currentFirmwareId.companyIdentifier)
        XCTAssertEqual(status2.list[0].currentFirmwareId.version,           status?.list[0].currentFirmwareId.version)
        XCTAssertEqual(status2.list[0].updateUri,                           status?.list[0].updateUri)
        XCTAssertEqual(status2.list[1].currentFirmwareId.companyIdentifier, status?.list[1].currentFirmwareId.companyIdentifier)
        XCTAssertEqual(status2.list[1].currentFirmwareId.version,           status?.list[1].currentFirmwareId.version)
        XCTAssertEqual(status2.list[1].updateUri,                           status?.list[1].updateUri)
        XCTAssertEqual(status2.list[2].currentFirmwareId.companyIdentifier, status?.list[2].currentFirmwareId.companyIdentifier)
        XCTAssertEqual(status2.list[2].currentFirmwareId.version,           status?.list[2].currentFirmwareId.version)
        XCTAssertNil(status2.list[2].updateUri)
        
    }
    
    func testFirmwareUpdateInformationStatus_basic() {
        let data = Data(hex: "0000")
        
        let status = FirmwareUpdateInformationStatus(parameters: data)
        XCTAssertNotNil(status)
        XCTAssertEqual(status?.firstIndex, 0)
        XCTAssertEqual(status?.list.count, 0)
        
        let encoded = status?.parameters
        XCTAssertEqual(encoded, data)
    }
    
    func testFirmwareUpdateInformationStatus_invalid() {
        let missingLastByte = Data(hex: "03000559000102031A68747470733A2F2F7777772E6E6F7264696373656D692E636F6D044C00AABB2A68747470733A2F2F6D6573682E6578616D706C652E636F6D2F636865636B2D666F722D7570646174657303341201")
        XCTAssertNil(FirmwareUpdateInformationStatus(parameters: missingLastByte))
        
        let missingRandomByte = Data(hex: "03000559000102031A68747470733A2F2F7777772E6E6F72646963736D692E636F6D044C00AABB2A68747470733A2F2F6D6573682E6578616D706C652E636F6D2F636865636B2D666F722D7570646174657303341201")
        XCTAssertNil(FirmwareUpdateInformationStatus(parameters: missingRandomByte))
    }
    
    func testFirmwareDistributionReceiversList_simple() {
        let data = Data(hex: "BBAA01AAFFFE4D0501")
        
        let list = FirmwareDistributionReceiversList(parameters: data)
        XCTAssertNotNil(list)
        XCTAssertEqual(list?.totalCount, 0xAABB)
        XCTAssertEqual(list?.firstIndex, 0xAA01)
        XCTAssertEqual(list?.receivers.count, 1)
        XCTAssertEqual(list?.receivers[0].address, 0x7FFF)
        XCTAssertEqual(list?.receivers[0].phase, .transferActive)
        XCTAssertEqual(list?.receivers[0].updateStatus, .internalError)
        XCTAssertEqual(list?.receivers[0].transferStatus, .wrongPhase)
        XCTAssertEqual(list?.receivers[0].transferProgress, 10)
        XCTAssertEqual(list?.receivers[0].imageIndex, 1)
        
        XCTAssertEqual(list?.parameters, data)
    }
    
    func testFirmwareDistributionReceiversList_double() {
        let data = Data(hex: "0300000001010032FF0102FCC102")
        
        let list = FirmwareDistributionReceiversList(parameters: data)
        XCTAssertNotNil(list)
        XCTAssertEqual(list?.totalCount, 3)
        XCTAssertEqual(list?.firstIndex, 0)
        XCTAssertEqual(list?.receivers.count, 2)
        XCTAssertEqual(list?.receivers[0].address, 0x0001)
        XCTAssertEqual(list?.receivers[0].phase, .applySuccess)
        XCTAssertEqual(list?.receivers[0].updateStatus, .success)
        XCTAssertEqual(list?.receivers[0].transferStatus, .success)
        XCTAssertEqual(list?.receivers[0].transferProgress, 100)
        XCTAssertEqual(list?.receivers[0].imageIndex, 0xFF)
        XCTAssertEqual(list?.receivers[1].address, 0x0101)
        XCTAssertEqual(list?.receivers[1].phase, .transferCanceled)
        XCTAssertEqual(list?.receivers[1].updateStatus, .blobTransferBusy)
        XCTAssertEqual(list?.receivers[1].transferStatus, .invalidChunkSize)
        XCTAssertEqual(list?.receivers[1].transferProgress, 2)
        XCTAssertEqual(list?.receivers[1].imageIndex, 2)
        
        XCTAssertEqual(list?.parameters, data)
    }
    
    func testFirmwareDistributionReceiversList_empty() {
        let list = FirmwareDistributionReceiversList(
            receivers: [], from: 3, outOf: 2
        )
        XCTAssertEqual(list.totalCount, 2)
        XCTAssertEqual(list.firstIndex, 3)
        XCTAssertEqual(list.receivers.count, 0)
    }
    
    func testFirmwareDistributionReceiversList() {
        let list = FirmwareDistributionReceiversList(
            receivers: [
                .init(address: 0x0001, phase: .applySuccess, updateStatus: .success, transferStatus: .success, transferProgress: 100, imageIndex: 0xFF),
                .init(address: 0x0101, phase: .transferCanceled, updateStatus: .blobTransferBusy, transferStatus: .invalidChunkSize, transferProgress: 2, imageIndex: 2),
                .init(address: 0x2BCD, phase: .idle, updateStatus: .wrongFirmwareIndex, transferStatus: .blobTooLarge, transferProgress: 33, imageIndex: 11)
            ],
            from: 1,
            outOf: 22
        )
        
        XCTAssertEqual(list.parameters, Data(hex: "1600010001010032FF0102FCC102CD5611D00B"))
        
        let list2 = FirmwareDistributionReceiversList(parameters: list.parameters!)
        XCTAssertEqual(list.firstIndex,                    list2?.firstIndex)
        XCTAssertEqual(list.totalCount,                list2?.totalCount)
        XCTAssertEqual(list.receivers.count,               list2?.receivers.count)
        XCTAssertEqual(list.receivers[0].address,          list2?.receivers[0].address)
        XCTAssertEqual(list.receivers[0].phase,            list2?.receivers[0].phase)
        XCTAssertEqual(list.receivers[0].updateStatus,     list2?.receivers[0].updateStatus)
        XCTAssertEqual(list.receivers[0].transferStatus,   list2?.receivers[0].transferStatus)
        XCTAssertEqual(list.receivers[0].transferProgress, list2?.receivers[0].transferProgress)
        XCTAssertEqual(list.receivers[0].imageIndex,       list2?.receivers[0].imageIndex)
        XCTAssertEqual(list.receivers[1].address,          list2?.receivers[1].address)
        XCTAssertEqual(list.receivers[1].phase,            list2?.receivers[1].phase)
        XCTAssertEqual(list.receivers[1].updateStatus,     list2?.receivers[1].updateStatus)
        XCTAssertEqual(list.receivers[1].transferStatus,   list2?.receivers[1].transferStatus)
        XCTAssertEqual(list.receivers[1].transferProgress, list2?.receivers[1].transferProgress)
        XCTAssertEqual(list.receivers[1].imageIndex,       list2?.receivers[1].imageIndex)
        XCTAssertEqual(list.receivers[2].address,          list2?.receivers[2].address)
        XCTAssertEqual(list.receivers[2].phase,            list2?.receivers[2].phase)
        XCTAssertEqual(list.receivers[2].updateStatus,     list2?.receivers[2].updateStatus)
        XCTAssertEqual(list.receivers[2].transferStatus,   list2?.receivers[2].transferStatus)
        XCTAssertEqual(list.receivers[2].transferProgress, list2?.receivers[2].transferProgress)
        XCTAssertEqual(list.receivers[2].imageIndex,       list2?.receivers[2].imageIndex)
    }
    
}
