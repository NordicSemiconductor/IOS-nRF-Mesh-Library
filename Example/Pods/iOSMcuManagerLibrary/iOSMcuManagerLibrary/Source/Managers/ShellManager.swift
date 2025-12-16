//
//  ShellManager.swift
//  iOSMcuManagerLibrary
//
//  Created by Dinesh Harjani on 27/2/24.
//

import Foundation
import SwiftCBOR

// MARK: - ShellManager

/**
 Enables remote execution of McuMgr Shell commands over BLE.
 */
public class ShellManager: McuManager {
    
    // MARK: TAG
    
    override class var TAG: McuMgrLogCategory { .shell }
    
    // MARK: IDs
    
    enum ShellID: UInt8 {
        case exec = 0
    }
    
    // MARK: Init
    
    public init(transport: McuMgrTransport) {
        super.init(group: McuMgrGroup.shell, transport: transport)
    }
    
    // MARK: API
    
    public func execute(command: String, callback: @escaping McuMgrCallback<McuMgrExecResponse>) {
        execute(command: command, arguments: [], callback: callback)
    }
    
    public func execute(command: String, arguments: [String],
                        callback: @escaping McuMgrCallback<McuMgrExecResponse>) {
        let payload: [String: CBOR]
        if arguments.isEmpty {
            payload = ["argv": CBOR.array([CBOR.utf8String(command)])]
        } else {
            var allArguments = [command]
            allArguments.append(contentsOf: arguments)
            payload = ["argv": CBOR.array(allArguments.map({CBOR.utf8String($0)}))]
        }
        send(op: .write, commandId: ShellID.exec, payload: payload, callback: callback)
    }
}

// MARK: - ShellManagerError

public enum ShellManagerError: UInt64, Error, LocalizedError {
    case noError = 0
    case unknown = 1
    case commandTooLong = 2
    case emptyCommand = 3
    
    public var errorDescription: String? {
        switch self {
        case .noError:
            return "Success"
        case .unknown:
            return "Unknown Error"
        case .commandTooLong:
            return "Given Command to run is too long"
        case .emptyCommand:
            return "No Command to run was provided"
        }
    }
}
