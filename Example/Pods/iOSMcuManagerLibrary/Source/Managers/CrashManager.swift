/*
 * Copyright (c) 2017-2018 Runtime Inc.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import SwiftCBOR

public class CrashManager: McuManager {
    override class var TAG: McuMgrLogCategory { .crash }
    
    // MARK: - IDs

    enum CrashID: UInt8 {
        case test = 0
    }
    
    // MARK: - CrashTest
    
    public enum CrashTest: String {
        case div0 = "div0"
        case jump0 = "jump0"
        case ref0 = "ref0"
        case assert = "assert"
        case wdog = "wdog"
    }
    
    //**************************************************************************
    // MARK: Initializers
    //**************************************************************************

    public init(transport: McuMgrTransport) {
        super.init(group: McuMgrGroup.crash, transport: transport)
    }

    //**************************************************************************
    // MARK: Commands
    //**************************************************************************

    /// Run a crash test on a device.
    ///
    /// - parameter crash: The crash test to run.
    /// - parameter callback: The response callback.
    public func test(crash: CrashTest, callback: @escaping McuMgrCallback<McuMgrResponse>) {
        let payload: [String:CBOR] = ["t": CBOR.utf8String(crash.rawValue)]
        send(op: .write, commandId: CrashID.test, payload: payload, callback: callback)
    }
}
