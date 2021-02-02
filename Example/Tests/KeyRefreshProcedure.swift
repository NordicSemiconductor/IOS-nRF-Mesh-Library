/*
* Copyright (c) 2021, Nordic Semiconductor
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

class KeyRefreshProcedure: XCTestCase {

    func testNetworkKeyNormalOperation() throws {
        let key = Data(hex: "00112233445566778899AABBCCDDEEFF")!
        let networkKey = try NetworkKey(name: "Test Key", index: 0, key: key)
        XCTAssertEqual(networkKey.phase, .normalOperation)
        XCTAssertEqual(networkKey.index, 0)
        XCTAssertEqual(networkKey.key, key)
        XCTAssertNotNil(networkKey.keys)
        XCTAssertEqual(networkKey.keys.beaconKey,     Data(hex: "44F5E91B3F2B9EE2D1C6023D2A57F1F3"))
        XCTAssertEqual(networkKey.keys.encryptionKey, Data(hex: "EAA68445FFA4F38F96F2CCC5CC16119C"))
        XCTAssertEqual(networkKey.keys.identityKey,   Data(hex: "C7BBF25E84C88EFDE1AF24231A7B90E6"))
        XCTAssertEqual(networkKey.keys.privacyKey,    Data(hex: "33F2DDDEFD05965A2FF862DDCBF8298C"))
        XCTAssertEqual(networkKey.networkId,          Data(hex: "1FBD2C61A4B6E5A4"))
        XCTAssertNil(networkKey.oldKey)
        XCTAssertNil(networkKey.oldKeys)
        XCTAssertNil(networkKey.oldNetworkId)
        // In Normal Operation the single key should be used.
        XCTAssertEqual(networkKey.keys.encryptionKey, networkKey.transmitKeys.encryptionKey)
    }

}
