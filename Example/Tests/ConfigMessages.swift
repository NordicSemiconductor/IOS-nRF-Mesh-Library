//
//  ConfigMessages.swift
//  nRFMeshProvision_Tests
//
//  Created by Aleksander Nowakowski on 28/06/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import nRFMeshProvision

class ConfigMessages: XCTestCase {

    func testEncodingConfigNetKeyAdd() {
        let networkKey = try! NetworkKey(name: "Test", index: 0x123, key: Data(hex: "00112233445566778899AABBCCDDEEFF")!)
        let message = ConfigNetKeyAdd(networkKey: networkKey)
        
        XCTAssertEqual(message.networkKeyIndex, 0x123)
        XCTAssertEqual(message.parameters, Data(hex: "230100112233445566778899AABBCCDDEEFF"))
    }
    
    func testDecodingConfigNetKeyAdd() {
        let message = ConfigNetKeyAdd(parameters: Data(hex: "230100112233445566778899AABBCCDDEEFF")!)
        
        XCTAssertNotNil(message)
        XCTAssertEqual(message?.networkKeyIndex, 0x123)
        XCTAssertEqual(message?.key, Data(hex: "00112233445566778899AABBCCDDEEFF")!)
    }
    
    func testEncodingConfigAppKeyAdd() {
        let networkKey = try! NetworkKey(name: "Test", index: 0x123, key: Data(hex: "00112233445566778899AABBCCDDEEFF")!)
        let applicationKey = try! ApplicationKey(name: "Test", index: 0x456, key: Data(hex: "0123456789ABCDEF0123456789ABCDEF")!, boundTo: networkKey)
        
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
        let message = ConfigAppKeyAdd(parameters: Data(hex: "2361450123456789ABCDEF0123456789ABCDEF")!)
        
        XCTAssertNotNil(message)
        XCTAssertEqual(message?.networkKeyIndex, 0x123)
        XCTAssertEqual(message?.applicationKeyIndex, 0x456)
        XCTAssertEqual(message?.key, Data(hex: "0123456789ABCDEF0123456789ABCDEF")!)
    }
    
    func testEncodingConfigAppKeyList() {
        let networkKey = try! NetworkKey(name: "Test", index: 0x123, key: Data(hex: "00112233445566778899AABBCCDDEEFF")!)
        let applicationKey = try! ApplicationKey(name: "Test", index: 0x456, key: Data(hex: "0123456789ABCDEF0123456789ABCDEF")!, boundTo: networkKey)
        
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
        let message = ConfigAppKeyList(parameters: Data(hex: "0023015604")!)
        
        XCTAssertNotNil(message)
        XCTAssertEqual(message?.networkKeyIndex, 0x123)
        XCTAssertEqual(message?.applicationKeyIndexes, [0x456])
        XCTAssertEqual(message?.status, .success)
    }

}
