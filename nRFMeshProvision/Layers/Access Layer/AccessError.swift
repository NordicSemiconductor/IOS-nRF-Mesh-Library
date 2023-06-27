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

/// A set of errors originating from the access layer.
public enum AccessError: Error {
    /// Error thrown when the local Provisioner does not have
    /// a Unicast Address specified and is not able to send
    /// requested message.
    case invalidSource
    /// Thrown when trying to send a message using an Element
    /// that does not belong to the local Provisioner's Node.
    case invalidElement
    /// Thrown when the given TTL is not valid. Valid TTL must
    /// be 0 or in range 2...127.
    case invalidTtl
    /// Thrown when the destination Address is not known and the
    /// library cannot determine the Network Key to use.
    case invalidDestination
    /// Thrown when trying to send a message from a Model that
    /// does not have any Application Key bound to it.
    case modelNotBoundToAppKey
    /// Thrown when trying to send a config message to a Node of
    /// which the Device Key is not known.
    case noDeviceKey
    /// Error thrown when the Provisioner is trying to delete
    /// the last Network Key from the Node.
    case cannotDelete
    /// Error thrown when trying to send a message to an address
    /// for which another message is already being sent.
    case busy
    /// Thrown, when the acknowledgment has not been received until
    /// the time run out.
    case timeout
    /// Thrown when senting the message was cancelled.
    case cancelled
}

extension AccessError: LocalizedError {
    
    public var errorDescription: String? {
        switch self {
        case .invalidSource:         return NSLocalizedString("Local Provisioner does not have Unicast Address specified.", comment: "access")
        case .invalidElement:        return NSLocalizedString("Element does not belong to the local Node.", comment: "access")
        case .invalidTtl:            return NSLocalizedString("Invalid TTL", comment: "access")
        case .invalidDestination:    return NSLocalizedString("The destination address is invalid.", comment: "access")
        case .modelNotBoundToAppKey: return NSLocalizedString("No Application Key bound to the given Model.", comment: "access")
        case .noDeviceKey:           return NSLocalizedString("Unknown Device Key", comment: "access")
        case .cannotDelete:          return NSLocalizedString("Cannot delete the last Network Key.", comment: "access")
        case .busy:                  return NSLocalizedString("Unable to send a message to specified address. Another transfer in progress.", comment: "access")
        case .timeout:               return NSLocalizedString("Request timed out.", comment: "access")
        case .cancelled:             return NSLocalizedString("Message cancelled.", comment: "access")
        }
    }
    
}
