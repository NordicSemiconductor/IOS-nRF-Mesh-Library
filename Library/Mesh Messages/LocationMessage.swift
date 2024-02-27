/*
* Copyright (c) 2022, Nordic Semiconductor
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

/// A base protocol for location status messages.
public protocol LocationStatusMessage: MeshMessage {
    /// Latitude
    var latitude: Latitude { get }
    /// Longitude
    var longitude: Longitude { get }
    /// Altitude
    var altitude: Altitude { get }
}

/// The representation of latitide coordinate.
public enum Latitude {
    init(raw parameter: Int32) {
        if (parameter == -1) {
            self = .notConfigured
        } else {
            self = .coordinate(parameter)
        }
    }

    /// Creates an instance of a Latitude object.
    ///
    /// - parameter position: The WGS84 coordinate longitude. Valid values are between -180 and 180.
    init?(position: Double) {
        if (position < -90 || position > 90) {
            return nil
        }
        
        self = .coordinate(max(Int32.min + 1, min(Int32.max - 1, Int32(floor((position / 90) * (pow(2, 31) - 1))))))
    }
    
    /// Encodes the Latitude object to Int32.
    func encode() -> Int32 {
        switch self {
        case .coordinate(let parameter):
            return parameter
        case .notConfigured:
            return -1
        }
    }

    func position() -> Double? {
        switch self {
        case .coordinate(let parameter):
            return Double(parameter) / (pow(2, 31) - 1) * 90
        case .notConfigured:
            return nil
        }
    }
    
    /// A specific latitude coordinate.
    case coordinate(Int32)
    /// Latitude is not configured.
    case notConfigured
}

/// The representation of longitude coordinate.
public enum Longitude {
    init(raw parameter: Int32) {
        if (parameter == -1) {
            self = .notConfigured
        } else {
            self = .coordinate(parameter)
        }
    }

    /// Creates an instance of a Longitude object.
    ///
    /// - parameter position: The WGS84 coordinate longitude. Valid values are between -180 and 180.
    init?(position: Double) {
        if (position < -180 || position > 180) {
            return nil
        }

        self = .coordinate(max(Int32.min + 1, min(Int32.max - 1, Int32(floor((position / 180) * (pow(2, 31) - 1))))))
    }
    
    /// Encodes the Longitude object to Int32.
    func encode() -> Int32 {
        switch self {
        case .coordinate(let parameter):
            return parameter
        case .notConfigured:
            return -1
        }
    }

    func position() -> Double? {
        switch self {
        case .coordinate(let parameter):
            return Double(parameter) / (pow(2, 31) - 1) * 180
        case .notConfigured:
            return nil
        }
    }
    
    /// A specific longitude coordinate.
    case coordinate(Int32)
    /// Longitude is not configured.
    case notConfigured
}

/// The representation of altitude above see level.
public enum Altitude : Equatable {
    init(raw parameter: Int16) {
        if (parameter == 0x7FFF) {
            self = .notConfigured
        } else if (parameter == 0x7FFE) {
            self = .tooLarge
        } else {
            self = .altitude(parameter)
        }
    }
    
    /// Encodes the Longitude object to Int16.
    ///
    /// Values 0x7FFE and 0x7FFF have special meaning.
    func encode() -> Int16 {
        switch self {
        case .altitude(let position):
            return position
        case .tooLarge:
            return 0x7FFE
        case .notConfigured:
            return 0x7FFF
        }
    }

    /// The altitude, or `nil` if not unknown.
    func altitude() -> Int16? {
        switch self {
        case .altitude(let parameter):
            return parameter
        case .tooLarge:
            return nil
        case .notConfigured:
            return nil
        }
    }
    
    /// A specific altitude.
    case altitude(Int16)
    /// The altitude is too large to fit Int16.
    case tooLarge
    /// The altitude is not configured.
    case notConfigured
}
