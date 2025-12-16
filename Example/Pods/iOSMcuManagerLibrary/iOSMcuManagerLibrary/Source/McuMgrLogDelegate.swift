/*
 * Copyright (c) 2017-2018 Runtime Inc.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

// MARK: - McuMgrLogLevel

/// Log level.
///
/// Logger application may filter log entries based on their level.
/// Levels allow to ignore less important messages.
///
/// - Debug       - Debug priority. Intended only for debug purposes.
/// - Verbose     - Low priority messages what the service is doing.
/// - Info        - Messages about completed tasks.
/// - Application - Messages about application level events, in human-readable form.
/// - Warning     - Important messages.
/// - Error       - Highest priority messages with errors.
public enum McuMgrLogLevel: Int {
    case debug       = 0
    case verbose     = 1
    case info        = 5
    case application = 10
    case warning     = 15
    case error       = 20
    
    public var name: String {
        switch self {
        case .debug:       return "D"
        case .verbose:     return "V"
        case .info:        return "I"
        case .application: return "A"
        case .warning:     return "W"
        case .error:       return "E"
        }
    }
}

extension McuMgrLogLevel: Comparable {
    
    public static func < (lhs: McuMgrLogLevel, rhs: McuMgrLogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
}

// MARK: - McuMgrLogCategory

/// The log category indicates the component that created the log entry.
public enum McuMgrLogCategory: String {
    case transport         = "Transport"
    case settings          = "SettingsManager"
    case crash             = "CrashManager"
    case `default`         = "DefaultManager"
    case filesystemManager = "FileSystemManager"
    case image             = "ImageManager"
    case log               = "LogManager"
    case runTest           = "RunTestManager"
    case stats             = "StatsManager"
    case dfu               = "DFU"
    case basic             = "BasicManager"
    case shell             = "ShellManager"
    case suit              = "SuitManager"
}

// MARK: - McuMgrLogDelegate

public protocol McuMgrLogDelegate: AnyObject {
    
    /// Provides the delegate with content intended to be logged.
    ///
    /// - parameters:
    ///   - msg: The text to log.
    ///   - category: The log category.
    ///   - level: The priority of the text being logged.
    func log(_ msg: String,
             ofCategory category: McuMgrLogCategory,
             atLevel level: McuMgrLogLevel)
    
    /// Returns the minimum log level to be logged.
    func minLogLevel() -> McuMgrLogLevel
}

public extension McuMgrLogDelegate {
    
    func minLogLevel() -> McuMgrLogLevel {
        return .debug
    }
}
