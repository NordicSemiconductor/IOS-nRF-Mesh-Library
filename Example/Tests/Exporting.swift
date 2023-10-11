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

class Exporting: XCTestCase {
    var meshNetwork: MeshNetwork!

    override func setUpWithError() throws {
        meshNetwork = MeshNetwork(name: "Test network", uuid: UUID())
        
        // Create 2 Network Keys (Primary Network Key is generated automatically),
        // including one Guest Network Key.
        var primaryNetworkKey: NetworkKey?
        var guestNetworkKey: NetworkKey?
        XCTAssertNoThrow(guestNetworkKey = try meshNetwork.add(networkKey: Data.random128BitKey(), name: "Guest Network Key"))
        XCTAssertNotNil(guestNetworkKey)
        primaryNetworkKey = meshNetwork.networkKeys.primaryKey
        XCTAssertNotNil(primaryNetworkKey)
        XCTAssertEqual(meshNetwork.networkKeys.count, 2) // Primary Network Key is created automatically.
        
        // Create 3 Application Keys, including one Guest Key.
        var lightsKey: ApplicationKey?
        var locksKey:  ApplicationKey?
        var guestKey:  ApplicationKey?
        XCTAssertNoThrow(lightsKey = try meshNetwork.add(applicationKey: Data.random128BitKey(), name: "Lights"))
        XCTAssertNoThrow(locksKey  = try meshNetwork.add(applicationKey: Data.random128BitKey(), name: "Locks"))
        XCTAssertNoThrow(guestKey  = try meshNetwork.add(applicationKey: Data.random128BitKey(), name: "Guest Lights"))
        XCTAssertNotNil(lightsKey)
        XCTAssertNotNil(locksKey)
        XCTAssertNotNil(guestKey)
        XCTAssertNoThrow(try guestNetworkKey.map { try guestKey?.bind(to: $0) })
        XCTAssertEqual(lightsKey?.boundNetworkKeyIndex, primaryNetworkKey?.index)
        XCTAssertEqual(locksKey?.boundNetworkKeyIndex,  primaryNetworkKey?.index)
        XCTAssertEqual(guestKey?.boundNetworkKeyIndex,  guestNetworkKey?.index)
        
        // Define Groups.
        let kitchenLights   = try? Group(name: "Kitchen Lights", address: MeshAddress(0xC000))
        let locks           = try? Group(name: "Locks", address: MeshAddress(0xC001))
        let guestRoomLights = try? Group(name: "Guest Room Lights", address: MeshAddress(0xD001))
        XCTAssertNotNil(kitchenLights)
        XCTAssertNotNil(locks)
        XCTAssertNotNil(guestRoomLights)
        XCTAssertNoThrow(try kitchenLights.map {   try meshNetwork.add(group: $0) })
        XCTAssertNoThrow(try locks.map {           try meshNetwork.add(group: $0) })
        XCTAssertNoThrow(try guestRoomLights.map { try meshNetwork.add(group: $0) })
        
        // Define Scenes.
        XCTAssertNoThrow(try meshNetwork.add(scene: Scene.allOff,        name: "All Off"))
        XCTAssertNoThrow(try meshNetwork.add(scene: Scene.kitchenOff,    name: "Kitchen On"))
        XCTAssertNoThrow(try meshNetwork.add(scene: Scene.kitchenOn,     name: "Kitchen Off"))
        XCTAssertNoThrow(try meshNetwork.add(scene: Scene.cozyGuestRoom, name: "Cozy Guest Room Setup"))
        XCTAssertEqual(meshNetwork.scenes.count, 4)
        XCTAssertFalse(meshNetwork.scenes.contains(where: { $0.isUsed }))
        
        // Define Provisioners. The main one, and one for the Guest.
        let mainProvisioner = Provisioner(name: "Main Provisioner", uuid: UUID(),
                                          allocatedUnicastRange: [AddressRange(0x0001...0x0010)],
                                          allocatedGroupRange: [AddressRange(0xC001...0xC010)],
                                          allocatedSceneRange: [SceneRange(0x0001...0x0010)])
        XCTAssertNoThrow(try meshNetwork.add(provisioner: mainProvisioner))
        XCTAssertNotNil(meshNetwork.localProvisioner?.node)
        XCTAssertGreaterThanOrEqual(meshNetwork.localProvisioner?.node?.elementsCount ?? 0, 1)
        XCTAssertEqual(meshNetwork.localProvisioner?.node?.networkKeys.count, 2)
        XCTAssertEqual(meshNetwork.localProvisioner?.node?.applicationKeys.count, 3)
        
        let guestProvisioner = Provisioner(name: "Guest Provisioner", uuid: UUID(),
                                           // Single Address, just for the single Element.
                                           allocatedUnicastRange: [AddressRange(0x1000...0x1000)],
                                           allocatedGroupRange: [],
                                           allocatedSceneRange: [])
        XCTAssertNoThrow(try meshNetwork.add(provisioner: guestProvisioner, withAddress: 0x1000))
        XCTAssertNotNil(guestProvisioner.node)
        
        // As the Composition Data have not been obtained from the Guest Provisioner's Node, the
        // Primary Element is unknown.
        XCTAssertNil(guestProvisioner.node?.primaryElement)
        
        let data = Data(hex: "004600CDAB0001FFFFFFFF01000300000002000110")
        guestProvisioner.node?.apply(compositionData: ConfigCompositionDataStatus(parameters: data)!)
        
        // As the Composition Data have been obtained, now the Primary Element should be available.
        XCTAssertNotNil(guestProvisioner.node?.primaryElement)
        
        let guestGenericOnOffClientModel = guestProvisioner.node?.primaryElement?
            .model(withSigModelId: .genericOnOffClientModelId)
        XCTAssertNotNil(guestGenericOnOffClientModel)
        guestKey.map { key in
            guestGenericOnOffClientModel!.bind(applicationKeyWithIndex: key.index)
            guestRoomLights.map { group in
                guestGenericOnOffClientModel!.set(publication: Publish(to: group.address, using: key,
                                                                       usingFriendshipMaterial: false, ttl: 5,
                                                                       period: .disabled, retransmit: .disabled))
            }
        }
        
        // Setup Nodes in the kitchen.
        let kitchenLightSwitch = Node(name: "Kitchen Light Switch", uuid: UUID(), deviceKey: Data.random128BitKey(),
                                      security: .secure,
                                      andAssignedNetworkKey: primaryNetworkKey!, andAddress: 0x0002)
        kitchenLightSwitch.add(elements: [
            Element(name: "Left button", location: .left,
                    models: [
                        Model(sigModelId: .configurationServerModelId),
                        Model(sigModelId: .healthServerModelId),
                        Model(sigModelId: .genericOnOffClientModelId)
                    ]
            ),
            Element(name: "Right button", location: .right,
                    models: [
                        Model(sigModelId: .genericOnOffClientModelId)
                    ]
            )
        ])
        
        let kitchenLight = Node(name: "Kitchen Light", uuid: UUID(), deviceKey: Data.random128BitKey(),
                                security: .secure,
                                andAssignedNetworkKey: primaryNetworkKey!, andAddress: 0x0004)
        kitchenLight.add(element:
            Element(name: "Main Element", location: .left,
                    models: [
                        Model(sigModelId: .configurationServerModelId),
                        Model(sigModelId: .healthServerModelId),
                        Model(sigModelId: .sceneServerModelId),
                        Model(sigModelId: .sceneSetupServerModelId),
                        Model(sigModelId: .genericOnOffServerModelId)
                    ]
            )
        )
        let led = Node(name: "LED", uuid: UUID(), deviceKey: Data.random128BitKey(),
                       security: .secure,
                       andAssignedNetworkKey: primaryNetworkKey!, andAddress: 0x0005)
        led.add(element:
            Element(name: "Main Element", location: .left,
                    models: [
                        Model(sigModelId: .configurationServerModelId),
                        Model(sigModelId: .healthServerModelId),
                        Model(sigModelId: .genericOnOffServerModelId),
                        Model(sigModelId: .sceneServerModelId),
                        Model(sigModelId: .sceneSetupServerModelId)
                    ]
            )
        )
        
        XCTAssertNoThrow(try meshNetwork.add(node: kitchenLightSwitch))
        XCTAssertNoThrow(try meshNetwork.add(node: kitchenLight))
        XCTAssertNoThrow(try meshNetwork.add(node: led))
        
        // Configure Light Switch in the kitchen.
        lightsKey.map { key in
            kitchenLightSwitch.add(applicationKey: key)
            XCTAssert(kitchenLightSwitch.applicationKeys.contains(key))
        }
        XCTAssertEqual(kitchenLightSwitch.applicationKeys.count, 1)
        let leftButtonModel = kitchenLightSwitch.elements.first?.model(withSigModelId: .genericOnOffClientModelId)
        XCTAssertNotNil(leftButtonModel)
        lightsKey.map { key in
            leftButtonModel?.bind(applicationKeyWithIndex: key.index)
            kitchenLights.map { group in
                leftButtonModel?.set(publication: Publish(to: group.address, using: key,
                                                          usingFriendshipMaterial: false, ttl: 5,
                                                          period: .disabled,
                                                          retransmit: Publish.Retransmit(1, timesWithInterval: 0.2)))
            }
        }
        XCTAssertEqual(leftButtonModel?.boundApplicationKeys.count, 1)
        XCTAssertNotNil(leftButtonModel?.publish)
        
        let rightButtonModel = kitchenLightSwitch.elements.last?.model(withSigModelId: .genericOnOffClientModelId)
        XCTAssertNotNil(rightButtonModel)
        lightsKey.map { key in
            rightButtonModel?.bind(applicationKeyWithIndex: key.index)
            rightButtonModel?.set(publication: Publish(to: MeshAddress(led.primaryUnicastAddress), using: key,
                                                       usingFriendshipMaterial: false, ttl: 5,
                                                       period: .disabled, retransmit: .disabled))
        }
        XCTAssertEqual(rightButtonModel?.boundApplicationKeys.count, 1)
        XCTAssertNotNil(rightButtonModel?.publish)
        
        // Configure Kitchen Light and subscribe it to Kitchen Lights group.
        lightsKey.map { key in
            kitchenLight.add(applicationKey: key)
            XCTAssert(kitchenLight.applicationKeys.contains(key))
        }
        XCTAssertEqual(kitchenLight.applicationKeys.count, 1)
        let kitchenLightModel = kitchenLight.elements.first?.model(withSigModelId: .genericOnOffServerModelId)
        XCTAssertNotNil(kitchenLightModel)
        lightsKey.map { key in
            kitchenLightModel?.bind(applicationKeyWithIndex: key.index)
        }
        kitchenLights.map { group in
            kitchenLightModel?.subscribe(to: group)
            XCTAssert(kitchenLightModel?.subscriptions.contains(group) ?? false)
        }
        // Simulate that the Kitchen Light Scene Register was set to use the following scenes:
        meshNetwork.scenes[Scene.allOff]?.add(address: kitchenLight.primaryUnicastAddress)
        XCTAssertFalse(meshNetwork.scenes[Scene.allOff]?.nodes.isEmpty ?? true)
        meshNetwork.scenes[Scene.kitchenOn]?.add(address: kitchenLight.primaryUnicastAddress)
        XCTAssertFalse(meshNetwork.scenes[Scene.kitchenOn]?.nodes.isEmpty ?? true)
        meshNetwork.scenes[Scene.kitchenOff]?.add(address: kitchenLight.primaryUnicastAddress)
        XCTAssertFalse(meshNetwork.scenes[Scene.kitchenOff]?.nodes.isEmpty ?? true)
        XCTAssertTrue(meshNetwork.scenes.contains(where: { $0.isUsed }))
        
        // Configure Kitchen LED light.
        lightsKey.map { key in
            led.add(applicationKey: key)
            XCTAssert(led.applicationKeys.contains(key))
        }
        XCTAssertEqual(led.applicationKeys.count, 1)
        let ledModel = led.elements.first?.model(withSigModelId: .genericOnOffServerModelId)
        XCTAssertNotNil(ledModel)
        lightsKey.map { key in
            ledModel?.bind(applicationKeyWithIndex: key.index)
        }
        // Simulate that the LED Scene Register was set to use the following scenes:
        meshNetwork.scenes[Scene.allOff]?.add(address: led.primaryUnicastAddress)
        XCTAssertTrue(meshNetwork.scenes[Scene.allOff]?.nodes.contains(led) ?? false)
        meshNetwork.scenes[Scene.kitchenOn]?.add(address: led.primaryUnicastAddress)
        XCTAssertTrue(meshNetwork.scenes[Scene.kitchenOn]?.nodes.contains(led) ?? false)
        meshNetwork.scenes[Scene.kitchenOff]?.add(address: led.primaryUnicastAddress)
        XCTAssertTrue(meshNetwork.scenes[Scene.kitchenOff]?.nodes.contains(led) ?? false)
        
        // Configure Lock.
        let lock = Node(name: "Door Lock", uuid: UUID(), deviceKey: Data.random128BitKey(),
                        security: .insecure,
                        andAssignedNetworkKey: primaryNetworkKey!, andAddress: 0x0010)
        lock.add(element: Element(name: "Main Element", location: .main,
                                  models: [
                                    Model(sigModelId: .configurationServerModelId),
                                    Model(sigModelId: .healthServerModelId),
                                    Model(sigModelId: .sceneServerModelId),
                                    Model(sigModelId: .sceneSetupServerModelId),
                                    Model(sigModelId: .genericOnOffServerModelId),
                                  ]))
        XCTAssertNoThrow(try meshNetwork.add(node: lock))
        locksKey.map { key in
            lock.add(applicationKey: key)
            XCTAssert(lock.applicationKeys.contains(key))
        }
        XCTAssertEqual(lock.applicationKeys.count, 1)
        let lockModel = led.elements.first?.model(withSigModelId: .genericOnOffServerModelId)
        XCTAssertNotNil(lockModel)
        locksKey.map { key in
            lockModel?.bind(applicationKeyWithIndex: key.index)
        }
        locks.map { group in
            lockModel?.subscribe(to: group)
            XCTAssert(lockModel?.subscriptions.contains(group) ?? false)
        }
        // Simulate that the Lock's Scene Register was set to use the following scene:
        meshNetwork.scenes[Scene.allOff]?.add(address: lock.primaryUnicastAddress)
        XCTAssertTrue(meshNetwork.scenes[Scene.allOff]?.nodes.contains(lock) ?? false)
        
        // Setup Nodes in the guest room.
        let guestSwitch = Node(name: "Guest Room Switch", uuid: UUID(), deviceKey: Data.random128BitKey(),
                               security: .insecure,
                               andAssignedNetworkKey: primaryNetworkKey!, andAddress: 0x0100)
        guestSwitch.add(element: Element(name: "Toggle Button", location: .main,
                                         models: [
                                            Model(sigModelId: .configurationServerModelId),
                                            Model(sigModelId: .healthServerModelId),
                                            Model(sigModelId: .genericOnOffClientModelId)
                                         ]))
        
        let guestLight = Node(name: "Guest Light", uuid: UUID(), deviceKey: Data.random128BitKey(),
                              security: .insecure,
                              andAssignedNetworkKey: primaryNetworkKey!, andAddress: 0x0101)
        guestLight.add(element: Element(name: "Main Element", location: .unknown,
                       models: [
                        Model(sigModelId: .configurationServerModelId),
                        Model(sigModelId: .healthServerModelId),
                        Model(sigModelId: .sceneServerModelId),
                        Model(sigModelId: .sceneSetupServerModelId),
                        Model(sigModelId: .genericOnOffServerModelId)
                       ]))
        
        XCTAssertNoThrow(try meshNetwork.add(node: guestSwitch))
        XCTAssertNoThrow(try meshNetwork.add(node: guestLight))
        
        // Configure Guest Switch.
        guestNetworkKey.map { key in
            guestSwitch.add(networkKey: key)
            XCTAssert(guestSwitch.networkKeys.contains(key))
        }
        XCTAssertEqual(guestSwitch.networkKeys.count, 2)
        guestKey.map { key in
            guestSwitch.add(applicationKey: key)
            XCTAssert(guestSwitch.applicationKeys.contains(key))
        }
        XCTAssertEqual(guestSwitch.applicationKeys.count, 1)
        let guestButtonModel = guestSwitch.elements.first?.model(withSigModelId: .genericOnOffClientModelId)
        XCTAssertNotNil(guestButtonModel)
        guestKey.map { key in
            guestButtonModel?.bind(applicationKeyWithIndex: key.index)
            guestRoomLights.map { group in
                guestButtonModel?.set(publication: Publish(to: group.address, using: key,
                                                           usingFriendshipMaterial: false, ttl: 5,
                                                           period: .disabled,
                                                           retransmit: Publish.Retransmit(1, timesWithInterval: 0.2)))
            }
        }
        XCTAssertEqual(guestButtonModel?.boundApplicationKeys.count, 1)
        XCTAssertNotNil(guestButtonModel?.publish)
        
        // Configure Guest Light and subscribe it to Guest Room Lights group.
        guestNetworkKey.map { key in
            guestLight.add(networkKey: key)
            XCTAssert(guestLight.networkKeys.contains(key))
        }
        XCTAssertEqual(guestLight.networkKeys.count, 2)
        guestKey.map { key in
            guestLight.add(applicationKey: key)
            XCTAssert(guestLight.applicationKeys.contains(key))
        }
        XCTAssertEqual(guestLight.applicationKeys.count, 1)
        let guestLightModel = kitchenLight.elements.first?.model(withSigModelId: .genericOnOffServerModelId)
        XCTAssertNotNil(guestLightModel)
        guestKey.map { key in
            guestLightModel?.bind(applicationKeyWithIndex: key.index)
        }
        guestRoomLights.map { group in
            guestLightModel?.subscribe(to: group)
            XCTAssert(guestLightModel?.subscriptions.contains(group) ?? false)
        }
        // Simulate that the Lock's Scene Register was set to use the following scene:
        meshNetwork.scenes[Scene.cozyGuestRoom]?.add(address: guestLight.primaryUnicastAddress)
        XCTAssertTrue(meshNetwork.scenes[Scene.cozyGuestRoom]?.nodes.contains(guestLight) ?? false)
        meshNetwork.scenes[Scene.allOff]?.add(address: guestLight.primaryUnicastAddress)
        XCTAssertTrue(meshNetwork.scenes[Scene.allOff]?.nodes.contains(guestLight) ?? false)
        
        // Add and remove a Node.
        XCTAssertNoThrow(try meshNetwork.add(node: Node(insecureNode: "Old Node", with: 1,
                                                        elementsDeviceKey: Data.random128BitKey(),
                                                        andAssignedNetworkKey: primaryNetworkKey!,
                                                        andAddress: 0x0F10)!))
        meshNetwork.node(withAddress: 0x0F10).map { node in
            node.add(element: Element(name: "Main Element", location: .unknown,
                                      models: [
                                        Model(sigModelId: .configurationServerModelId),
                                        Model(sigModelId: .healthServerModelId),
                                        Model(sigModelId: .genericOnOffClientModelId)
                                      ]))
            meshNetwork.remove(node: node)
        }
        XCTAssertNotNil(meshNetwork.networkExclusions)
        XCTAssertTrue(meshNetwork.networkExclusions?[meshNetwork.ivIndex]?.isExcluded(0x0F10) ?? false)
        XCTAssertEqual(meshNetwork.networkExclusions?.count, 1)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExportBasic() throws {
        let copy = meshNetwork.copy(using: .full)
        // This test tests implementation detail which may change.
        // In the current version, when copy(using .full) is called, the
        // same network instance is returned instead of creating an actual
        // copy. If this test fails, check the implementation and fix the
        // test.
        XCTAssert(copy === meshNetwork)
    }
    
    func testExportFull() throws {
        let copy = MeshNetwork(copy: meshNetwork, using: .full)
        XCTAssertEqual(copy.uuid, meshNetwork.uuid)
        XCTAssertEqual(copy.meshName, meshNetwork.meshName)
        XCTAssertEqual(copy.timestamp, meshNetwork.timestamp)
        XCTAssertEqual(copy.isPartial, false)
        XCTAssertEqual(copy.networkKeys.count, meshNetwork.networkKeys.count)
        XCTAssertEqual(copy.applicationKeys.count, meshNetwork.applicationKeys.count)
        XCTAssertEqual(copy.provisioners.count, meshNetwork.provisioners.count)
        XCTAssertEqual(copy.nodes.count, meshNetwork.nodes.count)
        XCTAssertEqual(copy.groups.count, meshNetwork.groups.count)
        XCTAssertEqual(copy.scenes.count, copy.scenes.count)
        XCTAssertEqual(copy.networkExclusions?.count ?? 0, meshNetwork.networkExclusions?.count ?? 0)
        
        copy.nodes.forEach { node in
            let matchingNode = meshNetwork.node(withUuid: node.uuid)
            XCTAssertNotNil(matchingNode)
            XCTAssertEqual(node.networkKeys.count, matchingNode?.networkKeys.count)
            XCTAssertEqual(node.applicationKeys.count, matchingNode?.applicationKeys.count)
            XCTAssertEqual(node.elements.count, matchingNode?.elements.count)
            node.elements.forEach { element in
                let matchingElement = matchingNode?.element(withAddress: element.unicastAddress)
                XCTAssertNotNil(matchingElement)
                XCTAssertEqual(element.models.count, matchingElement?.models.count)
            }
        }
        
        // Compare the generated JSON outputs.
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.withoutEscapingSlashes, .sortedKeys]
        
        var originalData, copyData: Data?
        XCTAssertNoThrow(originalData = try encoder.encode(meshNetwork))
        XCTAssertNoThrow(copyData = try encoder.encode(meshNetwork))
        XCTAssertEqual(originalData, copyData)
    }
    
