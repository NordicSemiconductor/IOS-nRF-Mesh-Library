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

/// A class representing an unprovisioned device.
public class UnprovisionedDevice: NSObject {
    /// Returns the human-readable name of the device.
    public var name: String?
    /// Returns the Mesh Beacon UUID of an Unprovisioned Device.
    public let uuid: UUID
    /// Information that points to out-of-band (OOB) information
    /// needed for provisioning.
    public let oobInformation: OobInformation
    
    /// Creates a basic Unprovisioned Device object.
    ///
    /// - parameter name: The optional name of the device.
    /// - parameter uuid: The UUID of the Unprovisioned Device.
    /// - parameter oobInformation: The information about OOB data.
    public init(name: String? = nil, uuid: UUID, oobInformation: OobInformation = OobInformation(rawValue: 0)) {
        self.name = name
        self.uuid = uuid
        self.oobInformation = oobInformation
    }
    
    /// Creates the Unprovisioned Device object based on the advertisement
    /// data. The Mesh UUID and OOB Information must be present in the
    /// advertisement data, otherwise `nil` is returned.
    ///
    /// - parameter advertisementData: The advertisement data deceived
    ///                                from the device during scanning.
    public init?(advertisementData: [String : Any]) {
        // An Unprovisioned Device must advertise with UUID and OOB Information.
        guard let uuid  = advertisementData.unprovisionedDeviceUUID,
              let oobInfo = advertisementData.oobInformation else {
                return nil
        }
        self.name = advertisementData.localName
        self.uuid = uuid
        self.oobInformation = oobInfo
    }
    
    /// Creates the Unprovisioned Device object based on the Remote
    /// Provisioning Scan Report message.
    ///
    /// - parameter scanReport: The scan report received during Remote Scan
    ///                         operation.
    public init(scanReport: RemoteProvisioningScanReport) {
        self.uuid = scanReport.uuid
        self.oobInformation = scanReport.oobInformation
    }
    
}
