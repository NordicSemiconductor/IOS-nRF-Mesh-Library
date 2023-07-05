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
import os.log
@testable import nRFMeshProvision

private struct TestStorage: Storage {
    
    func load() -> Data? {
        return #"""
                {
                    "meshNetwork":
                        {
                            "id": "http://www.bluetooth.com/specifications/assigned-numbers/mesh-profile/cdb-schema.json#",
                            "scenes": [
                                {
                                    "scene": "0001",
                                    "name": "Sunrise",
                                    "addresses": []
                                },
                                {
                                    "scene": "0002",
                                    "name": "Party",
                                    "addresses": []
                                },
                                {
                                    "scene": "0003",
                                    "name": "Evening",
                                    "addresses": []
                                }
                            ],
                            "version": "1.0.0",
                            "nodes": [
                                {
                                    "secureNetworkBeacon": false,
                                    "features": {
                                        "proxy": 2,
                                        "friend": 2,
                                        "relay": 2,
                                        "lowPower": 2
                                    },
                                    "unicastAddress": "0001",
                                    "elements": [
                                        {
                                            "models": [
                                                {
                                                    "modelId": "0000",
                                                    "subscribe": [],
                                                    "bind": []
                                                },
                                                {
                                                    "modelId": "0001",
                                                    "subscribe": [],
                                                    "bind": []
                                                },
                                                {
                                                    "modelId": "0002",
                                                    "subscribe": [],
                                                    "bind": []
                                                },
                                                {
                                                    "modelId": "0003",
                                                    "subscribe": [],
                                                    "bind": []
                                                },
                                                {
                                                    "modelId": "1205",
                                                    "subscribe": [],
                                                    "bind": []
                                                },
                                                {
                                                    "modelId": "1203",
                                                    "subscribe": [
                                                        "C000"
                                                    ],
                                                    "bind": [
                                                        1
                                                    ]
                                                },
                                                {
                                                    "modelId": "1204",
                                                    "subscribe": [
                                                        "C000"
                                                    ],
                                                    "bind": [
                                                        1
                                                    ]
                                                },
                                                {
                                                    "modelId": "1004",
                                                    "subscribe": [],
                                                    "bind": [
                                                        0
                                                    ]
                                                },
                                                {
                                                    "modelId": "1005",
                                                    "subscribe": [],
                                                    "bind": []
                                                },
                                                {
                                                    "modelId": "1000",
                                                    "subscribe": [
                                                        "C000"
                                                    ],
                                                    "bind": [
                                                        0
                                                    ]
                                                },
                                                {
                                                    "modelId": "1002",
                                                    "subscribe": [],
                                                    "bind": []
                                                },
                                                {
                                                    "publish": {
                                                        "index": 0,
                                                        "credentials": 0,
                                                        "ttl": 255,
                                                        "retransmit": {
                                                            "count": 0,
                                                            "interval": 50
                                                        },
                                                        "period": 0,
                                                        "address": "C000"
                                                    },
                                                    "modelId": "1001",
                                                    "subscribe": [],
                                                    "bind": [
                                                        0
                                                    ]
                                                },
                                                {
                                                    "modelId": "1003",
                                                    "subscribe": [],
                                                    "bind": []
                                                },
                                                {
                                                    "modelId": "00590001",
                                                    "subscribe": [],
                                                    "bind": []
                                                }
                                            ],
                                            "name": "Primary Element",
                                            "location": "0001",
                                            "index": 0
                                        },
                                        {
                                            "models": [
                                                {
                                                    "modelId": "1000",
                                                    "subscribe": [
                                                        "C000"
                                                    ],
                                                    "bind": [
                                                        0
                                                    ]
                                                },
                                                {
                                                    "modelId": "1002",
                                                    "subscribe": [],
                                                    "bind": [
                                                        0
                                                    ]
                                                },
                                                {
                                                    "modelId": "1001",
                                                    "subscribe": [],
                                                    "bind": []
                                                },
                                                {
                                                    "modelId": "1003",
                                                    "subscribe": [],
                                                    "bind": []
                                                }
                                            ],
                                            "name": "Secondary Element",
                                            "location": "0002",
                                            "index": 1
                                        }
                                    ],
                                    "configComplete": true,
                                    "netKeys": [
                                        {
                                            "index": 0,
                                            "updated": false
                                        },
                                        {
                                            "index": 1,
                                            "updated": false
                                        }
                                    ],
                                    "networkTransmit": {
                                        "count": 1,
                                        "interval": 10
                                    },
                                    "defaultTTL": 5,
                                    "cid": "004C",
                                    "appKeys": [
                                        {
                                            "index": 0,
                                            "updated": false
                                        },
                                        {
                                            "index": 1,
                                            "updated": false
                                        },
                                        {
                                            "index": 2,
                                            "updated": false
                                        }
                                    ],
                                    "blacklisted": false,
                                    "UUID": "B606812A9F97468DA47A5C9DB8FBD0D0",
                                    "security": "high",
                                    "crpl": "7FFF",
                                    "name": "MAG iPhone 11",
                                    "deviceKey": "A096C08136FE53F032D8C4D072610F1F"
                                }
                            ],
                            "meshUUID": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
                            "netKeys": [
                                {
                                    "phase": 0,
                                    "minSecurity": "high",
                                    "key": "1980815AD267AFE9EAF904437612A6E4",
                                    "timestamp": "2020-08-14T08:59:18Z",
                                    "name": "Primary Network Key",
                                    "index": 0
                                },
                                {
                                    "phase": 0,
                                    "minSecurity": "high",
                                    "key": "1701C1D0F7589F0B3FFD8D4D2622AEA3",
                                    "timestamp": "2020-08-18T12:54:56Z",
                                    "name": "Secondary Network Key",
                                    "index": 1
                                }
                            ],
                            "timestamp": "2020-09-16T07:41:23Z",
                            "appKeys": [
                                {
                                    "key": "0B67D9F4898C3A50D0F6542D78C1ED5B",
                                    "name": "Switches",
                                    "boundNetKey": 0,
                                    "index": 0
                                },
                                {
                                    "key": "7EEA82F899395AC251666D432D0E6FC1",
                                    "name": "Scenes",
                                    "boundNetKey": 0,
                                    "index": 1
                                },
                                {
                                    "key": "DCE33B437A6474EB102A756E32B3C6A7",
                                    "name": "Test App Key",
                                    "boundNetKey": 0,
                                    "index": 2
                                }
                            ],
                            "meshName": "Test Network",
                            "provisioners": [
                                {
                                    "allocatedGroupRange": [
                                        {
                                            "lowAddress": "C000",
                                            "highAddress": "CC9A"
                                        }
                                    ],
                                    "allocatedUnicastRange": [
                                        {
                                            "lowAddress": "0001",
                                            "highAddress": "199A"
                                        }
                                    ],
                                    "UUID": "B606812A9F97468DA47A5C9DB8FBD0D0",
                                    "provisionerName": "MAG iPhone 11",
                                    "allocatedSceneRange": [
                                        {
                                            "lastScene": "0004",
                                            "firstScene": "0001"
                                        },
                                        {
                                            "lastScene": "00AA",
                                            "firstScene": "0009"
                                        }
                                    ]
                                }
                            ],
                            "groups": [
                                {
                                    "name": "Kitchen",
                                    "address": "C000",
                                    "parentAddress": "0000"
                                },
                                {
                                    "name": "Virtual Group",
                                    "address": "89F7DDCE164E48E68CFF4C9AA6254187",
                                    "parentAddress": "0000"
                                }
                            ],
                            "$schema": "http://json-schema.org/draft-04/schema#"
                    }
                }
                """#.data(using: .utf8)
    }
    
    func save(_ data: Data) -> Bool {
        return true
    }
    
}

class DummyTransmitter: Transmitter {
    
    func send(_ data: Data, ofType type: PduType) throws {
        // Ignore
    }
    
}

class FastSending: XCTestCase, MeshNetworkDelegate {
    var manager: MeshNetworkManager!
    
    var statusSent: XCTestExpectation!
    var statusReceived: XCTestExpectation!
    var messageSent: XCTestExpectation!
    var keyBound: XCTestExpectation!

    override func setUp() {
        manager = MeshNetworkManager(using: TestStorage())
        do {
            if !(try manager.load()) {
                print("Loading JSON failed")
            }
            if let network = manager.meshNetwork,
               let defaults = UserDefaults(suiteName: network.uuid.uuidString) {
                defaults.removeSequenceNumber(for: Address(0001))
                defaults.removeSeqAuthValues(of: Address(0001))
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
        XCTAssertEqual(meshNetwork.localProvisioner!.primaryUnicastAddress, 0x0001)
        
        XCTAssertEqual(meshNetwork.networkKeys.count, 2)
        XCTAssertEqual(meshNetwork.applicationKeys.count, 3)
        XCTAssertNotNil(meshNetwork.applicationKeys[0].meshNetwork)
        XCTAssertNotNil(meshNetwork.applicationKeys[1].meshNetwork)
        XCTAssertNotNil(meshNetwork.applicationKeys[2].meshNetwork)
        XCTAssertEqual(meshNetwork.applicationKeys[0].boundNetworkKeyIndex, meshNetwork.networkKeys[0].index)
        XCTAssertEqual(meshNetwork.applicationKeys[1].boundNetworkKeyIndex, meshNetwork.networkKeys[0].index)
        XCTAssertEqual(meshNetwork.applicationKeys[0].boundNetworkKey, meshNetwork.networkKeys[0])
        XCTAssertEqual(meshNetwork.applicationKeys[1].boundNetworkKey, meshNetwork.networkKeys[0])
        
        XCTAssertEqual(meshNetwork.nodes.count, 1)
        XCTAssertNotNil(meshNetwork.nodes[0].meshNetwork)
    }

    func testFastSending() async throws {
        XCTAssertNotNil(manager)
        XCTAssertNotNil(manager.meshNetwork)
        
        let transmitter = DummyTransmitter()
        
        manager.delegate = self
        manager.transmitter = transmitter
        manager.localElements = []
        manager.logger = self
        
        let meshNetwork = manager.meshNetwork!
        
        let sceneClientModel = meshNetwork.localProvisioner?.node?
            .primaryElement?.model(withSigModelId: .sceneClientModelId)
        XCTAssertNotNil(sceneClientModel)
        XCTAssertTrue(sceneClientModel?.isBluetoothSIGAssigned == true)
        XCTAssertTrue(sceneClientModel?.boundApplicationKeys.isEmpty == true)
        XCTAssertTrue(sceneClientModel?.isSceneClient == true)
        
        let firstKey = meshNetwork.applicationKeys.first
        XCTAssertNotNil(firstKey)
        let lastKey = meshNetwork.applicationKeys.last
        XCTAssertNotNil(lastKey)
        
        messageSent = expectation(description: "Message sent")
        messageSent.expectedFulfillmentCount = 2
        statusSent = expectation(description: "Status sent")
        statusSent.expectedFulfillmentCount = 2
        statusReceived = expectation(description: "Status received")
        statusReceived.expectedFulfillmentCount = 2
        keyBound = expectation(description: "Key bound")
        keyBound.expectedFulfillmentCount = 2
        
        let bindFirstAppKey = ConfigModelAppBind(applicationKey: firstKey!, to: sceneClientModel!)
        XCTAssertNotNil(bindFirstAppKey)
        let response1 = try await manager.sendToLocalNode(bindFirstAppKey!)
        XCTAssert(response1 is ConfigModelAppStatus)
        
        let bindLastAppKey = ConfigModelAppBind(applicationKey: lastKey!, to: sceneClientModel!)
        XCTAssertNotNil(bindLastAppKey)
        let response2 = try await manager.sendToLocalNode(bindLastAppKey!)
        XCTAssert(response2 is ConfigModelAppStatus)
        
        await fulfillment(of: [messageSent, keyBound, statusSent, statusReceived], timeout: 2)
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            didReceiveMessage message: MeshMessage,
                            sentFrom source: Address, to destination: MeshAddress) {
        if message is ConfigModelAppBind {
            let sceneClientModel = manager.meshNetwork?.localProvisioner?.node?
                .primaryElement?.model(withSigModelId: .sceneClientModelId)
            XCTAssertNotNil(sceneClientModel)
            XCTAssertTrue(sceneClientModel?.boundApplicationKeys.isEmpty == false)
        
            if sceneClientModel?.boundApplicationKeys.first?.index == 0 {
                keyBound.fulfill()
            }
        }
        if message is ConfigModelAppStatus {
            statusReceived.fulfill()
        }
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager, didSendMessage message: MeshMessage,
                            from localElement: Element, to destination: MeshAddress) {
        if message is ConfigModelAppBind {
            messageSent.fulfill()
        }
        if message is ConfigModelAppStatus {
            statusSent.fulfill()
        }
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager, failedToSendMessage message: MeshMessage,
                            from localElement: Element, to destination: MeshAddress, error: Error) {
        XCTFail(error.localizedDescription)
    }

}

// MARK: - Logger

extension FastSending: LoggerDelegate {
    
    func log(message: String, ofCategory category: LogCategory, withLevel level: LogLevel) {
        if #available(iOS 10.0, *) {
            os_log("%{public}@", log: category.log, type: level.type, message)
        } else {
            NSLog("%@", message)
        }
    }
    
}

extension LogLevel {
    
    /// Mapping from mesh log levels to system log types.
    var type: OSLogType {
        switch self {
        case .debug:       return .debug
        case .verbose:     return .debug
        case .info:        return .info
        case .application: return .default
        case .warning:     return .error
        case .error:       return .fault
        }
    }
    
}

extension LogCategory {
    
    var log: OSLog {
        return OSLog(subsystem: Bundle.main.bundleIdentifier!, category: rawValue)
    }
    
}