    func testExportPartialOneNetworkKey() throws {
        guard let guestNetworkKey = meshNetwork.networkKeys.first(where: { $0.index == 1 }) else {
            XCTFail("Guest Network Key not found")
            return
        }
        // Export
        let copy = MeshNetwork(copy: meshNetwork,
                               using: .partial(networkKeys: .some([guestNetworkKey]),
                                               applicationKeys: .all,
                                               provisioners: .all,
                                               nodes: .allWithDeviceKey))
        XCTAssertEqual(copy.uuid, copy.uuid)
        XCTAssertEqual(copy.meshName, copy.meshName)
        XCTAssertEqual(copy.timestamp, copy.timestamp)
        XCTAssertEqual(copy.isPartial, true)
        XCTAssertEqual(copy.networkKeys.count, 1)
        XCTAssertEqual(copy.applicationKeys.count, 1)
        XCTAssertEqual(copy.provisioners.count, 2)
        XCTAssertEqual(copy.nodes.count, 4)
        copy.nodes.forEach { node in
            let matchingNode = meshNetwork.node(withUuid: node.uuid)
            XCTAssertNotNil(matchingNode)
            XCTAssertNotNil(node.deviceKey)
            XCTAssertEqual(node.deviceKey, matchingNode?.deviceKey)
            XCTAssertEqual(node.networkKeys.count, 1)
            XCTAssertLessThanOrEqual(node.networkKeys.count, matchingNode?.networkKeys.count ?? 0)
            XCTAssertGreaterThanOrEqual(node.applicationKeys.count, 1)
            XCTAssertLessThanOrEqual(node.applicationKeys.count, matchingNode?.applicationKeys.count ?? 0)
            XCTAssertEqual(node.elements.count, matchingNode?.elements.count)
            node.elements.forEach { element in
                let matchingElement = matchingNode?.element(withAddress: element.unicastAddress)
                XCTAssertNotNil(matchingElement)
                XCTAssertEqual(element.models.count, matchingElement?.models.count)
            }
        }
        XCTAssertEqual(copy.groups.count, 1)
        XCTAssertEqual(copy.scenes.count, 2)
        XCTAssertNotNil(copy.scenes[Scene.allOff])
        XCTAssertEqual(copy.scenes[Scene.allOff]?.addresses.count, 1)
        XCTAssertEqual(copy.scenes[Scene.allOff]?.addresses.first, 0x0101)
        XCTAssertEqual(copy.networkExclusions?.count ?? 0, 1)
    }
    
