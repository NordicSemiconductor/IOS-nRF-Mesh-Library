//
//  BaseGattProxyBearer.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 02/05/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import CoreBluetooth

open class BaseGattProxyBearer<Service: MeshService>: NSObject, Bearer, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // MARK: - Properties
    
    public weak var delegate: BearerDelegate?
    
    private let centralManager   : CBCentralManager
    private let basePeripheral   : CBPeripheral
    
    /// The protocol used for segmentation and reassembly.
    private let protocolHandler: ProxyProtocolHandler
    private var queue: [Data] = []
    private var rssiTimer: Timer?
    private var rssiInterval: TimeInterval?
    
    /// The last read RSSI value. The first RSSI is read just
    /// after enabling notifications.
    /// If an interval was set in the Bearer constructor, the RSSI
    /// will be updated every given number of seconds.
    public var lastRSSI: NSNumber?
    
    // MARK: - Computed properties
    
    public var isOpen: Bool {
        return basePeripheral.state == .connected
    }
    
    public var supportedMessageTypes: MessageTypes {
        return [.networkPdu, .meshBeacon, .proxyConfiguration, .provisioningPdu]
    }
    
    // MARK: - Characteristic properties
    
    private var dataInCharacteristic:  CBCharacteristic?
    private var dataOutCharacteristic: CBCharacteristic?
    
    // MARK: - Public API
    
    /// Creates the Gatt Proxy Bearer object. This object is not required to be
    /// used with nRF Mesh Provisioning library. Bearers are separate from the
    /// mesh networking part and the data must be passed to and from by the
    /// application.
    ///
    /// - parameters:
    ///   - peripheral: The CBPeripheral poiting a Bluetooth LE device with
    ///                 Bluetooth Mesh GATT service (Provisioning or Proxy Service).
    ///   - manager:    The CBCentralManager used to obtain the peripheral.
    ///   - interval:   The time interval (in seconds) for RSSI updates. Set `nil`
    ///                 (default) to disable RSSI polling. RSSI updates may be useful to
    ///                 select the closes device when an app allows to connect to
    ///                 multiple proxies at a time.
    public init(to peripheral: CBPeripheral, using manager: CBCentralManager, withRssiUpdateInterval interval: TimeInterval? = nil) {
        centralManager  = manager
        basePeripheral  = peripheral
        protocolHandler = ProxyProtocolHandler()
        rssiInterval = interval
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
        rssiTimer?.invalidate()
        rssiTimer = nil
    }
    
    open func send(_ data: Data, ofType type: MessageType) throws {
        guard supports(type) else {
            throw BearerError.messageTypeNotSupported
        }
        guard isOpen else {
            throw BearerError.bearerClosed
        }
        guard let dataInCharacteristic = dataInCharacteristic else {
            throw GattBearerError.deviceNotSupported
        }
        
        let mtu = basePeripheral.maximumWriteValueLength(for: .withoutResponse)
        let packets = protocolHandler.segment(data, ofType: type, toMtu: mtu)
        
        // On iOS 11+ only the first packet is sent here. When the peripheral is ready
        // to send more data, a `peripheralIsReady(toSendWriteWithoutResponse:)` callback
        // will be called, which will send the next packet.
        if #available(iOS 11.0, *) {
            let queueWasEmpty = queue.isEmpty
            queue.append(contentsOf: packets)
            
            // Don't look at `basePeripheral.canSendWriteWithoutResponse`. If often returns
            // `false` even when nothing was sent before and no callback is called afterwards.
            // Just assume, that the first packet can always be sent.
            if queueWasEmpty {
                let packet = queue.remove(at: 0)
                print("-> 0x\(packet.hex)")
                basePeripheral.writeValue(packet, for: dataInCharacteristic, type: .withoutResponse)
            }
        } else {
            // For iOS versions before 11, the data must be just sent in a loop.
            // This may not work if there is more than ~20 packets to be sent, as a
            // buffer may overflow. The solution would be to add some delays, but
            // let's hope it will work as is. For now.
            // TODO: Handle very long packets on iOS 9 and 10.
            for packet in packets {
                print("-> 0x\(packet.hex)")
                basePeripheral.writeValue(packet, for: dataInCharacteristic, type: .withoutResponse)
            }
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
            
            rssiTimer?.invalidate()
            rssiTimer = nil
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
            rssiTimer?.invalidate()
            rssiTimer = nil
            
            if let error = error {
                print("Disconnected with error: \(error)")
                delegate?.bearer(self, didClose: error)
            } else {
                guard let dataOutCharacteristic = dataOutCharacteristic, let _ = dataInCharacteristic,
                    dataOutCharacteristic.properties.contains(.notify) else {
                        print("Disconnected with error: Device not supported")
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
                if Service.dataInUuid == characteristic.uuid {
                    print("Data In characteristic found")
                    dataInCharacteristic = characteristic
                } else if Service.dataOutUuid == characteristic.uuid {
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
        basePeripheral.readRSSI()
        
        if let rssiInterval = rssiInterval {
            rssiTimer = Timer.scheduledTimer(withTimeInterval: rssiInterval, repeats: true) { _ in
                self.basePeripheral.readRSSI()
            }
        }
    }
    
    open func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic == dataOutCharacteristic, let data = characteristic.value else {
            return
        }
        print("<- 0x\(data.hex)")
        if let message = protocolHandler.reassemble(data) {
            delegate?.bearer(self, didDeliverData: message.data, ofType: message.messageType)
        }
    }
    
    open func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        // Data is sent without response.
        // This method will not be called.
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        lastRSSI = RSSI
        if let delegate = delegate as? GattBearerDelegate {
            delegate.bearer(self, didReadRSSI: RSSI)
        }
    }
    
    // This method is available only on iOS 11+.
    public func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        guard !queue.isEmpty else {
            return
        }
        
        let packet = queue.remove(at: 0)
        print("-> 0x\(packet.hex)")
        peripheral.writeValue(packet, for: dataInCharacteristic!, type: .withoutResponse)
    }
    
}
