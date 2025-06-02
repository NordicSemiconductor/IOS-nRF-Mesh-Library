//
//  McuMgrBleTransport+CBPeripheralDelegate.swift
//  McuManager
//
//  Created by Dinesh Harjani on 4/5/22.
//

import Foundation
import CoreBluetooth
import OSLog

// MARK: - McuMgrBleTransport+CBPeripheralDelegate

extension McuMgrBleTransport: CBPeripheralDelegate {
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        // Check for error.
        guard error == nil else {
            connectionLock.open(error)
            return
        }
        
        let s = peripheral.services?
            .map({ $0.uuid.uuidString })
            .joined(separator: ", ")
            ?? "none"
        log(msg: "Services discovered: \(s)", atLevel: .verbose)
        
        // Get peripheral's services.
        guard let services = peripheral.services else {
            connectionLock.open(McuMgrBleTransportError.missingService)
            return
        }
        // Find the service matching the SMP service UUID.
        for service in services {
            if service.uuid == McuMgrBleTransportConstant.SMP_SERVICE {
                log(msg: "Discovering characteristics...", atLevel: .verbose)
                peripheral.discoverCharacteristics([McuMgrBleTransportConstant.SMP_CHARACTERISTIC],
                                                   for: service)
                return
            }
        }
        connectionLock.open(McuMgrBleTransportError.missingService)
    }
    
    public func peripheral(_ peripheral: CBPeripheral,
                           didDiscoverCharacteristicsFor service: CBService,
                           error: Error?) {
        // Check for error.
        guard error == nil else {
            connectionLock.open(error)
            return
        }
        
        let c = service.characteristics?
            .map({ $0.uuid.uuidString })
            .joined(separator: ", ")
            ?? "none"
        log(msg: "Characteristics discovered: \(c)", atLevel: .verbose)
        
        // Get service's characteristics.
        guard let characteristics = service.characteristics else {
            connectionLock.open(McuMgrBleTransportError.missingCharacteristic)
            return
        }
        // Find the characteristic matching the SMP characteristic UUID.
        for characteristic in characteristics {
            if characteristic.uuid == McuMgrBleTransportConstant.SMP_CHARACTERISTIC {
                // Set the characteristic notification if available.
                if characteristic.properties.contains(.notify) {
                    log(msg: "Enabling notifications...", atLevel: .verbose)
                    peripheral.setNotifyValue(true, for: characteristic)
                } else {
                    connectionLock.open(McuMgrBleTransportError.missingNotifyProperty)
                }
                return
            }
        }
        connectionLock.open(McuMgrBleTransportError.missingCharacteristic)
    }
    
    public func peripheral(_ peripheral: CBPeripheral,
                           didUpdateNotificationStateFor characteristic: CBCharacteristic,
                           error: Error?) {
        guard characteristic.uuid == McuMgrBleTransportConstant.SMP_CHARACTERISTIC else {
            return
        }
        // Check for error.
        guard error == nil else {
            connectionLock.open(error)
            return
        }
        
        log(msg: "Notifications enabled", atLevel: .verbose)
        
        // Set the SMP characteristic.
        smpCharacteristic = characteristic
        state = .connected
        notifyStateChanged(.connected)
        
        // The SMP Service and characteristic have now been discovered and set
        // up. Signal the dispatch semaphore to continue to send the request.
        connectionLock.open(key: McuMgrBleTransportKey.discoveringSmpCharacteristic.rawValue)
    }
    
    public func peripheral(_ peripheral: CBPeripheral,
                           didUpdateValueFor characteristic: CBCharacteristic,
                           error: Error?) {
        guard characteristic.uuid == McuMgrBleTransportConstant.SMP_CHARACTERISTIC else {
            return
        }
        
        if let error = error {
            writeState.onError(error)
            return
        }
        
        // Assumption: CoreBluetooth is delivering all packets from the same sender,
        // in order.
        guard let data = characteristic.value else {
            writeState.onError(McuMgrTransportError.badResponse)
            return
        }
        
        // Check that we've received all the data for the Sequence Number of the
        // previous received Data.
        if let previousUpdateNotificationSequenceNumber = previousUpdateNotificationSequenceNumber,
           !writeState.isChunkComplete(for: previousUpdateNotificationSequenceNumber) {
            
            // Add Data to the previous Sequence Number.
            writeState.received(sequenceNumber: previousUpdateNotificationSequenceNumber, data: data)
            return
        }
        
        // If the Data is the first 'chunk', it will include the header.
        guard let sequenceNumber = data.readMcuMgrHeaderSequenceNumber() else {
            writeState.onError(McuMgrTransportError.badResponse)
            return
        }
        
        previousUpdateNotificationSequenceNumber = sequenceNumber
        writeState.received(sequenceNumber: sequenceNumber, data: data)
    }
    
    public func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        // Restart any paused writes due to Peripheral not being ready for more writes.
        writeState.sharedLock { [unowned self] in
            guard !pausedWrites.isEmpty else { return }
            for pausedWrite in pausedWrites {
                log(msg: "► [Seq: \(pausedWrite.sequenceNumber)] Resume (Peripheral Ready for Write Without Response)", atLevel: .debug)
                coordinatedWrite(of: pausedWrite.sequenceNumber, data: Array(pausedWrite.remaining), to: pausedWrite.peripheral, characteristic: pausedWrite.characteristic, callback: pausedWrite.callback)
            }
            pausedWrites.removeAll()
        }
    }
}
