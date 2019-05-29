//
//  NetworkPdus.swift
//  nRFMeshProvision_Tests
//
//  Created by Aleksander Nowakowski on 27/05/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import nRFMeshProvision

class NetworkPdus: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testEncodingControlMessage() {
        let networkKey = try! NetworkKey(name: "Test Key", index: 0, key: Data(hex: "7dd7364cd842ad18c17c2b820c84c3d6")!)
        let ivIndex = IvIndex()
        ivIndex.index = 0x12345678
        ivIndex.updateActive = false
        
        let networkPdu = NetworkPdu(encode: Data(hex: "034b50057e400000010000")!, ofType: .controlMessage,
                                    sentFrom: 0x1201, to: 0xFFFD, usingNetworkKey: networkKey, sequence: 1, ttl: 0, andIvIndex: ivIndex)
        let data = Data(hex: "68eca487516765b5e5bfdacbaf6cb7fb6bff871f035444ce83a670df")!
        XCTAssertEqual(networkPdu.pdu, data)
    }
    
    func testEncodingAccessMessage() {
        let networkKey = try! NetworkKey(name: "Test Key", index: 0, key: Data(hex: "7dd7364cd842ad18c17c2b820c84c3d6")!)
        let ivIndex = IvIndex()
        ivIndex.index = 0x12345678
        ivIndex.updateActive = false
        
        let networkPdu = NetworkPdu(encode: Data(hex: "8026ac01ee9dddfd2169326d23f3afdf")!, ofType: .accessMessage,
                                    sentFrom: 0x0003, to: 0x1201, usingNetworkKey: networkKey, sequence: 0x3129AB, ttl: 4, andIvIndex: ivIndex)
        let data = Data(hex: "68cab5c5348a230afba8c63d4e686364979deaf4fd40961145939cda0e")!
        XCTAssertEqual(networkPdu.pdu, data)
    }

    func testDecodingControlMessage() {
        let networkKey = try! NetworkKey(name: "Test Key", index: 0, key: Data(hex: "7dd7364cd842ad18c17c2b820c84c3d6")!)
        let ivIndex = IvIndex()
        ivIndex.index = 0x12345678
        ivIndex.updateActive = false
        
        let data = Data(hex: "68eca487516765b5e5bfdacbaf6cb7fb6bff871f035444ce83a670df")!
        
        let networkPdu = NetworkPdu(decode: data, usingNetworkKey: networkKey, andIvIndex: ivIndex)
        XCTAssertNotNil(networkPdu)
        XCTAssertEqual(networkPdu!.ivi, 0x0)
        XCTAssertEqual(networkPdu!.nid, 0x68)
        XCTAssertEqual(networkPdu!.type, .controlMessage)
        XCTAssertEqual(networkPdu!.ttl, 0)
        XCTAssertEqual(networkPdu!.sequence, 1)
        XCTAssertEqual(networkPdu!.source, 0x1201)
        XCTAssertEqual(networkPdu!.destination, 0xFFFD)
        XCTAssertEqual(networkPdu!.transportPdu, Data(hex: "034b50057e400000010000")!)
    }
    
    func testDecodingControlMessageUsingOldKey() {
        let networkKey = try! NetworkKey(name: "Test Key", index: 0, key: Data(hex: "7dd7364cd842ad18c17c2b820c84c3d6")!)
        networkKey.key = Data(hex: "7d01D01D01D01D01D01D01D01D01D01D")!
        let ivIndex = IvIndex()
        ivIndex.index = 0x12345678
        ivIndex.updateActive = false
        
        let data = Data(hex: "68eca487516765b5e5bfdacbaf6cb7fb6bff871f035444ce83a670df")!
        
        let networkPdu = NetworkPdu(decode: data, usingNetworkKey: networkKey, andIvIndex: ivIndex)
        XCTAssertNotNil(networkPdu)
        XCTAssertEqual(networkPdu!.ivi, 0x0)
        XCTAssertEqual(networkPdu!.nid, 0x68)
        XCTAssertEqual(networkPdu!.type, .controlMessage)
        XCTAssertEqual(networkPdu!.ttl, 0)
        XCTAssertEqual(networkPdu!.sequence, 1)
        XCTAssertEqual(networkPdu!.source, 0x1201)
        XCTAssertEqual(networkPdu!.destination, 0xFFFD)
        XCTAssertEqual(networkPdu!.transportPdu, Data(hex: "034b50057e400000010000")!)
    }
    
    func testDecodingControlMessageWithNextIvIndex() {
        let networkKey = try! NetworkKey(name: "Test Key", index: 0, key: Data(hex: "7dd7364cd842ad18c17c2b820c84c3d6")!)
        let ivIndex = IvIndex()
        ivIndex.index = 0x12345679
        ivIndex.updateActive = true
        
        let data = Data(hex: "68eca487516765b5e5bfdacbaf6cb7fb6bff871f035444ce83a670df")!
        
        let networkPdu = NetworkPdu(decode: data, usingNetworkKey: networkKey, andIvIndex: ivIndex)
        XCTAssertNotNil(networkPdu)
        XCTAssertEqual(networkPdu!.ivi, 0x0)
        XCTAssertEqual(networkPdu!.nid, 0x68)
        XCTAssertEqual(networkPdu!.type, .controlMessage)
        XCTAssertEqual(networkPdu!.sequence, 1)
        XCTAssertEqual(networkPdu!.source, 0x1201)
        XCTAssertEqual(networkPdu!.destination, 0xFFFD)
        XCTAssertEqual(networkPdu!.transportPdu, Data(hex: "034b50057e400000010000")!)
    }
    
    func testDecodingControlMessageWithWrongIvIndex() {
        let networkKey = try! NetworkKey(name: "Test Key", index: 0, key: Data(hex: "7dd7364cd842ad18c17c2b820c84c3d6")!)
        let ivIndex = IvIndex()
        ivIndex.index = 0x12345679
        ivIndex.updateActive = false
        
        let data = Data(hex: "68eca487516765b5e5bfdacbaf6cb7fb6bff871f035444ce83a670df")!
        
        let networkPdu = NetworkPdu(decode: data, usingNetworkKey: networkKey, andIvIndex: ivIndex)
        XCTAssertNil(networkPdu)
    }
    
    func testDecodingControlMessageWithWrongKey() {
        let networkKey = try! NetworkKey(name: "Other Key", index: 0, key: Data(hex: "8dd7364cd842ad18c17c2b820c84c3d6")!)
        let ivIndex = IvIndex()
        ivIndex.index = 0x12345678
        ivIndex.updateActive = false
        
        let data = Data(hex: "68eca487516765b5e5bfdacbaf6cb7fb6bff871f035444ce83a670df")!
        
        let networkPdu = NetworkPdu(decode: data, usingNetworkKey: networkKey, andIvIndex: ivIndex)
        XCTAssertNil(networkPdu)
    }
    
    func testDecodingControlMessageWithWrongKey2() {
        let networkKey = try! NetworkKey(name: "Test Key", index: 0, key: Data(hex: "7dd7364cd842ad18c17c2b820c84c3d6")!)
        let ivIndex = IvIndex()
        ivIndex.index = 0x12345678
        ivIndex.updateActive = false
        
        let otherData = Data(hex: "68eca487516765b5e5bfdacbaf6cb7fb7bff871f035444ce83a670df")!
        
        let networkPdu = NetworkPdu(decode: otherData, usingNetworkKey: networkKey, andIvIndex: ivIndex)
        XCTAssertNil(networkPdu)
    }
    
    func testDecodingControlMessageWithWrongNid() {
        let networkKey = try! NetworkKey(name: "Test Key", index: 0, key: Data(hex: "7dd7364cd842ad18c17c2b820c84c3d6")!)
        let ivIndex = IvIndex()
        ivIndex.index = 0x12345678
        ivIndex.updateActive = false
        
        let data = Data(hex: "69eca487516765b5e5bfdacbaf6cb7fb6bff871f035444ce83a670df")!
        
        let networkPdu = NetworkPdu(decode: data, usingNetworkKey: networkKey, andIvIndex: ivIndex)
        XCTAssertNil(networkPdu)
    }

}
