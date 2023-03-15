/*
* Copyright (c) 2023, Nordic Semiconductor
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
import CoreBluetooth
@testable import nRFMeshProvision

class RemoteProvisioning: XCTestCase {
    let rssi: NSNumber = -50 // dBm
    let uuid = CBUUID(string: "68753A44-4D6F-1226-9C60-0050E4C00067")
    let oobInformation = OobInformation(rawValue: 0xA040)
    let uriHash = Data(hex: "01020304")
    
    func testOobInformation() throws {
        XCTAssert(oobInformation.contains(.string))
        XCTAssert(oobInformation.contains(.onPieceOfPaper))
        XCTAssert(oobInformation.contains(.onDevice))
        XCTAssertFalse(oobInformation.contains(.insideManual))
    }
    
    func testScanReport_advertisementData() throws {
        let sd: [CBUUID : Data] = [
            // UUID in Big Endian.
            // OOB in Little Endian.
            // Don't ask why...
            // See Sample Data 8.5.1 in Mesh Protocol 1.1.
            MeshProvisioningService.uuid: Data(hex: "70cf7c9732a345b691494810d2e9cbf42040")
        ]
        let ad: [String : Any] = [
            CBAdvertisementDataIsConnectable: true,
            CBAdvertisementDataLocalNameKey: "test",
            CBAdvertisementDataServiceDataKey: sd
        ]
        let report = RemoteProvisioningScanReport(rssi: rssi, advertisementData: ad)
        XCTAssertNotNil(report)
        XCTAssertEqual(report?.rssi, rssi)
        XCTAssertEqual(report?.uuid, CBUUID(string: "70cf7c97-32a3-45b6-9149-4810d2e9cbf4"))
        XCTAssertEqual(report?.oobInformation, [.number, .insideManual])
        XCTAssertNil(report?.uriHash)
    }
    
    func testScanReport_withHash() throws {
        let report = RemoteProvisioningScanReport(rssi: rssi, uuid: uuid, oobInformation: oobInformation, uriHash: uriHash)
        XCTAssertEqual(report.rssi, rssi)
        XCTAssertEqual(report.uuid, uuid)
        XCTAssertEqual(report.oobInformation, oobInformation)
        XCTAssertNotNil(report.uriHash)
        XCTAssertEqual(report.uriHash, uriHash)
        
        let expectedData = Data(hex: "CE68753A444D6F12269C600050E4C00067A04001020304")
        XCTAssertEqual(report.parameters, expectedData)
    }
    
    func testScanReport_withoutHash() throws {
        let report = RemoteProvisioningScanReport(rssi: rssi, uuid: uuid, oobInformation: oobInformation)
        XCTAssertEqual(report.rssi, rssi)
        XCTAssertEqual(report.uuid, uuid)
        XCTAssertEqual(report.oobInformation, oobInformation)
        XCTAssertNil(report.uriHash)
        
        let expectedData = Data(hex: "CE68753A444D6F12269C600050E4C00067A040")
        XCTAssertEqual(report.parameters, expectedData)
    }
    
    func testScanReport_deserialization_withHash() throws {
        let receivedData = Data(hex: "CE68753A444D6F12269C600050E4C00067A04001020304")
        let report = RemoteProvisioningScanReport(parameters: receivedData)
        
        XCTAssertNotNil(report)
        XCTAssertEqual(report?.rssi, rssi)
        XCTAssertEqual(report?.uuid, uuid)
        XCTAssertEqual(report?.oobInformation, oobInformation)
        XCTAssertNotNil(report?.uriHash)
        XCTAssertEqual(report?.uriHash, uriHash)
    }
    
    func testScanReport_deserialization_withputHash() throws {
        let receivedData = Data(hex: "CE68753A444D6F12269C600050E4C00067A040")
        let report = RemoteProvisioningScanReport(parameters: receivedData)
        
        XCTAssertNotNil(report)
        XCTAssertEqual(report?.rssi, rssi)
        XCTAssertEqual(report?.uuid, uuid)
        XCTAssertEqual(report?.oobInformation, oobInformation)
        XCTAssertNil(report?.uriHash)
    }
    
    func testExtendedScanStart_localName() throws {
        let request = RemoteProvisioningExtendedScanStart(filter: .localName)
        XCTAssertEqual(request.adTypeFilterCount, 1)
        XCTAssertEqual(request.adTypeFilter, [0x09])
        XCTAssertNil(request.uuid)
        XCTAssertNil(request.timeout)
        
        let expectedData = Data(hex: "0109")
        XCTAssertEqual(request.parameters, expectedData)
    }
    
    func testExtendedScanStart_multi() throws {
        let request = RemoteProvisioningExtendedScanStart(filter: [.localName, .uri])
        XCTAssertEqual(request.adTypeFilterCount, 2)
        XCTAssertEqual(request.adTypeFilter, [AdType.localName.rawValue, AdType.uri.rawValue])
        XCTAssertNil(request.uuid)
        XCTAssertNil(request.timeout)
        
        let expectedData = Data(hex: "020924")
        XCTAssertEqual(request.parameters, expectedData)
    }
    
    func testExtendedScanReport_scanningCannotStart() throws {
        let receivedData = Data(hex: "0168753A444D6F12269C600050E4C00067")
        let response = RemoteProvisioningExtendedScanReport(parameters: receivedData)
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.status, .scanningCannotStart)
        XCTAssertEqual(response?.uuid, uuid)
        XCTAssertNil(response?.oobInformation)
        XCTAssertNil(response?.localName)
        XCTAssertNil(response?.uri)
        XCTAssertNil(response?.serviceData)
        XCTAssertNil(response?.serviceUUIDs)
        XCTAssertNil(response?.serviceSolicitationUUIDs)
    }
    
    func testExtendedScanReport_localName() throws {
        let receivedData = Data(hex: "0068753A444D6F12269C600050E4C00067A040050974657374")
        let response = RemoteProvisioningExtendedScanReport(parameters: receivedData)
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.uuid, uuid)
        XCTAssertEqual(response?.oobInformation, oobInformation)
        XCTAssertEqual(response?.localName, "test")
        XCTAssertNil(response?.uri)
        XCTAssertNil(response?.serviceData)
        XCTAssertNil(response?.serviceUUIDs)
        XCTAssertNil(response?.serviceSolicitationUUIDs)
    }
    
    func testExtendedScanReport_16bitServiceUUIDs() throws {
        let receivedData = Data(hex: "0068753A444D6F12269C600050E4C00067A040050309180218")
        let response = RemoteProvisioningExtendedScanReport(parameters: receivedData)
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.uuid, uuid)
        XCTAssertEqual(response?.oobInformation, oobInformation)
        XCTAssertEqual(response?.serviceUUIDs?.count, 2)
        XCTAssert(response?.serviceUUIDs?.contains(CBUUID(string: "1802")) ?? false)
        XCTAssert(response?.serviceUUIDs?.contains(CBUUID(string: "1809")) ?? false)
        XCTAssertNil(response?.localName)
        XCTAssertNil(response?.uri)
        XCTAssertNil(response?.serviceData)
        XCTAssertNil(response?.serviceSolicitationUUIDs)
    }
    
    func testExtendedScanReport_serviceUUIDs() throws {
        let receivedData = Data(hex: "0068753A444D6F12269C600050E4C00067A0400303091811076700C0E45000609C26126F4D443A7568")
        let response = RemoteProvisioningExtendedScanReport(parameters: receivedData)
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.uuid, uuid)
        XCTAssertEqual(response?.oobInformation, oobInformation)
        XCTAssertEqual(response?.serviceUUIDs?.count, 2)
        XCTAssert(response?.serviceUUIDs?.contains(CBUUID(string: "1809")) ?? false)
        XCTAssert(response?.serviceUUIDs?.contains(uuid) ?? false)
        XCTAssertNil(response?.localName)
        XCTAssertNil(response?.uri)
        XCTAssertNil(response?.serviceData)
        XCTAssertNil(response?.serviceSolicitationUUIDs)
    }
    
    func testExtendedScanReport_serviceData() throws {
        let receivedData = Data(hex: "0068753A444D6F12269C600050E4C00067A0400716CDAB01020304")
        let response = RemoteProvisioningExtendedScanReport(parameters: receivedData)
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.uuid, uuid)
        XCTAssertEqual(response?.oobInformation, oobInformation)
        XCTAssertNotNil(response?.serviceData)
        XCTAssertEqual(response?.serviceData?[CBUUID(string: "ABCD")], Data(hex: "01020304"))
        XCTAssertNil(response?.localName)
        XCTAssertNil(response?.uri)
        XCTAssertNil(response?.serviceUUIDs)
        XCTAssertNil(response?.serviceSolicitationUUIDs)
    }
    
    func testExtendedScanReport_128bitServiceData() throws {
        let receivedData = Data(hex: "0068753A444D6F12269C600050E4C00067000016216700C0E45000609C26126F4D443A75680102030405")
        let response = RemoteProvisioningExtendedScanReport(parameters: receivedData)
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.uuid, uuid)
        XCTAssertEqual(response?.oobInformation, [])
        XCTAssertNotNil(response?.serviceData)
        XCTAssertEqual(response?.serviceData?[uuid], Data(hex: "0102030405"))
        XCTAssertNil(response?.localName)
        XCTAssertNil(response?.uri)
        XCTAssertNil(response?.serviceUUIDs)
        XCTAssertNil(response?.serviceSolicitationUUIDs)
    }
    
    func testScanStart() throws {
        let request = RemoteProvisioningScanStart(scannedItemsLimit: 2, timeout: 11.0)
        XCTAssertEqual(request.scannedItemsLimit, 2)
        XCTAssertEqual(request.timeout, 11.0)
        XCTAssertNil(request.uuid)
        
        let expectedData = Data(hex: "020B")
        XCTAssertEqual(request.parameters, expectedData)
    }
    
    func testScanStart_deserialization() throws {
        let receivedData = Data(hex: "020B")
        let request = RemoteProvisioningScanStart(parameters: receivedData)
        XCTAssertNotNil(request)
        XCTAssertEqual(request?.scannedItemsLimit, 2)
        XCTAssertEqual(request?.timeout, 11.0)
        XCTAssertNil(request?.uuid)
    }
    
    func testScanStart_withUUID() throws {
        let request = RemoteProvisioningScanStart(scannedItemsLimit: 5, timeout: 10.0, uuid: uuid)
        XCTAssertEqual(request.scannedItemsLimit, 5)
        XCTAssertEqual(request.timeout, 10.0)
        XCTAssertEqual(request.uuid, uuid)
        
        let expectedData = Data(hex: "050A68753A444D6F12269C600050E4C00067")
        XCTAssertEqual(request.parameters, expectedData)
    }
    
    func testScanStart_withUUID_deserialization() throws {
        let receivedData = Data(hex: "050A68753A444D6F12269C600050E4C00067")
        let request = RemoteProvisioningScanStart(parameters: receivedData)
        XCTAssertNotNil(request)
        XCTAssertEqual(request?.scannedItemsLimit, 5)
        XCTAssertEqual(request?.timeout, 10.0)
        XCTAssertEqual(request?.uuid, uuid)
    }
    
}
