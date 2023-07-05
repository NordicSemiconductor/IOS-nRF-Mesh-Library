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
import CoreBluetooth

/// A Remote Provisioning Extended Scan Report message is an unacknowledged message
/// used by the Remote Provisioning Server to report the advertising data requested
/// by the client in a Remote Provisioning Extended Scan Start message.
public struct RemoteProvisioningExtendedScanReport: RemoteProvisioningStatusMessage {
    public static let opCode: UInt32 = 0x8057
    
    public let status: RemoteProvisioningMessageStatus
    /// Device UUID.
    public let uuid: UUID
    /// Out-Of-Band Information of the unprovisioned device.
    public let oobInformation: OobInformation?
    /// Concatenated list of AD Structures that match the AD Types requested by the
    /// client in the ``RemoteProvisioningExtendedScanStart/adTypeFilter`` field.
    public let adStructures: [AdStructure]?
    
    public var parameters: Data? {
        var data = Data([status.rawValue]) + uuid.data
        // If OOBInformation field is present, the AdStructures field is optional;
        // otherwise, AdStructures field shall not be present.
        if let oobInformation = oobInformation {
            data += oobInformation.rawValue.bigEndian
            if let adStructures = adStructures {
                data += adStructures.reduce(Data()) { result, next in result + next.type + next.value }
            }
        }
        return data
    }
    
    /// To ensure delivery of the message it should be sent as a segmented message
    /// even if the PDU contains less than 11 bytes.
    public var isSegmented: Bool = true
    
    // TODO: initializers
    
    public init?(parameters: Data) {
        guard parameters.count == 17 || parameters.count == 19 || parameters.count >= 21 else {
            return nil
        }
        guard let status = RemoteProvisioningMessageStatus(rawValue: parameters[0]) else {
            return nil
        }
        self.status = status
        guard let uuid = UUID(data: parameters.subdata(in: 1..<17)) else {
            return nil
        }
        self.uuid = uuid
        if parameters.count > 17 {
            self.oobInformation = OobInformation(data: parameters, offset: 17)
            
            if parameters.count > 19 {
                // Parse Ad Structures
                var ads: [AdStructure] = []
                var i = 19
                while i < parameters.count {
                    let len = Int(parameters[i])
                    guard parameters.count >= i + len else {
                        return nil
                    }
                    let type = parameters[i + 1]
                    let value = parameters.subdata(in: i + 2..<i + 1 + len)
                    ads.append(AdStructure(type: type, value: value))
                    i += 1 + len
                }
                self.adStructures = ads
            } else {
                self.adStructures = nil
            }
        } else {
            self.oobInformation = nil
            self.adStructures = nil
        }
    }
}

// MARK: - Helper methods

public extension RemoteProvisioningExtendedScanReport {
    
    /// Complete or Shortened Local Name returned in the Extended Scan Report.
    var localName: String? {
        return adStructures?
            .first { $0.adType == AdType.localName }
            .flatMap { String(data: $0.value, encoding: .utf8) }
    }
    
    var txPowerLevel: Int? {
        return adStructures?
            .first { $0.adType == AdType.localName }
            .map { Int($0.value[0]) }
    }
    
    /// URI Data returned in the Extended Scan Report.
    var uri: String? {
        return adStructures?
            .first { $0.adType == AdType.uri }
            .flatMap { String(data: $0.value, encoding: .utf8) }
    }
    
    /// Complete list of Service UUIDs.
    var serviceUUIDs: [CBUUID]? {
        guard let adStructures = adStructures else {
            return nil
        }
        return adStructures
            .filter {
                $0.adType == AdType.completeListOf16­bitServiceClassUUIDs ||
                $0.adType == AdType.completeListOf32bitServiceClassUUIDs ||
                $0.adType == AdType.completeListOf128bitServiceClassUUIDs
            }
            .notEmpty?
            .flatMap { $0.value.uuids(ofType: $0.adType!) }
    }
    
    /// Complete list of Service UUIDs.
    var serviceSolicitationUUIDs: [CBUUID]? {
        guard let adStructures = adStructures else {
            return nil
        }
        return adStructures
            .filter {
                $0.adType == AdType.listOf16­bitServiceSolicitationUUIDs ||
                $0.adType == AdType.listOf32bitServiceSolicitationUUIDs ||
                $0.adType == AdType.listOf128bitServiceSolicitationUUIDs
            }
            .notEmpty?
            .flatMap { $0.value.uuids(ofType: $0.adType!) }
    }
    
    /// Dictionary of Service Data.
    ///
    /// The Keys in the dictionary are Service UUIDs and Values are corresponding data.
    var serviceData: [CBUUID : Data]? {
        return adStructures?
            .filter {
                $0.adType == AdType.serviceData16bitUUID ||
                $0.adType == AdType.serviceData32bitUUID ||
                $0.adType == AdType.serviceData128bitUUID
            }
            .notEmpty?
            .reduce([CBUUID : Data]()) { result, next in
                let uuid = next.value.uuid(ofType: next.adType!)
                let value = next.value.suffix(from: next.adType!.length)
                // Only the first Serice Data for a UUID is chosen.
                return result.merging([uuid : value], uniquingKeysWith: { current, _ in current })
            }
    }
    
}

private extension Data {
    
    func uuid(ofType adType: AdType) -> CBUUID {
        return CBUUID(dataLittleEndian: subdata(in: 0..<adType.length))
    }
    
    func uuids(ofType adType: AdType) -> [CBUUID] {
        return chunked(into: adType.length)
            .map { CBUUID(dataLittleEndian: $0) }
    }
    
    func chunked(into size: Int) -> [Data] {
        return stride(from: 0, to: count, by: size)
            .map { subdata(in: $0 ..< $0 + size) }
    }
    
}

private extension Array {
    
    var notEmpty: Self? {
        return isEmpty ? nil : self
    }
    
}