    func testExportOneNetworkKeyWithoutDeviceKeys() throws {
        guard let guestNetworkKey = meshNetwork.networkKeys.first(where: { $0.index == 1 }) else {
            XCTFail("Guest Network Key not found")
            return
        }
        guard let cozyGuestRoom = meshNetwork.scenes[Scene.cozyGuestRoom] else {
            XCTFail("Cozy Guest Room group not found")
            return
        }
        // Export
        let copy = MeshNetwork(copy: meshNetwork,
                               using: .partial(networkKeys: .some([guestNetworkKey]),
                                               applicationKeys: .all,
                                               provisioners: .all,
                                               nodes: .allWithoutDeviceKey,
                                               scenes: .some([cozyGuestRoom])))
        XCTAssertEqual(copy.uuid, copy.uuid)
        XCTAssertEqual(copy.meshName, copy.meshName)
        XCTAssertEqual(copy.timestamp, copy.timestamp)
        XCTAssertEqual(copy.isPartial, true)
        XCTAssertEqual(copy.networkKeys.count, 1)
        XCTAssertEqual(copy.applicationKeys.count, 1)
        XCTAssertEqual(copy.provisioners.count, 2)
        XCTAssertEqual(copy.nodes.count, 4)
        copy.nodes.forEach {
            XCTAssertNil($0.deviceKey)
            XCTAssertEqual($0.networkKeys.count, 1)
            XCTAssertGreaterThanOrEqual($0.applicationKeys.count, 1)
        }
        XCTAssertEqual(copy.groups.count, 1)
        XCTAssertEqual(copy.scenes.count, 1)
        XCTAssertEqual(copy.networkExclusions?.count ?? 0, meshNetwork.networkExclusions?.count ?? 0)
    }
    
