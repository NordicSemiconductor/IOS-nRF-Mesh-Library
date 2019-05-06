//
//  UnprovisionedDevice.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 02/05/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import CoreBluetooth

open class UnprovisionedProxyDevice: NSObject, UnprovisionedDevice {
    
    // MARK: - Properties
    
    private let centralManager   : CBCentralManager
    private let basePeripheral   : CBPeripheral
    
    /// The device name, parsed from the advertising data.
    /// This may be different then the name in CBPeripheral
    /// as it is not cached.
    public private(set) var name : String?
    /// The Unprovisioned Device mesh UUID, obtained from the
    /// advertising packet.
    public private(set) var uuid : UUID
    /// The out-of-band (OOB) information from the advertising
    /// packet.
    public private(set) var oobInformation: OobInformation
    
    /// The delegate will receive callback whenever the link to the
    /// Unprovisioned Device will change or when any data will be
    /// received from this device.
    public var delegate: UnprovisionedDeviceDelegate?
    
    // MARK: - Computed properties
    
    /// Returns `true` if the peripheral state is `.connected`.
    public var isConnected: Bool {
        return basePeripheral.state == .connected
    }
    
    // MARK: - Characteristic properties
    
    private var dataInCharacteristic:  CBCharacteristic?
    private var dataOutCharacteristic: CBCharacteristic?
    
    // MARK: - Public API
    
    public init?(withPeripheral peripheral: CBPeripheral,
         advertisementData dictionary: [String : Any],
         using manager: CBCentralManager) {
        // Some validation. UUID and OOB Informatino are required in the advertising packet.
        guard let cbuuid = dictionary.unprovisionedDeviceUUID,
            let oob = dictionary.oobInformation else {
                return nil
        }
        centralManager = manager
        basePeripheral = peripheral
        name = dictionary.localName
        uuid = cbuuid.uuid
        oobInformation = oob
        super.init()
        basePeripheral.delegate = self
    }
    
    open func openLink() {
        if basePeripheral.state == .disconnected {
            centralManager.delegate = self
            print("Connecting to Unprovisioned Device...")
            centralManager.connect(basePeripheral, options: nil)
        }
    }
    
    open func closeLink() {
        if basePeripheral.state == .connected || basePeripheral.state == .connecting {
            print("Cancelling connection...")
            centralManager.cancelPeripheralConnection(basePeripheral)
        }
    }
    
    open func send(_ data: Data) {
        if let dataInCharacteristic = dataInCharacteristic {
            basePeripheral.writeValue(data, for: dataInCharacteristic, type: .withoutResponse)
        }
    }
    
    // MARK: - Implementation
    
    /// Starts service discovery, only for Mesh Provisioning Service.
    private func discoverServices() {
        print("Discovering Provisioning Service service...")
        basePeripheral.delegate = self
        basePeripheral.discoverServices([MeshProvisioningService.serviceUUID])
    }
    
    /// Starts characteristic discovery for Data In and Data Out Characteristics.
    ///
    /// - parameter service: The service to look for the characteristics in.
    private func discoverCharacteristics(for service: CBService) {
        print("Discovering characteristrics...")
        basePeripheral.discoverCharacteristics(
            [MeshProvisioningService.dataInUUID, MeshProvisioningService.dataOutUUID],
            for: service)
    }
    
    /// Enables notification for the given characteristic.
    ///
    /// - parameter characteristic: The characteristic to enable notifications for.
    private func enableNotifications(for characteristic: CBCharacteristic) {
        print("Enabling notifications for characteristic...")
        basePeripheral.setNotifyValue(true, for: characteristic)
    }
    
    // MARK: - NSObject protocols
    
    override open func isEqual(_ object: Any?) -> Bool {
        switch object {
        case let device as UnprovisionedProxyDevice:
            return device.basePeripheral.identifier == basePeripheral.identifier
        case let device as UnprovisionedDevice:
            return device.uuid == uuid
        case let peripheral as CBPeripheral:
            return peripheral.identifier == basePeripheral.identifier
        default:
            return false
        }
    }
    
}
// MARK: - CBCentralManagerDelegate

extension UnprovisionedProxyDevice: CBCentralManagerDelegate {
    
    open func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            print("Central Manager state changed to \(central.state)")
            delegate?.link(to: self, didClose: GattError.centralManagerNotPoweredOn)
        }
    }
    
    open func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if peripheral == basePeripheral {
            print("Connected to UnprovisionedDevice")
            discoverServices()
        }
    }
    
    open func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if peripheral == basePeripheral {
            print("UnprovisionedDevice disconnected")
            guard let dataOutCharacteristic = dataOutCharacteristic, let _ = dataInCharacteristic,
                dataOutCharacteristic.properties.contains(.notify) else {
                    delegate?.link(to: self, didClose: GattError.deviceNotSupported)
                    return
            }
            delegate?.link(to: self, didClose: nil)
        }
    }
    
}
    
// MARK: - CBPeripheralDelegate

extension UnprovisionedProxyDevice: CBPeripheralDelegate {
    
    open func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            closeLink()
            return
        }
        
        for service in services {
            if service.isMeshProvisioningService {
                print("Mesh Provisioning service found")
                discoverCharacteristics(for: service)
                return
            }
        }
    }
    
    open func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        // Look for required characteristics.
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.isMeshProvisioningDataInCharacteristic {
                    print("Data In characteristic found")
                    dataInCharacteristic = characteristic
                } else if characteristic.isMeshProvisioningDataOutCharacteristic {
                    print("Data Out characteristic found")
                    dataOutCharacteristic = characteristic
                }
            }
        }
        
        // Ensure all required characteristics were found.
        guard let dataOutCharacteristic = dataOutCharacteristic, let _ = dataInCharacteristic,
            dataOutCharacteristic.properties.contains(.notify) else {
                closeLink()
                return
        }
        
        enableNotifications(for: dataOutCharacteristic)
    }
    
    open func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
    }
    
    open func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        
    }
    
    open func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
    }
    
}
