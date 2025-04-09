/*
* Copyright (c) 2025, Nordic Semiconductor
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

/// The Firmware Distribution Firmware Status message is an unacknowledged message sent by
/// a Firmware Distribution Server to report the status of an operation on a stored firmware image.
///
/// A Firmware Distribution Firmware Status message is sent in response to any of:
/// * ``FirmwareDistributionFirmwareGet`` message,
/// * ``FirmwareDistributionFirmwareGetByIndex`` message,
/// * ``FirmwareDistributionFirmwareDelete`` message,
/// * ``FirmwareDistributionFirmwareDeleteAll`` message.
public struct FirmwareDistributionFirmwareStatus: StaticMeshResponse {
    public static let opCode: UInt32 = 0x8327
    
    /// Status for the requesting message.
    public let status: FirmwareDistributionMessageStatus
    /// The number of firmware images stored on the Firmware Distribution Server.
    ///
    /// This field is `nil` if the requested firmware image was not found or deleted.
    public let entryCount: UInt16
    /// Index of the firmware image in the Firmware Images List state.
    public let imageIndex: UInt16?
    /// Identifies associated firmware image.
    ///
    /// This field is `nil` if the firmware wasn't found, or the Status message is a response
    /// for ``FirmwareDistributionFirmwareDeleteAll`` message.
    public let firmwareId: FirmwareId?
    
    public var parameters: Data? {
        var data = Data([status.rawValue]) + entryCount + (imageIndex ?? 0xFFFF)
        if let firmwareId = firmwareId {
            data += firmwareId.companyIdentifier
            data += firmwareId.version
        }
        return data
    }
    
    /// Creates the Firmware Distribution Firmware Status message.
    ///
    /// - parameters:
    ///   - request: The ``FirmwareDistributionFirmwareGet`` message that was received.
    ///   - firmwareImageList: The list of firmware images stored on the Firmware Distribution Server.
    public init(responseTo request: FirmwareDistributionFirmwareGet,
                with firmwareImageList: [FirmwareId]) {
        self.status = .success
        self.entryCount = UInt16(firmwareImageList.count)
        if let index = firmwareImageList.firstIndex(where: { $0 == request.firmwareId }) {
            self.imageIndex = UInt16(index)
            self.firmwareId = request.firmwareId
        } else {
            self.imageIndex = nil
            self.firmwareId = nil
        }
    }
    
    /// Creates the Firmware Distribution Firmware Status message.
    ///
    /// - parameters:
    ///   - request: The ``FirmwareDistributionFirmwareGetByIndex`` message that was received.
    ///   - firmwareImageList: The list of firmware images stored on the Firmware Distribution Server.
    public init(responseTo request: FirmwareDistributionFirmwareGetByIndex,
                with firmwareImageList: [FirmwareId]) {
        self.status = .success
        self.entryCount = UInt16(firmwareImageList.count)
        self.imageIndex = request.imageIndex
        if firmwareImageList.count > Int(request.imageIndex) {
            self.firmwareId = firmwareImageList[Int(request.imageIndex)]
        } else {
            self.firmwareId = nil
        }
    }
    
    /// Creates the Firmware Distribution Firmware Status message.
    ///
    /// - important: The `firmwareImageList` should NOT contain the deleted image, that
    ///              means that the delete operation should be performed prior to creating this message.
    ///
    /// If the Firmware Image List did not contain the image to delete, the return status should
    /// be equal to the situation when such entry was found and deleted.
    ///
    /// - parameters:
    ///   - request: The ``FirmwareDistributionFirmwareDelete`` message that was received.
    ///   - firmwareImageList: The list of firmware images stored on the Firmware Distribution Server
    ///                        with the given image removed.
    public init(responseTo request: FirmwareDistributionFirmwareDelete,
                with firmwareImageList: [FirmwareId]) {
        self.status = .success
        self.entryCount = UInt16(firmwareImageList.count)
        self.imageIndex = nil
        self.firmwareId = request.firmwareId
    }
    
    /// Creates the Firmware Distribution Firmware Status message.
    ///
    /// - important: The `firmwareImageList` should be cleared prior to creating this message.
    ///
    /// If the Firmware Image List was already empty, the return status should
    /// be equal to the situation when at least one entry was found and deleted.
    ///
    /// - parameter request: The ``FirmwareDistributionFirmwareDeleteAll`` message that was received.
    public init(responseTo request: FirmwareDistributionFirmwareDeleteAll) {
        self.status = .success
        self.entryCount = 0
        self.imageIndex = nil
        self.firmwareId = nil
    }
    
    /// Creates the Firmware Distribution Firmware Status message.
    ///
    /// - important: The `firmwareImageList` should be cleared prior to creating this message.
    ///
    /// If the Firmware Image List was already empty, the return status should
    /// be equal to the situation when at least one entry was found and deleted.
    ///
    /// - parameters:
    ///   - status: The status of processing the request.
    ///   - firmwareImageList: The list of firmware images stored on the Firmware Distribution Server
    ///                        with the given image removed.
    public init(report status: FirmwareDistributionMessageStatus,
                with firmwareImageList: [FirmwareId]) {
        self.status = status
        self.entryCount = UInt16(firmwareImageList.count)
        self.imageIndex = nil
        self.firmwareId = nil
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 5 || parameters.count >= 7 else {
            return nil
        }
        guard let status = FirmwareDistributionMessageStatus(rawValue: parameters[0]) else {
            return nil
        }
        self.status = status
        self.entryCount = parameters.read(fromOffset: 1)
        
        // Index Not Found is encoded as 0xFFFF.
        let imageIndex: UInt16 = parameters.read(fromOffset: 3)
        self.imageIndex = imageIndex == 0xFFFF ? nil : imageIndex
        
        if parameters.count == 5 {
            self.firmwareId = nil
        } else {
            let companyIdentifier: UInt16 = parameters.read(fromOffset: 5)
            if parameters.count == 7 {
                self.firmwareId = FirmwareId(companyIdentifier: companyIdentifier, version: Data())
            } else {
                let version = parameters.subdata(in: 7..<parameters.count)
                self.firmwareId = FirmwareId(companyIdentifier: companyIdentifier, version: version)
            }
        }
    }
}