    func testExportOneNetworkKeyAndOneProvisioner() throws {
        guard let guestProvisioner = meshNetwork.provisioners.first(where: { $0.name == "Guest Provisioner" }) else {
            XCTFail("Guest Provisioner not found")
            return
        }
        guard let guestNetworkKey = meshNetwork.networkKeys.first(where: { $0.index == 1 }) else {
            XCTFail("Guest Network Key not found")
            return
        }
        // Export
        let copy = MeshNetwork(copy: meshNetwork,
                               using: .partial(networkKeys: .some([guestNetworkKey]),
                                               applicationKeys: .all,
                                               provisioners: .one(guestProvisioner),
                                               nodes: .allWithoutDeviceKey,
                                               groups: .all,
                                               scenes: .all))
        XCTAssertEqual(copy.uuid, copy.uuid)
        XCTAssertEqual(copy.meshName, copy.meshName)
        XCTAssertEqual(copy.timestamp, copy.timestamp)
        XCTAssertEqual(copy.isPartial, true)
        XCTAssertEqual(copy.networkKeys.count, 1)
        XCTAssertEqual(copy.applicationKeys.count, 1)
        XCTAssertEqual(copy.provisioners.count, 1)
        XCTAssertNotNil(copy.localProvisioner)
        XCTAssertNotNil(copy.localProvisioner?.node)
        XCTAssertNotNil(copy.localProvisioner?.node?.primaryElement)
        let guestGenericOnOffClientModel = copy.localProvisioner?.node?.primaryElement?
            .model(withSigModelId: .genericOnOffClientModelId)
        XCTAssertNotNil(guestGenericOnOffClientModel)
        XCTAssertNotNil(guestGenericOnOffClientModel?.publish)
        XCTAssertEqual(guestGenericOnOffClientModel?.publish?.publicationAddress, MeshAddress(0xD001))
        XCTAssertEqual(copy.nodes.count, 3)
        copy.nodes.forEach {
            XCTAssertNil($0.deviceKey)
            XCTAssertEqual($0.networkKeys.count, 1)
            XCTAssertGreaterThanOrEqual($0.applicationKeys.count, 1)
        }
        XCTAssertEqual(copy.groups.count, 3)
        XCTAssertEqual(copy.scenes.count, 4)
        XCTAssertEqual(copy.networkExclusions?.count ?? 0, 1)
    }
    
