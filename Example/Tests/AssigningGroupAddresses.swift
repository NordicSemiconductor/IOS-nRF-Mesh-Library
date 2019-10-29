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

class AssigningGroupAddresses: XCTestCase {
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testAssigningGroupAddress_empty() {
        let meshNetwork = MeshNetwork(name: "Test network")
        
        let provisioner = Provisioner(name: "Test provisioner",
                                      allocatedUnicastRange: [ AddressRange(1...0x7FFF) ],
                                      allocatedGroupRange: [ AddressRange(0xC000...0xC008) ],
                                      allocatedSceneRange: [])
        
        let address = meshNetwork.nextAvailableGroupAddress(for: provisioner)
        
        XCTAssertNotNil(address)
        XCTAssertEqual(address!, 0xC000)
    }
    
    func testAssigningGroupAddress_basic() {
        let meshNetwork = MeshNetwork(name: "Test network")
        
        let provisioner = Provisioner(name: "Test provisioner",
                                      allocatedUnicastRange: [ AddressRange(1...0x7FFF) ],
                                      allocatedGroupRange: [ AddressRange(0xD015...0xD0FF) ],
                                      allocatedSceneRange: [])
        
        let address = meshNetwork.nextAvailableGroupAddress(for: provisioner)
        
        XCTAssertNotNil(address)
        XCTAssertEqual(address!, 0xD015)
    }
    
    func testAssigningGroupAddress_some() {
        let meshNetwork = MeshNetwork(name: "Test network")
        
        let provisioner = Provisioner(name: "Test provisioner",
                                      allocatedUnicastRange: [ AddressRange(1...0x7FFF) ],
                                      allocatedGroupRange: [ AddressRange(0xC000...0xC001), AddressRange(0xC00F...0xC00F) ],
                                      allocatedSceneRange: [])
        XCTAssertNoThrow(try meshNetwork.add(group: Group(name: "Group 1", address: 0xC000)))
        XCTAssertNoThrow(try meshNetwork.add(group: Group(name: "Group 2", address: 0xC001)))
        
        let address = meshNetwork.nextAvailableGroupAddress(for: provisioner)
        
        XCTAssertNotNil(address)
        XCTAssertEqual(address!, 0xC00F)
    }
    
    func testAssigningGroupAddress_no_more() {
        let meshNetwork = MeshNetwork(name: "Test network")
        
        let provisioner = Provisioner(name: "Test provisioner",
                                      allocatedUnicastRange: [ AddressRange(1...0x7FFF) ],
                                      allocatedGroupRange: [ AddressRange(0xC000...0xC001), AddressRange(0xC00F...0xC00F) ],
                                      allocatedSceneRange: [])
        XCTAssertNoThrow(try meshNetwork.add(group: Group(name: "Group 1", address: 0xC000)))
        XCTAssertNoThrow(try meshNetwork.add(group: Group(name: "Group 2", address: 0xC001)))
        XCTAssertNoThrow(try meshNetwork.add(group: Group(name: "Group 3", address: 0xC00F)))
        
        let address = meshNetwork.nextAvailableGroupAddress(for: provisioner)
        
        XCTAssertNil(address)
    }

}
