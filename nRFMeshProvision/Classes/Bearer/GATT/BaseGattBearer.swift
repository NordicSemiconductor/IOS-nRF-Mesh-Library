//
//  BaseGattBearer.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 02/05/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import CoreBluetooth

open class BaseGattBearer<Service: MeshService>: NSObject, Bearer, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // MARK: - Properties
    
    private let centralManager   : CBCentralManager
    private let basePeripheral   : CBPeripheral
    
    public weak var delegate: BearerDelegate?
    
    // MARK: - Computed properties
    
    /// Returns `true` if the peripheral state is `.connected`.
    public var isConnected: Bool {
        return basePeripheral.state == .connected
    }
    
    // MARK: - Characteristic properties
    
    private var dataInCharacteristic:  CBCharacteristic?
    private var dataOutCharacteristic: CBCharacteristic?
    
    /// Data buffer used for segmentation.
    private var outgoingBuffer: Data?
    /// Data buffer used for reassembly.
    private var incomingBuffer: Data?
    
    // MARK: - Public API
    
    public init(to peripheral: CBPeripheral, using manager: CBCentralManager) {
        centralManager = manager
        basePeripheral = peripheral
        super.init()
        basePeripheral.delegate = self
    }
    
    open func open() {
        if basePeripheral.state == .disconnected {
            centralManager.delegate = self
            print("Connecting...")
            centralManager.connect(basePeripheral, options: nil)
        }
    }
    
    open func close() {
        if basePeripheral.state == .connected || basePeripheral.state == .connecting {
            print("Cancelling connection...")
            centralManager.cancelPeripheralConnection(basePeripheral)
        }
    }
    
    open func send(_ data: Data) {
        if let dataInCharacteristic = dataInCharacteristic {
            print("-> 0x\(data.hex)")
            basePeripheral.writeValue(data, for: dataInCharacteristic, type: .withoutResponse)
        }
    }
    
    // MARK: - Implementation
    
    /// Starts service discovery, only given Service.
    private func discoverServices() {
        print("Discovering services...")
        basePeripheral.delegate = self
        basePeripheral.discoverServices([Service.uuid])
    }
    
    /// Starts characteristic discovery for Data In and Data Out Characteristics.
    ///
    /// - parameter service: The service to look for the characteristics in.
    private func discoverCharacteristics(for service: CBService) {
        print("Discovering characteristrics...")
        basePeripheral.discoverCharacteristics([Service.dataInUuid, Service.dataOutUuid], for: service)
    }
    
    /// Enables notification for the given characteristic.
    ///
    /// - parameter characteristic: The characteristic to enable notifications for.
    private func enableNotifications(for characteristic: CBCharacteristic) {
        print("Enabling notifications...")
        basePeripheral.setNotifyValue(true, for: characteristic)
    }
    
    // MARK: - CBCentralManagerDelegate
    
    open func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            print("Central Manager state changed to \(central.state)")
            delegate?.bearer(self, didClose: BearerError.centralManagerNotPoweredOn)
        }
    }
    
    open func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if peripheral == basePeripheral {
            print("Connected")
            if let delegate = delegate as? GattBearerDelegate {
                delegate.bearerDidConnect(self)
            }
            discoverServices()
        }
    }
    
    open func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if peripheral == basePeripheral {
            if let error = error {
                print("Disconnected with error: \(error)")
                delegate?.bearer(self, didClose: error)
            } else {
                guard let dataOutCharacteristic = dataOutCharacteristic, let _ = dataInCharacteristic,
                    dataOutCharacteristic.properties.contains(.notify) else {
                        print("Disconnected. Provisioning service not found")
                        delegate?.bearer(self, didClose: GattBearerError.deviceNotSupported)
                        return
                }
                print("Disconnected")
                delegate?.bearer(self, didClose: nil)
            }
        }
    }
    
    // MARK: - CBPeripheralDelegate
    
    open func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                if Service.matches(service) {
                    print("Service found")
                    discoverCharacteristics(for: service)
                    return
                }
            }
        }
        // Required service not found.
        print("Device not supported")
        close()
    }
    
    open func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        // Look for required characteristics.
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.isMeshProxyDataInCharacteristic {
                    print("Data In characteristic found")
                    dataInCharacteristic = characteristic
                } else if characteristic.isMeshProxyDataOutCharacteristic {
                    print("Data Out characteristic found")
                    dataOutCharacteristic = characteristic
                }
            }
        }
        
        // Ensure all required characteristics were found.
        guard let dataOutCharacteristic = dataOutCharacteristic, let _ = dataInCharacteristic,
            dataOutCharacteristic.properties.contains(.notify) else {
                print("Device not supported")
                close()
                return
        }
        
        if let delegate = delegate as? GattBearerDelegate {
            delegate.bearerDidDiscoverServices(self)
        }
        enableNotifications(for: dataOutCharacteristic)
    }
    
    open func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic == dataOutCharacteristic, characteristic.isNotifying else {
            return
        }
        
        print("Data Out notifications enabled")
        print("GATT Bearer open and ready")
        delegate?.bearerDidOpen(self)
    }
    
    open func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic == dataOutCharacteristic, let data = characteristic.value else {
            return
        }
        print("<- 0x\(data.hex)")
        delegate?.bearer(self, didDeliverData: data)
    }
    
    open func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        // Data is sent without response.
        // This method will not be called.
    }
    
}
