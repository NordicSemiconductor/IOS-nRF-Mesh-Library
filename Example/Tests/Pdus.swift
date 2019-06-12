//
//  Pdus.swift
//  nRFMeshProvision_Tests
//
//  Created by Aleksander Nowakowski on 12/06/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import nRFMeshProvision

struct TestStorage: Storage {
    
    func load() -> Data? {
        return #"""
                {
                    "meshNetwork":
                        {
                            "$schema": "http://json-schema.org/draft-04/schema#",
                            "id": "http://www.bluetooth.com/specifications/assigned-numbers/mesh-profile/cdb-schema.json#",
                            "version": "1.0.0",
                            "meshUUID": "72C6BE40444D2081BEAADDAD4E3CC21C",
                            "meshName": "Brian and Mary's House",
                            "timestamp": "2018-12-23T11:45:22-08:00",
                            "netKeys": [
                                {
                                    "name": "Home Network",
                                    "index": 291,
                                    "key": "7dd7364cd842ad18c17c2b820c84c3d6",
                                    "phase": 0,
                                    "minSecurity": "high",
                                    "timestamp": "2018-11-20T10:05:20-08:00"
                                }
                            ],
                            "appKeys": [
                                {
                                    "name": "Primary App Key",
                                    "index": 0,
                                    "boundNetKey": 291,
                                    "key": "3FA985DA6D4CA22DA05C7E7A1F11C783"
                                },
                                {
                                    "name": "Home Automation",
                                    "index": 1110,
                                    "boundNetKey": 291,
                                    "key": "63964771734fbd76e3b40519d1d94a48"
                                }
                            ],
                            "provisioners": [
                                {
                                    "provisionerName": "Brian's Phone",
                                    "UUID": "70CF7C9732A345B691494810D2E9CBF4",
                                    "allocatedGroupRange": [
                                        {"lowAddress": "C000", "highAddress": "FEFF"}
                                    ],
                                    "allocatedUnicastRange": [
                                        {"lowAddress": "0001", "highAddress": "7FFF"}
                                    ],
                                    "allocatedSceneRange": []
                                }
                            ],
                            "nodes": [
                                {
                                    "UUID": "70CF7C9732A345B691494810D2E9CBF4",
                                    "name": "Brian’s phone",
                                    "cid": "0008",
                                    "pid": "032B",
                                    "vid": "0005",
                                    "crpl": "0100",
                                    "features": {
                                        "relay": 0,
                                        "proxy": 0,
                                        "friend": 0,
                                        "lowPower": 2
                                    },
                                    "deviceKey": "27653BFE0EEEA5ECBBA68975DD0A0244",
                                    "unicastAddress": "0003",
                                    "security": "high",
                                    "configComplete": true,
                                    "netKeys": [
                                           { "index": 291, "updated": false }
                                    ],
                                    "appKeys": [
                                           { "index": 1110, "updated": false }
                                    ],
                                    "elements": [
                                        {
                                            "index": 0,
                                            "location": "0000",
                                            "models": [
                                                {
                                                    "modelId": "0000",
                                                    "subscribe": [],
                                                    "bind": []
                                                },
                                                {
                                                    "modelId": "0002",
                                                    "subscribe": [],
                                                    "bind": []
                                                },
                                                {
                                                    "modelId": "0001",
                                                    "subscribe": [],
                                                    "bind": []
                                                }
                                            ]
                                        }
                                    ],
                                    "blacklisted": false
                                },
                                {
                                    "UUID": "EAA389973B4345B691494865D2885555",
                                    "name": "Bell",
                                    "deviceKey": "9D6DD0E96EB25DC19A40ED9914F8F03F",
                                    "unicastAddress": "1201",
                                    "security": "high",
                                    "cid": "0007",
                                    "pid": "001A",
                                    "vid": "0003",
                                    "crpl": "0100",
                                    "features": {
                                        "relay": 0,
                                        "proxy": 1,
                                        "friend": 0,
                                        "lowPower": 2
                                    },
                                    "configComplete": true,
                                    "netKeys": [ { "index": 291, "updated": false } ],
                                    "appKeys": [],
                                    "defaultTTL": 9,
                                    "elements": [
                                        {
                                            "index": 0,
                                            "location": "010C",
                                            "models": [
                                                {
                                                    "modelId": "0000",
                                                    "subscribe": [],
                                                    "bind": []
                                                },
                                                {
                                                    "modelId": "0002",
                                                    "subscribe": [],
                                                    "bind": []
                                                },
                                                {
                                                    "modelId": "1000",
                                                    "subscribe": [],
                                                    "bind": []
                                                }
                                            ]
                                        }
                                    ],
                                    "blacklisted": false
                                }
                            ]
                        }
                }
                """#.data(using: .utf8)
    }
    
    func save(_ data: Data) -> Bool {
        return true
    }
    
}

class Pdus: XCTestCase {
    var manager: MeshNetworkManager!

    override func setUp() {
        manager = MeshNetworkManager(using: TestStorage())
        do {
            if !(try manager.load()) {
                print("Loading JSON failed")
            }
        } catch {
            print(error)
        }
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testLoadingManager() {
        XCTAssertNotNil(manager)
        XCTAssertNotNil(manager.meshNetwork)
        
        let meshNetwork = manager.meshNetwork!
        
        XCTAssertNotNil(meshNetwork.localProvisioner)
        XCTAssertNotNil(meshNetwork.localProvisioner!.meshNetwork)
        XCTAssertNotNil(meshNetwork.localProvisioner!.unicastAddress)
        XCTAssertEqual(meshNetwork.localProvisioner!.unicastAddress, 0x0003)
        
        XCTAssertEqual(meshNetwork.networkKeys.count, 1)
        XCTAssertEqual(meshNetwork.applicationKeys.count, 2)
        XCTAssertNotNil(meshNetwork.applicationKeys[0].meshNetwork)
        XCTAssertNotNil(meshNetwork.applicationKeys[1].meshNetwork)
        XCTAssertEqual(meshNetwork.applicationKeys[0].boundNetworkKeyIndex, meshNetwork.networkKeys[0].index)
        XCTAssertEqual(meshNetwork.applicationKeys[1].boundNetworkKeyIndex, meshNetwork.networkKeys[0].index)
        XCTAssertEqual(meshNetwork.applicationKeys[0].boundNetworkKey, meshNetwork.networkKeys[0])
        XCTAssertEqual(meshNetwork.applicationKeys[1].boundNetworkKey, meshNetwork.networkKeys[0])
        
        XCTAssertEqual(meshNetwork.nodes.count, 2)
        XCTAssertNotNil(meshNetwork.nodes[0].meshNetwork)
        XCTAssertNotNil(meshNetwork.nodes[1].meshNetwork)
    }

    func testConfigAppKeyAddMessage() {
        XCTAssertNotNil(manager.meshNetwork)
        let meshNetwork = manager.meshNetwork!
        let message = ConfigAppKeyAdd(applicationKey: meshNetwork.applicationKeys[1])
        XCTAssertEqual(message.opCode, 0)
        XCTAssertEqual(message.applicationKey, meshNetwork.applicationKeys[1])
        XCTAssertEqual(message.parameters, Data(hex: "56341263964771734FBD76E3B40519D1D94A48"))
        XCTAssertEqual(message.accessPdu, Data(hex: "0056341263964771734FBD76E3B40519D1D94A48"))
    }
    
    func testUpperTransportPdu() {
        XCTAssertNotNil(manager.meshNetwork)
        let meshNetwork = manager.meshNetwork!
        XCTAssertNotNil(meshNetwork.networkKeys.first)
        let networkKey = meshNetwork.networkKeys.first!
        networkKey.ivIndex = IvIndex(index: 0x12345678, updateActive: false)
        
        let message = ConfigAppKeyAdd(applicationKey: meshNetwork.applicationKeys[1])
        
        let source = meshNetwork.localProvisioner?.unicastAddress
        XCTAssertNotNil(source)
        XCTAssertEqual(source!, 0x0003)
        
        XCTAssert(meshNetwork.nodes.count > 1)
        let node = meshNetwork.nodes[1]
        let destination = node.unicastAddress
        XCTAssertEqual(destination, 0x1201)
        
        let sequence: UInt32 = 0x3129AB
        
        let pdu = UpperTransportPdu(fromConfigMessage: message,
                                    sentFrom: source!, to: destination,
                                    usingDeviceKey: node.deviceKey, sequence: sequence, andIvIndex: networkKey.ivIndex)
        XCTAssertEqual(pdu.source, source!)
        XCTAssertEqual(pdu.destination, destination)
        XCTAssertEqual(pdu.sequence, sequence)
        XCTAssertNil(pdu.aid)
        XCTAssertEqual(pdu.transportMicSize, 4)
        XCTAssertEqual(pdu.accessPdu, Data(hex: "0056341263964771734FBD76E3B40519D1D94A48"))
        XCTAssertEqual(pdu.transportPdu, Data(hex: "EE9DDDFD2169326D23F3AFDFCFDC18C52FDEF772E0E17308"))
    }

}
