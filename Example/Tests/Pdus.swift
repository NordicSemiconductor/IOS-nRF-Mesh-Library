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

private struct TestStorage: Storage {
    
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
                                },
                                {
                                    "UUID": "EAA389973B4345B691494865D2885555",
                                    "name": "Low Power Node",
                                    "deviceKey": "9D6DD0E96EB25DC19A40ED9914F8F03F",
                                    "unicastAddress": "1234",
                                    "security": "high",
                                    "cid": "0007",
                                    "pid": "001A",
                                    "vid": "0003",
                                    "crpl": "0100",
                                    "features": {
                                        "relay": 0,
                                        "proxy": 0,
                                        "friend": 0,
                                        "lowPower": 1
                                    },
                                    "configComplete": true,
                                    "netKeys": [ { "index": 291, "updated": false } ],
                                    "appKeys": [ { "index": 1110, "updated": false } ],
                                    "defaultTTL": 3,
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
                                                    "modelId": "000a0000",
                                                    "subscribe": [],
                                                    "bind": [ 1110 ]
                                                }
                                            ]
                                        }
                                    ],
                                    "blacklisted": false
                                }
                            ],
                            "groups": [
                                {
                                    "name": "Virtual Group",
                                    "address": "0073E7E4D8B9440FAF8415DF4C56C0E1",
                                    "parentAddress": "0000"
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

/// There is a bug in encoding NetKeyIndex and AppKeyIndex in Bluetooth Mesh spec 1.0.1.
/// This test covers sample data #6 and #16 wich actually use messages that encode those
/// indexes, and does it correctly.
///
/// Correct encoding goes as follows:
///
/// NetKeyIndex: 0x123
///
/// AppKeyIndex: 0x456
///
/// Correct Output: 0x236145
///
/// Incorrect Output: 0x563412
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
        XCTAssertNotNil(meshNetwork.localProvisioner!.primaryUnicastAddress)
        XCTAssertEqual(meshNetwork.localProvisioner!.primaryUnicastAddress, 0x0003)
        
        XCTAssertEqual(meshNetwork.networkKeys.count, 1)
        XCTAssertEqual(meshNetwork.applicationKeys.count, 2)
        XCTAssertNotNil(meshNetwork.applicationKeys[0].meshNetwork)
        XCTAssertNotNil(meshNetwork.applicationKeys[1].meshNetwork)
        XCTAssertEqual(meshNetwork.applicationKeys[0].boundNetworkKeyIndex, meshNetwork.networkKeys[0].index)
        XCTAssertEqual(meshNetwork.applicationKeys[1].boundNetworkKeyIndex, meshNetwork.networkKeys[0].index)
        XCTAssertEqual(meshNetwork.applicationKeys[0].boundNetworkKey, meshNetwork.networkKeys[0])
        XCTAssertEqual(meshNetwork.applicationKeys[1].boundNetworkKey, meshNetwork.networkKeys[0])
        
        XCTAssertEqual(meshNetwork.nodes.count, 3)
        XCTAssertNotNil(meshNetwork.nodes[0].meshNetwork)
        XCTAssertNotNil(meshNetwork.nodes[1].meshNetwork)
    }
    
    func testSending_message_6() {
        XCTAssertNotNil(manager.meshNetwork)
        let meshNetwork = manager.meshNetwork!
        let networkKey = meshNetwork.networkKeys.first!
        let ivIndex = IvIndex(index: 0x12345678, updateActive: false)
        let source = meshNetwork.localProvisioner?.node?.elements.first?.unicastAddress
        XCTAssertNotNil(source)
        let node = meshNetwork.nodes[1]
        let destination = MeshAddress(node.primaryUnicastAddress)
        let sequence: UInt32 = 0x3129AB
        let keySet = DeviceKeySet(networkKey: networkKey, node: node)!
        
        // Test begins here
        let message = ConfigAppKeyAdd(applicationKey: meshNetwork.applicationKeys[1])
        XCTAssertEqual(message.networkKeyIndex, 0x123)
        XCTAssertEqual(message.applicationKeyIndex, 0x456)
        XCTAssertEqual(message.key, Data(hex: "63964771734FBD76E3B40519D1D94A48"))
        XCTAssertEqual(message.parameters, Data(hex: "23614563964771734FBD76E3B40519D1D94A48"))
        
        let accessPdu = AccessPdu(fromMeshMessage: message,
                                  sentFrom: source!, to: destination,
                                  userInitiated: true)
        XCTAssertEqual(accessPdu.isSegmented, true)
        XCTAssertEqual(accessPdu.destination, destination)
        XCTAssertEqual(accessPdu.opCode, ConfigAppKeyAdd.opCode)
        XCTAssertEqual(accessPdu.accessPdu, Data(hex: "0023614563964771734FBD76E3B40519D1D94A48"))
        
        let pdu = UpperTransportPdu(fromAccessPdu: accessPdu, usingKeySet: keySet,
                                    sequence: sequence, andIvIndex: ivIndex)
        XCTAssertEqual(pdu.source, source)
        XCTAssertEqual(pdu.destination, destination)
        XCTAssertEqual(pdu.sequence, sequence)
        XCTAssertNil(pdu.aid)
        XCTAssertEqual(pdu.transportMicSize, 4) // 32-bits
        XCTAssertEqual(pdu.accessPdu, Data(hex: "0023614563964771734FBD76E3B40519D1D94A48"))
        XCTAssertEqual(pdu.transportPdu, Data(hex: "EEE888AA2169326D23F3AFDFCFDC18C52FDEF7720F8AF48F"))
        
        let segment0 = SegmentedAccessMessage(fromUpperTransportPdu: pdu,
                                              usingNetworkKey: networkKey, offset: 0)
        XCTAssertNil(segment0.aid)
        XCTAssertEqual(segment0.source, source)
        XCTAssertEqual(segment0.destination, destination.address)
        XCTAssertEqual(segment0.networkKey, networkKey)
        XCTAssertEqual(segment0.sequenceZero, 0x9AB)
        XCTAssertEqual(segment0.segmentOffset, 0)
        XCTAssertEqual(segment0.lastSegmentNumber, 1)
        XCTAssertEqual(segment0.upperTransportPdu, Data(hex: "EEE888AA2169326D23F3AFDF"))
        XCTAssertEqual(segment0.transportPdu, Data(hex: "8026AC01EEE888AA2169326D23F3AFDF"))
        
        let segment1 = SegmentedAccessMessage(fromUpperTransportPdu: pdu,
                                              usingNetworkKey: networkKey, offset: 1)
        XCTAssertEqual(segment1.source, source)
        XCTAssertEqual(segment1.destination, destination.address)
        XCTAssertEqual(segment1.networkKey, networkKey)
        XCTAssertEqual(segment1.sequenceZero, 0x9AB)
        XCTAssertEqual(segment1.segmentOffset, 1)
        XCTAssertEqual(segment1.lastSegmentNumber, 1)
        XCTAssertEqual(segment1.upperTransportPdu, Data(hex: "CFDC18C52FDEF7720F8AF48F"))
        XCTAssertEqual(segment1.transportPdu, Data(hex: "8026AC21CFDC18C52FDEF7720F8AF48F"))
        
        let networkPdu0 = NetworkPdu(encode: segment0, ofType: .networkPdu,
                                     withSequence: sequence, andTtl: 4)
        XCTAssertEqual(networkPdu0.sequence, sequence)
        XCTAssertEqual(networkPdu0.source, source)
        XCTAssertEqual(networkPdu0.destination, destination.address)
        XCTAssertEqual(networkPdu0.ivi, 0)
        XCTAssertEqual(networkPdu0.nid, 0x68)
        XCTAssertEqual(networkPdu0.networkKey, networkKey)
        XCTAssertEqual(networkPdu0.pdu, Data(hex: "68CAB5C5348A230AFBA8C63D4E681631C09DEAF4FD409611459A3D6C3E"))
        
        let networkPdu1 = NetworkPdu(encode: segment1, ofType: .networkPdu,
                                     withSequence: sequence + 1, andTtl: 4)
        XCTAssertEqual(networkPdu1.sequence, sequence + 1)
        XCTAssertEqual(networkPdu1.source, source)
        XCTAssertEqual(networkPdu1.destination, destination.address)
        XCTAssertEqual(networkPdu1.ivi, 0)
        XCTAssertEqual(networkPdu1.nid, 0x68)
        XCTAssertEqual(networkPdu1.networkKey, networkKey)
        XCTAssertEqual(networkPdu1.pdu, Data(hex: "681615B5DD4A846CAE0C032BF0746F44F1B8CC8CE502AEF9D2393E5B93"))
    }
    
    func testSending_message_16() {
        XCTAssertNotNil(manager.meshNetwork)
        let meshNetwork = manager.meshNetwork!
        let networkKey = meshNetwork.networkKeys.first!
        let ivIndex = IvIndex(index: 0x12345678, updateActive: false)
        let node = meshNetwork.nodes[1]
        let source = node.elements.first?.unicastAddress
        let destination = MeshAddress(meshNetwork.localProvisioner!.primaryUnicastAddress!)
        XCTAssertNotNil(destination)
        let sequence: UInt32 = 0x000006
        let keySet = DeviceKeySet(networkKey: networkKey, node: node)!
        
        // Test begins here
        let message = ConfigAppKeyStatus(confirm: meshNetwork.applicationKeys[1])
        XCTAssertEqual(message.networkKeyIndex, 0x123)
        XCTAssertEqual(message.applicationKeyIndex, 0x456)
        XCTAssertEqual(message.status, .success)
        XCTAssertEqual(message.parameters, Data(hex: "00236145"))
        
        let accessPdu = AccessPdu(fromMeshMessage: message,
                                  sentFrom: source!, to: destination,
                                  userInitiated: true)
        XCTAssertEqual(accessPdu.isSegmented, false)
        XCTAssertEqual(accessPdu.destination, destination)
        XCTAssertEqual(accessPdu.opCode, ConfigAppKeyStatus.opCode)
        XCTAssertEqual(accessPdu.accessPdu, Data(hex: "800300236145"))
        
        let pdu = UpperTransportPdu(fromAccessPdu: accessPdu, usingKeySet: keySet,
                                    sequence: sequence, andIvIndex: ivIndex)
        XCTAssertEqual(pdu.source, source)
        XCTAssertEqual(pdu.destination, destination)
        XCTAssertEqual(pdu.sequence, sequence)
        XCTAssertNil(pdu.aid)
        XCTAssertEqual(pdu.transportMicSize, 4) // 32-bits
        XCTAssertEqual(pdu.accessPdu, Data(hex: "800300236145"))
        XCTAssertEqual(pdu.transportPdu, Data(hex: "89511B8484FF7501A689"))
        
        let segment = SegmentedAccessMessage(fromUpperTransportPdu: pdu,
                                             usingNetworkKey: networkKey, offset: 0)
        XCTAssertNil(segment.aid)
        XCTAssertEqual(segment.source, source)
        XCTAssertEqual(segment.destination, destination.address)
        XCTAssertEqual(segment.networkKey, networkKey)
        XCTAssertEqual(segment.sequenceZero, 0x006)
        XCTAssertEqual(segment.segmentOffset, 0)
        XCTAssertEqual(segment.lastSegmentNumber, 0)
        XCTAssertEqual(segment.upperTransportPdu, Data(hex: "89511B8484FF7501A689"))
        XCTAssertEqual(segment.transportPdu, Data(hex: "8000180089511B8484FF7501A689"))
        
        let networkPdu = NetworkPdu(encode: segment, ofType: .networkPdu,
                                    withSequence: sequence, andTtl: 0)
        XCTAssertEqual(networkPdu.sequence, sequence)
        XCTAssertEqual(networkPdu.source, source)
        XCTAssertEqual(networkPdu.destination, destination.address)
        XCTAssertEqual(networkPdu.ivi, 0)
        XCTAssertEqual(networkPdu.nid, 0x68)
        XCTAssertEqual(networkPdu.networkKey, networkKey)
        XCTAssertEqual(networkPdu.pdu, Data(hex: "68A878FE9CD29FC9E344863A3827BFAEE1265C9A1D334285C640A2"))
    }
    
    func testReceiving_message_6() {
        XCTAssertNotNil(manager.meshNetwork)
        let meshNetwork = manager.meshNetwork!
        let networkKey = meshNetwork.networkKeys.first!
        let ivIndex = IvIndex(index: 0x12345678, updateActive: false)
        let source = meshNetwork.localProvisioner?.primaryUnicastAddress
        let node = meshNetwork.nodes[1]
        let destination = node.primaryUnicastAddress
        let sequence: UInt32 = 0x3129AB
        
        // Test begins here
        let networkPdu0 = NetworkPdu(decode: Data(hex: "68CAB5C5348A230AFBA8C63D4E681631C09DEAF4FD409611459A3D6C3E"),
                                     ofType: .networkPdu,
                                     usingNetworkKey: networkKey, andIvIndex: ivIndex)
        XCTAssertNotNil(networkPdu0)
        XCTAssertEqual(networkPdu0?.source, source)
        XCTAssertEqual(networkPdu0?.destination, destination)
        XCTAssertEqual(networkPdu0?.type, .accessMessage)
        XCTAssertEqual(networkPdu0?.ivi, 0)
        XCTAssertEqual(networkPdu0?.nid, 0x68)
        XCTAssertEqual(networkPdu0?.networkKey, networkKey)
        XCTAssertEqual(networkPdu0?.transportPdu, Data(hex: "8026AC01EEE888AA2169326D23F3AFDF"))
        XCTAssertEqual(networkPdu0?.pdu, Data(hex: "68CAB5C5348A230AFBA8C63D4E681631C09DEAF4FD409611459A3D6C3E"))
        
        let networkPdu1 = NetworkPdu(decode: Data(hex: "681615B5DD4A846CAE0C032BF0746F44F1B8CC8CE502AEF9D2393E5B93"),
                                     ofType: .networkPdu,
                                     usingNetworkKey: networkKey, andIvIndex: ivIndex)
        XCTAssertNotNil(networkPdu1)
        XCTAssertEqual(networkPdu1?.source, source)
        XCTAssertEqual(networkPdu1?.destination, destination)
        XCTAssertEqual(networkPdu1?.type, .accessMessage)
        XCTAssertEqual(networkPdu1?.ivi, 0)
        XCTAssertEqual(networkPdu1?.nid, 0x68)
        XCTAssertEqual(networkPdu1?.networkKey, networkKey)
        XCTAssertEqual(networkPdu1?.transportPdu, Data(hex: "8026AC21CFDC18C52FDEF7720F8AF48F"))
        XCTAssertEqual(networkPdu1?.pdu, Data(hex: "681615B5DD4A846CAE0C032BF0746F44F1B8CC8CE502AEF9D2393E5B93"))
        
        let segment0 = SegmentedAccessMessage(fromSegmentPdu: networkPdu0!)
        XCTAssertNotNil(segment0)
        XCTAssertNil(segment0?.aid)
        XCTAssertEqual(segment0?.source, source)
        XCTAssertEqual(segment0?.destination, destination)
        XCTAssertEqual(segment0?.sequence, sequence)
        XCTAssertEqual(segment0?.lastSegmentNumber, 1)
        XCTAssertEqual(segment0?.sequenceZero, 0x9AB)
        XCTAssertEqual(segment0?.segmentOffset, 0)
        XCTAssertEqual(segment0?.transportMicSize, 4)
        XCTAssertEqual(segment0?.type, .accessMessage)
        XCTAssertEqual(segment0?.networkKey, networkKey)
        XCTAssertEqual(segment0?.transportPdu, Data(hex: "8026AC01EEE888AA2169326D23F3AFDF"))
        XCTAssertEqual(segment0?.upperTransportPdu, Data(hex: "EEE888AA2169326D23F3AFDF"))
        
        let segment1 = SegmentedAccessMessage(fromSegmentPdu: networkPdu1!)
        XCTAssertNotNil(segment1)
        XCTAssertNil(segment1?.aid)
        XCTAssertEqual(segment1?.source, source)
        XCTAssertEqual(segment1?.destination, destination)
        XCTAssertEqual(segment1?.sequence, sequence)
        XCTAssertEqual(segment1?.lastSegmentNumber, 1)
        XCTAssertEqual(segment1?.sequenceZero, 0x9AB)
        XCTAssertEqual(segment1?.segmentOffset, 1)
        XCTAssertEqual(segment1?.transportMicSize, 4)
        XCTAssertEqual(segment1?.type, .accessMessage)
        XCTAssertEqual(segment1?.networkKey, networkKey)
        XCTAssertEqual(segment1?.transportPdu, Data(hex: "8026AC21CFDC18C52FDEF7720F8AF48F"))
        XCTAssertEqual(segment1?.upperTransportPdu, Data(hex: "CFDC18C52FDEF7720F8AF48F"))
        
        let accessMessage = AccessMessage(fromSegments: [segment0!, segment1!])
        XCTAssertEqual(accessMessage.source, source!)
        XCTAssertEqual(accessMessage.destination, destination)
        XCTAssertEqual(accessMessage.networkKey, networkKey)
        XCTAssertEqual(accessMessage.upperTransportPdu, Data(hex: "EEE888AA2169326D23F3AFDFCFDC18C52FDEF7720F8AF48F"))
        
        let pdu = UpperTransportPdu(fromLowerTransportAccessMessage: accessMessage, usingKey: node.deviceKey!)
        XCTAssertNotNil(pdu)
        XCTAssertEqual(pdu?.source, source)
        XCTAssertEqual(pdu?.destination, MeshAddress(destination))
        XCTAssertNil(pdu?.aid)
        XCTAssertEqual(pdu?.sequence, sequence)
        XCTAssertEqual(pdu?.transportMicSize, 4)
        XCTAssertEqual(pdu?.transportPdu, Data(hex: "EEE888AA2169326D23F3AFDFCFDC18C52FDEF7720F8AF48F"))
        XCTAssertEqual(pdu?.accessPdu, Data(hex: "0023614563964771734FBD76E3B40519D1D94A48"))
        
        let accessPdu = AccessPdu(fromUpperTransportPdu: pdu!)
        XCTAssertNotNil(accessPdu)
        XCTAssertEqual(accessPdu?.opCode, ConfigAppKeyAdd.opCode)
        XCTAssertEqual(accessPdu?.parameters, Data(hex: "23614563964771734FBD76E3B40519D1D94A48"))
        XCTAssertEqual(accessPdu?.accessPdu, Data(hex: "0023614563964771734FBD76E3B40519D1D94A48"))
        
        let message = ConfigAppKeyAdd(parameters: accessPdu!.parameters)
        XCTAssertNotNil(message)
        XCTAssertEqual(message?.networkKeyIndex, 0x123)
        XCTAssertEqual(message?.applicationKeyIndex, 0x456)
        XCTAssertEqual(message?.key, Data(hex: "63964771734FBD76E3B40519D1D94A48"))
        XCTAssertEqual(message?.parameters, Data(hex: "23614563964771734FBD76E3B40519D1D94A48"))
    }

    func testSending_message_22() {
        XCTAssertNotNil(manager.meshNetwork)
        let meshNetwork = manager.meshNetwork!
        let networkKey = meshNetwork.networkKeys.first!
        let ivIndex = IvIndex(index: 0x12345677, updateActive: false)
        let node = meshNetwork.nodes[2] // Low Power Node
        let applicationKey = meshNetwork.applicationKeys[1]
        let source = node.elements.first?.unicastAddress
        let virtualGroup = meshNetwork.groups.first
        XCTAssertNotNil(virtualGroup)
        let sequence: UInt32 = 0x07080B
        let keySet = AccessKeySet(applicationKey: applicationKey)
        
        struct TestVendorMessage: StaticVendorMessage {
            static let opCode: UInt32 = 0xD50A00
            
            var parameters: Data?
            
            init?(parameters: Data) {
                self.parameters = parameters
            }
        }
        
        let message = TestVendorMessage(parameters: Data(hex: "48656C6C6F"))
        XCTAssertNotNil(message)
        
        let accessPdu = AccessPdu(fromMeshMessage: message!,
                                  sentFrom: source!, to: virtualGroup!.address,
                                  userInitiated: false)
        XCTAssertNotNil(accessPdu)
        XCTAssertEqual(accessPdu.opCode, TestVendorMessage.opCode)
        XCTAssertEqual(accessPdu.parameters, Data(hex: "48656C6C6F"))
        XCTAssertEqual(accessPdu.accessPdu, Data(hex: "D50A0048656C6C6F"))
        
        let pdu = UpperTransportPdu(fromAccessPdu: accessPdu, usingKeySet: keySet,
                                    sequence: sequence, andIvIndex: ivIndex)
        XCTAssertEqual(pdu.source, source)
        XCTAssertEqual(pdu.destination, virtualGroup!.address)
        XCTAssertEqual(pdu.sequence, sequence)
        XCTAssertEqual(pdu.aid, 0x26)
        XCTAssertEqual(pdu.transportMicSize, 4) // 32-bits
        XCTAssertEqual(pdu.accessPdu, Data(hex: "D50A0048656C6C6F"))
        XCTAssertEqual(pdu.transportPdu, Data(hex: "3871B904D431526316CA48A0"))
        
        let segment = AccessMessage(fromUnsegmentedUpperTransportPdu: pdu,
                                    usingNetworkKey: networkKey)
        XCTAssertEqual(pdu.aid, 0x26)
        XCTAssertEqual(segment.source, source)
        XCTAssertEqual(segment.destination, virtualGroup?.address.address)
        XCTAssertEqual(segment.networkKey, networkKey)
        XCTAssertEqual(segment.upperTransportPdu, Data(hex: "3871B904D431526316CA48A0"))
        XCTAssertEqual(segment.transportPdu, Data(hex: "663871B904D431526316CA48A0"))
        
        let networkPdu = NetworkPdu(encode: segment, ofType: .networkPdu,
                                    withSequence: sequence, andTtl: 3)
        XCTAssertEqual(networkPdu.sequence, sequence)
        XCTAssertEqual(networkPdu.source, source)
        XCTAssertEqual(networkPdu.destination, virtualGroup?.address.address)
        XCTAssertEqual(networkPdu.ivi, 1)
        XCTAssertEqual(networkPdu.nid, 0x68)
        XCTAssertEqual(networkPdu.networkKey, networkKey)
        XCTAssertEqual(networkPdu.pdu, Data(hex: "E8D85CAECEF1E3ED31F3FDCF88A411135FEA55DF730B6B28E255"))
    }
}
