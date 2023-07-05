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

/// Set of errors that may be thrown from the bearer.
public enum BearerError: Error {
    /// Thrown when the Central Manager is not in ON state.
    case centralManagerNotPoweredOn
    /// Thrown when the given PDU type is not supported
    /// by the Bearer.
    case pduTypeNotSupported
    /// Thrown when the Bearer is not ready to send data.
    case bearerClosed
    /// Thrown when the Bearer is busy and cannot send new message at that moment.
    case busy
}

extension BearerError: LocalizedError {
    
    public var errorDescription: String? {
        switch self {
        case .centralManagerNotPoweredOn: return NSLocalizedString("Central Manager not powered on.", comment: "bearer")
        case .pduTypeNotSupported:        return NSLocalizedString("PDU type not supported.", comment: "bearer")
        case .bearerClosed:               return NSLocalizedString("The bearer is closed.", comment: "bearer")
        case .busy:                       return NSLocalizedString("The bearer is busy", comment: "bearer")
        }
    }
    
}
