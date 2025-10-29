//
//  McuMgrBleTransport+CBCentralManagerDelegate.swift
//  McuManager
//
//  Created by Dinesh Harjani on 4/5/22.
//

import Foundation
import CoreBluetooth

// MARK: - McuMgrBleTransport+CBCentralManagerDelegate

extension McuMgrBleTransport: CBCentralManagerDelegate {
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            if let peripheral = centralManager
                .retrievePeripherals(withIdentifiers: [identifier])
                .first {
                self.peripheral = peripheral
                connectionLock.open(key: McuMgrBleTransportKey.awaitingCentralManager.rawValue)
            } else {
                connectionLock.open(McuMgrBleTransportError.centralManagerNotReady)
            }
        default:
            connectionLock.open(McuMgrBleTransportError.centralManagerNotReady)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard self.identifier == peripheral.identifier else { return }
        
        log(msg: "Peripheral connected", atLevel: .info)
        state = .initializing
        previousUpdateNotificationSequenceNumber = nil
        log(msg: "Discovering services...", atLevel: .verbose)
        peripheral.delegate = self
        peripheral.discoverServices([configuration.serviceUUID])
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        guard self.identifier == peripheral.identifier else {
            return
        }
        log(msg: "Peripheral disconnected", atLevel: .info)
        peripheral.delegate = nil
        smpCharacteristic = nil
        connectionLock.open(McuMgrTransportError.disconnected)
        state = .disconnected
        notifyStateChanged(.disconnected)
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        guard self.identifier == peripheral.identifier else {
            return
        }
        log(msg: "Peripheral failed to connect", atLevel: .warning)
        connectionLock.open(McuMgrTransportError.connectionFailed)
    }
}
