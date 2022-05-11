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

import Foundation

/// Log level, which allows filtering logs by importance.
public enum LogLevel: Int {
    /// Lowest priority. Usually names of called methods or callbacks received.
    case debug       = 0
    /// Low priority messages what the service is doing.
    case verbose     = 1
    /// Messages about completed tasks.
    case info        = 5
    /// Messages about application level events, in this case DFU messages in human-readable form.
    case application = 10
    /// Important messages.
    case warning     = 15
    /// Highest priority messages with errors.
    case error       = 20
    
    /// A shortened abbreviation of the log level.
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

/// The log category indicates the component that created the log entry.
public enum LogCategory: String {
    /// Log created by the Bearer component.
    case bearer          = "Bearer"
    /// Log created by the Proxy component.
    case proxy           = "Proxy"
    /// Log created by the Network layer.
    case network         = "Network"
    /// Log created by the Lower Transport layer.
    case lowerTransport  = "LowerTransport"
    /// Log created by the Upper Transport layer.
    case upperTransport  = "UpperTransport"
    /// Log created by the Access layer.
    case access          = "Access"
    /// Log created by the Foundation layer models.
    case foundationModel = "FoundationModel"
    /// Log created by the Access layer model.
    case model           = "Model"
    /// Log created by the Provisioning component.
    case provisioning    = "Provisioning"
}

/// The Logger delegate.
public protocol LoggerDelegate: AnyObject {
    
    /// This method is called whenever a new log entry is to be saved.
    ///
    /// - Important: It is NOT safe to update the UI from this method as multiple
    ///              threads may log.
    ///
    /// - parameters:
    ///   - message:  The message.
    ///   - category: The message category.
    ///   - level:    The log level.
    func log(message: String, ofCategory category: LogCategory, withLevel level: LogLevel)
}

internal extension LoggerDelegate {
    
    func d(_ category: LogCategory, _ message: @autoclosure () -> String) {
        log(message: message(), ofCategory: category, withLevel: .debug)
    }
    
    func v(_ category: LogCategory, _ message: @autoclosure () -> String) {
        log(message: message(), ofCategory: category, withLevel: .verbose)
    }
    
    func i(_ category: LogCategory, _ message: @autoclosure () -> String) {
        log(message: message(), ofCategory: category, withLevel: .info)
    }
    
    func a(_ category: LogCategory, _ message: @autoclosure () -> String) {
        log(message: message(), ofCategory: category, withLevel: .application)
    }
    
    func w(_ category: LogCategory, _ message: @autoclosure () -> String) {
        log(message: message(), ofCategory: category, withLevel: .warning)
    }
    
    func w(_ category: LogCategory, _ error: Error) {
        log(message: error.localizedDescription, ofCategory: category, withLevel: .warning)
    }
    
    func e(_ category: LogCategory, _ message: @autoclosure () -> String) {
        log(message: message(), ofCategory: category, withLevel: .error)
    }
    
    func e(_ category: LogCategory, _ error: Error) {
        log(message: error.localizedDescription, ofCategory: category, withLevel: .error)
    }
    
}
