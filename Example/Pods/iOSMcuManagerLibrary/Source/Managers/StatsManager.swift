/*
 * Copyright (c) 2017-2018 Runtime Inc.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import SwiftCBOR

/// Displays statistics from a device.
///
/// Stats manager can read the list of stats modules from a device and read the
/// statistics from a specific module.
public class StatsManager: McuManager {
    override class var TAG: McuMgrLogCategory { .stats }
    
    // MARK: - IDs
    
    enum StatsID: UInt8 {
        case read = 0
        case list = 1
    }
    
    //**************************************************************************
    // MARK: Initializers
    //**************************************************************************

    public init(transport: McuMgrTransport) {
        super.init(group: McuMgrGroup.statistics, transport: transport)
    }
    
    //**************************************************************************
    // MARK: Stats Commands
    //**************************************************************************

    /// Read statistics from a particular stats module.
    ///
    /// - parameter module: The statistics module to.
    /// - parameter callback: The response callback.
    public func read(module: String, callback: @escaping McuMgrCallback<McuMgrStatsResponse>) {
        let payload: [String:CBOR] = ["name": CBOR.utf8String(module)]
        send(op: .read, commandId: StatsID.read, payload: payload, callback: callback)
    }
    
    /// List the statistic modules from a device.
    ///
    /// - parameter callback: The response callback.
    public func list(callback: @escaping McuMgrCallback<McuMgrStatsListResponse>) {
        send(op: .read, commandId: StatsID.list, payload: nil, callback: callback)
    }
}

// MARK: - StatsManagerError

public enum StatsManagerError: UInt64, Error, LocalizedError {
    case noError = 0
    case unknown = 1
    case invalidGroup = 2
    case invalidStatName = 3
    case invalidStatSize = 4
    case abortedWalk = 5
    
    public var errorDescription: String? {
        switch self {
        case .noError:
            return "Success"
        case .unknown:
            return "Unknown error"
        case .invalidGroup:
            return "Statistic group not found"
        case .invalidStatName:
            return "Statistic name not found"
        case .invalidStatSize:
            return "Size of the statistic cannot be handled"
        case .abortedWalk:
            return "Walkthrough of statistics was aborted"
        }
    }
}
