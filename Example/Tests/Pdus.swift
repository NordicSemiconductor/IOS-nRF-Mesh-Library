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
    
    func testSending() {
        XCTAssertNotNil(manager.meshNetwork)
        let meshNetwork = manager.meshNetwork!
        let networkKey = meshNetwork.networkKeys.first!
        networkKey.ivIndex = IvIndex(index: 0x12345678, updateActive: false)
        let source = meshNetwork.localProvisioner?.unicastAddress
        XCTAssertNotNil(source)
        let node = meshNetwork.nodes[1]
        let destination = node.unicastAddress
        let sequence: UInt32 = 0x3129AB
        
        // Test begins here
        let message = ConfigAppKeyAdd(applicationKey: meshNetwork.applicationKeys[1])
        XCTAssertEqual(message.opCode, 0)
        XCTAssertEqual(message.applicationKey, meshNetwork.applicationKeys[1])
        XCTAssertEqual(message.parameters, Data(hex: "56341263964771734FBD76E3B40519D1D94A48"))
        XCTAssertEqual(message.accessPdu, Data(hex: "0056341263964771734FBD76E3B40519D1D94A48"))
        
        let pdu = UpperTransportPdu(fromConfigMessage: message,
                                    sentFrom: source!, to: destination,
                                    usingDeviceKey: node.deviceKey, sequence: sequence, andIvIndex: networkKey.ivIndex)
        XCTAssertEqual(pdu.source, source)
        XCTAssertEqual(pdu.destination, destination)
        XCTAssertEqual(pdu.sequence, sequence)
        XCTAssertNil(pdu.aid)
        XCTAssertEqual(pdu.transportMicSize, 4)
        XCTAssertEqual(pdu.accessPdu, Data(hex: "0056341263964771734FBD76E3B40519D1D94A48"))
        XCTAssertEqual(pdu.transportPdu, Data(hex: "EE9DDDFD2169326D23F3AFDFCFDC18C52FDEF772E0E17308"))
        
        let segment0 = SegmentedAccessMessage(fromUpperTransportPdu: pdu, usingNetworkKey: networkKey, offset: 0)
        XCTAssertNil(segment0.aid)
        XCTAssertEqual(segment0.source, source)
        XCTAssertEqual(segment0.destination, destination)
        XCTAssertEqual(segment0.networkKey, networkKey)
        XCTAssertEqual(segment0.segmentZero, 0x9AB)
        XCTAssertEqual(segment0.segmentOffset, 0)
        XCTAssertEqual(segment0.lastSegmentNumber, 1)
        XCTAssertEqual(segment0.upperTransportPdu, Data(hex: "EE9DDDFD2169326D23F3AFDF"))
        XCTAssertEqual(segment0.transportPdu, Data(hex: "8026AC01EE9DDDFD2169326D23F3AFDF"))
        
        let segment1 = SegmentedAccessMessage(fromUpperTransportPdu: pdu, usingNetworkKey: networkKey, offset: 1)
        XCTAssertEqual(segment1.source, source)
        XCTAssertEqual(segment1.destination, destination)
        XCTAssertEqual(segment1.networkKey, networkKey)
        XCTAssertEqual(segment1.segmentZero, 0x9AB)
        XCTAssertEqual(segment1.segmentOffset, 1)
        XCTAssertEqual(segment1.lastSegmentNumber, 1)
        XCTAssertEqual(segment1.upperTransportPdu, Data(hex: "CFDC18C52FDEF772E0E17308"))
        XCTAssertEqual(segment1.transportPdu, Data(hex: "8026AC21CFDC18C52FDEF772E0E17308"))
        
        let networkPdu0 = NetworkPdu(encode: segment0, withSequence: sequence, andTtl: 4)
        XCTAssertEqual(networkPdu0.sequence, sequence)
        XCTAssertEqual(networkPdu0.source, source)
        XCTAssertEqual(networkPdu0.destination, destination)
        XCTAssertEqual(networkPdu0.ivi, 0)
        XCTAssertEqual(networkPdu0.nid, 0x68)
        XCTAssertEqual(networkPdu0.networkKey, networkKey)
        XCTAssertEqual(networkPdu0.pdu, Data(hex: "68CAB5C5348A230AFBA8C63D4E686364979DEAF4FD40961145939CDA0E"))
        
        let networkPdu1 = NetworkPdu(encode: segment1, withSequence: sequence + 1, andTtl: 4)
        XCTAssertEqual(networkPdu1.sequence, sequence + 1)
        XCTAssertEqual(networkPdu1.source, source)
        XCTAssertEqual(networkPdu1.destination, destination)
        XCTAssertEqual(networkPdu1.ivi, 0)
        XCTAssertEqual(networkPdu1.nid, 0x68)
        XCTAssertEqual(networkPdu1.networkKey, networkKey)
        XCTAssertEqual(networkPdu1.pdu, Data(hex: "681615B5DD4A846CAE0C032BF0746F44F1B8CC8CE5EDC57E55BEED49C0"))
    }
    
    func testReceiving() {
        XCTAssertNotNil(manager.meshNetwork)
        let meshNetwork = manager.meshNetwork!
        let networkKey = meshNetwork.networkKeys.first!
        networkKey.ivIndex = IvIndex(index: 0x12345678, updateActive: false)
        let source = meshNetwork.localProvisioner?.unicastAddress
        let node = meshNetwork.nodes[1]
        let destination = node.unicastAddress
        let sequence: UInt32 = 0x3129AB
        
        // Test begins here
        let networkPdu0 = NetworkPdu(decode: Data(hex: "68CAB5C5348A230AFBA8C63D4E686364979DEAF4FD40961145939CDA0E")!,
                                     usingNetworkKey: networkKey)
        XCTAssertNotNil(networkPdu0)
        XCTAssertEqual(networkPdu0?.source, source)
        XCTAssertEqual(networkPdu0?.destination, destination)
        XCTAssertEqual(networkPdu0?.type, .accessMessage)
        XCTAssertEqual(networkPdu0?.ivi, 0)
        XCTAssertEqual(networkPdu0?.nid, 0x68)
        XCTAssertEqual(networkPdu0?.networkKey, networkKey)
        XCTAssertEqual(networkPdu0?.transportPdu, Data(hex: "8026AC01EE9DDDFD2169326D23F3AFDF"))
        XCTAssertEqual(networkPdu0?.pdu, Data(hex: "68CAB5C5348A230AFBA8C63D4E686364979DEAF4FD40961145939CDA0E"))
        
        let networkPdu1 = NetworkPdu(decode: Data(hex: "681615B5DD4A846CAE0C032BF0746F44F1B8CC8CE5EDC57E55BEED49C0")!,
                                     usingNetworkKey: networkKey)
        XCTAssertNotNil(networkPdu1)
        XCTAssertEqual(networkPdu1?.source, source)
        XCTAssertEqual(networkPdu1?.destination, destination)
        XCTAssertEqual(networkPdu1?.type, .accessMessage)
        XCTAssertEqual(networkPdu1?.ivi, 0)
        XCTAssertEqual(networkPdu1?.nid, 0x68)
        XCTAssertEqual(networkPdu1?.networkKey, networkKey)
        XCTAssertEqual(networkPdu1?.transportPdu, Data(hex: "8026AC21CFDC18C52FDEF772E0E17308"))
        XCTAssertEqual(networkPdu1?.pdu, Data(hex: "681615B5DD4A846CAE0C032BF0746F44F1B8CC8CE5EDC57E55BEED49C0"))
        
        let segment0 = SegmentedAccessMessage(fromSegmentPdu: networkPdu0!)
        XCTAssertNotNil(segment0)
        XCTAssertNil(segment0?.aid)
        XCTAssertEqual(segment0?.source, source)
        XCTAssertEqual(segment0?.destination, destination)
        XCTAssertEqual(segment0?.sequence, sequence)
        XCTAssertEqual(segment0?.lastSegmentNumber, 1)
        XCTAssertEqual(segment0?.segmentZero, 0x9AB)
        XCTAssertEqual(segment0?.segmentOffset, 0)
        XCTAssertEqual(segment0?.transportMicSize, 4)
        XCTAssertEqual(segment0?.type, .accessMessage)
        XCTAssertEqual(segment0?.networkKey, networkKey)
        XCTAssertEqual(segment0?.transportPdu, Data(hex: "8026AC01EE9DDDFD2169326D23F3AFDF"))
        XCTAssertEqual(segment0?.upperTransportPdu, Data(hex: "EE9DDDFD2169326D23F3AFDF"))
        
        let segment1 = SegmentedAccessMessage(fromSegmentPdu: networkPdu1!)
        XCTAssertNotNil(segment1)
        XCTAssertNil(segment1?.aid)
        XCTAssertEqual(segment1?.source, source)
        XCTAssertEqual(segment1?.destination, destination)
        XCTAssertEqual(segment1?.sequence, sequence)
        XCTAssertEqual(segment1?.lastSegmentNumber, 1)
        XCTAssertEqual(segment1?.segmentZero, 0x9AB)
        XCTAssertEqual(segment1?.segmentOffset, 1)
        XCTAssertEqual(segment1?.transportMicSize, 4)
        XCTAssertEqual(segment1?.type, .accessMessage)
        XCTAssertEqual(segment1?.networkKey, networkKey)
        XCTAssertEqual(segment1?.transportPdu, Data(hex: "8026AC21CFDC18C52FDEF772E0E17308"))
        XCTAssertEqual(segment1?.upperTransportPdu, Data(hex: "CFDC18C52FDEF772E0E17308"))
        
        let accessMessage = AccessMessage(fromSegments: [segment0!, segment1!])
        XCTAssertEqual(accessMessage.source, source!)
        XCTAssertEqual(accessMessage.destination, destination)
        XCTAssertEqual(accessMessage.networkKey, networkKey)
        XCTAssertEqual(accessMessage.upperTransportPdu, Data(hex: "EE9DDDFD2169326D23F3AFDFCFDC18C52FDEF772E0E17308"))
        
        let pdu = UpperTransportPdu(fromLowerTransportAccessMessage: accessMessage, usingKey: node.deviceKey)
        XCTAssertNotNil(pdu)
        XCTAssertEqual(pdu?.source, source)
        XCTAssertEqual(pdu?.destination, destination)
        XCTAssertNil(pdu?.aid)
        XCTAssertEqual(pdu?.sequence, sequence)
        XCTAssertEqual(pdu?.transportMicSize, 4)
        XCTAssertEqual(pdu?.transportPdu, Data(hex: "EE9DDDFD2169326D23F3AFDFCFDC18C52FDEF772E0E17308"))
        XCTAssertEqual(pdu?.accessPdu, Data(hex: "0056341263964771734FBD76E3B40519D1D94A48"))
    }

}
