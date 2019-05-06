//
//  UnprovisionedDevice.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 02/05/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import CoreBluetooth

public protocol UnprovisionedDeviceDelegate: class {
    /// Callback called when the Link Establishment procedure has
    /// been completed.
    ///
    /// - parameter unprovisionedDevice: The device that the Link has
    ///                                  been opened to.
    func linkDidExtablish(to unprovisionedDevice: UnprovisionedDevice)
    
    /// Callback called when the Link is no longer open.
    ///
    /// - parameter unprovisionedDevice: The device to which the Link has
    ///                                  been closed.
    /// - parameter error:               The reason of closing the Link, or `nil`
    ///                                  if disconnection was intended.
    func link(to unprovisionedDevice: UnprovisionedDevice, didClose error: Error?)
    
    /// Callback called when a packet has been received from the
    /// Unprovisioned Device.
    ///
    /// - parameter unprovisionedDevice: The source device of the received data.
    /// - parameter data:                The recieved data.
    func unprovisionedDevice(_ unprovisionedDevice: UnprovisionedDevice, didSendData data: Data)
}

public struct OobInformation: OptionSet {
    public let rawValue: UInt16
    
    static let other          = OobInformation(rawValue: 1 << 0)
    static let electornicURI  = OobInformation(rawValue: 1 << 1)
    static let qrCode         = OobInformation(rawValue: 1 << 2)
    static let barCode        = OobInformation(rawValue: 1 << 3)
    static let nfc            = OobInformation(rawValue: 1 << 4)
    static let number         = OobInformation(rawValue: 1 << 5)
    static let string         = OobInformation(rawValue: 1 << 6)
    static let onBox          = OobInformation(rawValue: 1 << 11)
    static let insideBox      = OobInformation(rawValue: 1 << 12)
    static let onPieceOfPaper = OobInformation(rawValue: 1 << 13)
    static let insideManual   = OobInformation(rawValue: 1 << 14)
    static let onDevice       = OobInformation(rawValue: 1 << 15)
    
    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }
}

public protocol UnprovisionedDevice: class {
    /// The device delegate will receive updates about the link state
    /// and data received.
    var delegate: UnprovisionedDeviceDelegate? { get set }
    /// Returns the human-readable name of the device.
    var name: String? { get }
    /// Returns the Mesh Beacon UUID of an Unprovisioned Device.
    var uuid: UUID { get }
    /// Information that points to out-of-band (OOB) information
    /// needed for provisioning.
    var oobInformation: OobInformation { get }
    
    /// This method opens a Link to the Unprovisioned Device.
    func openLink()
    
    /// This method closes the Link to the Unprovisioned Device.
    func closeLink()
    
    /// This method sends the given data to the Unprovisioned Device
    /// over the bearer. If the data length exceeds the MTU, it should
    /// be segmented before calling this method.
    ///
    /// - parameter data: The data to be sent to the Unprovisioned
    ///                   Device.
    func send(_ data: Data)
}

public extension Dictionary where Key == String, Value == Any {
    
    /// Returns the value under the Complete or Shortened Local Name
    /// from the advertising packet, or `nil` if such doesn't exist.
    var localName: String? {
        return self[CBAdvertisementDataLocalNameKey] as? String
    }
    
    /// Returns the Unprovisioned Device's UUID.
    /// This value is taken from the Service Data with Mesh Provisioning Service
    /// UUID. The first 16 bytes are the converted to CBUUID.
    ///
    /// - returns: The device CBUUID or `nil` if could not be parsed.
    var unprovisionedDeviceUUID: CBUUID? {
        if let serviceData = self[CBAdvertisementDataServiceDataKey] as? [CBUUID : Data],
           let data = serviceData[MeshProvisioningService.serviceUUID] {
            guard data.count == 18 else {
                return nil
            }
            
            return CBUUID(data: data.subdata(in: 0 ..< 16))
        }
        return nil
    }
    
    /// Returns the Unprovisioned Device's OOB information.
    /// This value is taken from the Service Data with Mesh Provisioning Service
    /// UUID. The last 2 bytes are parsed and returned as `OobInformation`.
    ///
    /// - returns: The device OOB information or `nil` if could not be parsed.
    var oobInformation: OobInformation? {
        if let serviceData = self[CBAdvertisementDataServiceDataKey] as? [CBUUID : Data],
            let data = serviceData[MeshProvisioningService.serviceUUID] {
            guard data.count == 18 else {
                return nil
            }
            
            let rawValue: UInt16 = data.convert(offset: 16)
            return OobInformation(rawValue: rawValue)
        }
        return nil
    }
    
}

public extension CBUUID {
    
    /// Converts teh CBUUID to foundation UUID.
    var uuid: UUID {
        return self.data.withUnsafeBytes { UUID(uuid: $0.load(as: uuid_t.self)) }
    }
    
}