    func testExportOneProvisioner() throws {
        guard let guestProvisioner = meshNetwork.provisioners.first(where: { $0.name == "Guest Provisioner" }) else {
            XCTFail("Guest Provisioner not found")
            return
        }
        // Export
        let copy = MeshNetwork(copy: meshNetwork,
                               using: .partial(networkKeys: .all,
                                               applicationKeys: .all,
                                               provisioners: .one(guestProvisioner),
                                               nodes: .allWithDeviceKey,
                                               groups: .all,
                                               scenes: .all))
        XCTAssertEqual(copy.uuid, copy.uuid)
        XCTAssertEqual(copy.meshName, copy.meshName)
        XCTAssertEqual(copy.timestamp, copy.timestamp)
        XCTAssertEqual(copy.isPartial, true)
        XCTAssertEqual(copy.networkKeys.count, 2)
        XCTAssertEqual(copy.applicationKeys.count, 3)
        XCTAssertEqual(copy.provisioners.count, 1)
        XCTAssertEqual(copy.nodes.count, 7)
        copy.nodes.forEach {
            XCTAssertNotNil($0.deviceKey)
            XCTAssertGreaterThanOrEqual($0.networkKeys.count, 1)
            XCTAssertGreaterThanOrEqual($0.applicationKeys.count, 1)
        }
        XCTAssertNil(copy.node(withAddress: 0x0001)) // The other provisioner should be excluded.
        XCTAssertEqual(copy.groups.count, 3)
        XCTAssertEqual(copy.scenes.count, 4)
        XCTAssertEqual(copy.networkExclusions?.count ?? 0, 1)
    }
    
