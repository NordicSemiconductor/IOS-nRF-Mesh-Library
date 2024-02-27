/*
* Copyright (c) 2023, Nordic Semiconductor
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

/// A Remote Provisioning Scan Report message is an unacknowledged message used by
/// the Remote Provisioning Server to report the scanned Device UUID of an
/// unprovisioned device.
///
/// Based on the Remote Provisioning Scan Reports received from multiple
/// Remote Provisioning Servers, the Remote Provisioning Client can select the most
/// suitable Remote Provisioning Server to execute the Extended Scan procedure
/// and/or to provision the unprovisioned device.
public struct RemoteProvisioningScanReport: UnacknowledgedRemoteProvisioningMessage {
    public static let opCode: UInt32 = 0x8055
    /// Signed integer that is interpreted as an indication of received signal strength
    /// measured in dBm.
    public let rssi: NSNumber
    /// Device UUID.
    public let uuid: UUID
    /// Out-Of-Band Information of the unprovisioned device.
    public let oobInformation: OobInformation
    /// If present, the URI Hash field identifies the URI Hash of the unprovisioned device.
    ///
    /// The URI Hash is calculated as:
    /// ```swift
    /// s1(URI Data)[0-3]
    /// ```
    /// The URI Data is a buffer containing the URI data type, as defined in Core Bluetooth
    /// Supplement (CSS) Version 6 or later.
    public let uriHash: Data?
    
    public var parameters: Data? {
        return Data([UInt8(truncating: rssi)]) + uuid.data + oobInformation.rawValue.bigEndian + uriHash
    }
    
    /// To ensure delivery of the message it should be sent as a segmented message
    /// even if the PDU contains less than 11 bytes.
    public var isSegmented: Bool = true
    
    /// Creates a Remote Provisioning Scan Report message.
    ///
    /// - parameters:
    ///   - rssi: The RSSI of the scanned packet.
    ///   - uuid: Device UUID.
    ///   - oobInformation: OOB Information of the unprovisioned device.
    ///   - uriHash: Optional URI Hash information.
    public init(rssi: NSNumber, uuid: UUID, oobInformation: OobInformation, uriHash: Data? = nil) {
        self.rssi = rssi
        self.uuid = uuid
        self.oobInformation = oobInformation
        self.uriHash = uriHash
    }
    
    /// Creates a Remote Provisioning Scan Report message from the advertisement data.
    ///
    /// - parameters:
    ///   - rssi: The RSSI of the scanned packet.
    ///   - advertisementData: Received advertising data.
    public init?(rssi: NSNumber, advertisementData: [String : Any]) {
        guard let uuid = advertisementData.unprovisionedDeviceUUID,
              let oobInformation = advertisementData.oobInformation else {
            return nil
        }
        self.rssi = rssi
        self.uuid = uuid
        self.oobInformation = oobInformation
        self.uriHash = advertisementData.uriHash
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 19 || parameters.count == 23 else {
            return nil
        }
        rssi = NSNumber(value: Int8(bitPattern: parameters[0]))
        guard let uuid = UUID(data: parameters.subdata(in: 1 ..< 17)) else {
            return nil
        }
        self.uuid = uuid
        oobInformation = OobInformation(data: parameters, offset: 17)
        if parameters.count == 23 {
            uriHash = parameters.subdata(in: 19..<23)
        } else {
            uriHash = nil
        }
    }
}
