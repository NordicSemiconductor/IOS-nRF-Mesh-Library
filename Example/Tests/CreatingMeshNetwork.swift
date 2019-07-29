//
//  CreatingMeshNetwork.swift
//  nRFMeshProvision_Tests
//
//  Created by Aleksander Nowakowski on 29/07/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

@testable import nRFMeshProvision
import XCTest

private struct TestStorage: Storage {
    
    func load() -> Data? {
        return nil
    }
    
    func save(_ data: Data) -> Bool {
        return true
    }
    
}

class CreatingMeshNetwork: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCreateMeshNetwork() {
        let manager = MeshNetworkManager(using: TestStorage())
        XCTAssertNoThrow(manager.createNewMeshNetwork(withName: "Test network", by: "Test Provisioner"))
        XCTAssertNotNil(manager.meshNetwork)
        let network = manager.meshNetwork
        XCTAssertEqual(network?.meshName, "Test network")
        XCTAssertEqual(network?.provisioners.count, 1)
        XCTAssertEqual(network?.provisioners.first?.provisionerName, "Test Provisioner")
        XCTAssertEqual(network?.networkKeys.count, 1)
        XCTAssertEqual(network?.nodes.count, 1)
        XCTAssertEqual(network?.nodes.first?.name, "Test Provisioner")
        XCTAssertEqual(network?.nodes.first?.networkKeys.first?.index, 0)
    }

}