    func testExportPublishAndSubscribe() throws {
        guard let primaryNetworkKey = meshNetwork.networkKeys.primaryKey else {
            XCTFail("Primary Network Key not found")
            return
        }
        // Export
        let copy = MeshNetwork(copy: meshNetwork,
                               using: .partial(networkKeys: .some([primaryNetworkKey]),
                                               applicationKeys: .all,
                                               provisioners: .all,
                                               nodes: .allWithDeviceKey,
                                               groups: .some([]),
                                               scenes: .all))
        XCTAssertEqual(copy.uuid, copy.uuid)
        XCTAssertEqual(copy.meshName, copy.meshName)
        XCTAssertEqual(copy.timestamp, copy.timestamp)
        XCTAssertEqual(copy.isPartial, true)
        XCTAssertEqual(copy.networkKeys.count, 1)
        XCTAssertEqual(copy.applicationKeys.count, 2)
        XCTAssertEqual(copy.provisioners.count, 2)
        XCTAssertEqual(copy.nodes.count, 8)
        copy.nodes.forEach { node in
            XCTAssertNotNil(node.deviceKey)
            XCTAssertGreaterThanOrEqual(node.networkKeys.count, 1)
            XCTAssertFalse(node.applicationKeys.contains(where: { $0.boundNetworkKeyIndex == 1 }))
        }
        XCTAssertEqual(copy.groups.count, 0)
        XCTAssertEqual(copy.scenes.count, 4)
        XCTAssertEqual(copy.networkExclusions?.count ?? 0, 1)
        
        let guestSwitch = copy.node(withAddress: 0x0100)
        XCTAssertNotNil(guestSwitch)
        let genericOnOffClientModel = guestSwitch?.elements.first?.model(withSigModelId: .genericOnOffClientModelId)
        XCTAssertNotNil(genericOnOffClientModel)
        XCTAssertNil(genericOnOffClientModel?.publish)
        XCTAssertEqual(genericOnOffClientModel?.bind.count, 0)
    }

}

private extension UInt16 {
    
    static let genericOnOffServerModelId: UInt16 = 0x1000
    static let genericOnOffClientModelId: UInt16 = 0x1001
    
    static let sceneServerModelId:        UInt16 = 0x1203
    static let sceneSetupServerModelId:   UInt16 = 0x1204
    static let sceneClientModelId:        UInt16 = 0x1205
    
}

private extension Scene {
    
    static let allOff:        SceneNumber = 0x0001
    static let kitchenOff:    SceneNumber = 0x0002
    static let kitchenOn:     SceneNumber = 0x0003
    static let cozyGuestRoom: SceneNumber = 0x0004
    
}
