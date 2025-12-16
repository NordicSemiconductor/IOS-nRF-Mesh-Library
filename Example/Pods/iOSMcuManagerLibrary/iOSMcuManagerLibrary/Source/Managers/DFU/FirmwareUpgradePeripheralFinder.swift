//
//  FirmwareUpgradePeripheralFinder.swift
//  iOSMcuManagerLibrary
//
//  Created by Dinesh Harjani on 1/12/25.
//

import Foundation
import CoreBluetooth

// MARK: - FirmwareUpgradePeripheralFinder

final class FirmwareUpgradePeripheralFinder: NSObject {
    
    private static let Timeout: TimeInterval = 15.0
    
    // MARK: Private Properties
    
    private weak var centralManager: CBCentralManager?
    
    typealias FindCallback = (Result<CBPeripheral, FirmwareUpgradeManagerPeripheralFinderError>) -> Void
    private var searchCallback: FindCallback?
    private var safeguardedDelegate: (any CBCentralManagerDelegate)?
    private var searchName: String
    
    // MARK: init
    
    init(_ centralManager: CBCentralManager, searchName: String) {
        self.centralManager = centralManager
        self.searchName = searchName
    }
    
    // MARK: API
    
    func find(with callback: @escaping FindCallback) {
        safeguardedDelegate = centralManager?.delegate
        searchCallback = callback
        centralManager?.delegate = self
        centralManager?.scanForPeripherals(withServices: nil, options: [
            CBAdvertisementDataLocalNameKey: searchName
        ])
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.Timeout) { [weak self] in
            guard let self, let centralManager, let safeguardedDelegate,
                                let searchCallback, centralManager.isScanning else { return }
            // If we're still alive and Central Manager has not stopped scanning,
            // most likely this is a timeout scenario.
            centralManager.stopScan()
            centralManager.delegate = safeguardedDelegate
            searchCallback(.failure(.timeout))
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension FirmwareUpgradePeripheralFinder: CBCentralManagerDelegate {
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let peripheralName = peripheral.name ?? ""
        let advertisedName = (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? ""
        
        guard peripheralName.localizedCaseInsensitiveContains(searchName)
                || advertisedName.localizedCaseInsensitiveContains(searchName) else { return }
        centralManager?.stopScan()
        centralManager?.delegate = safeguardedDelegate
        searchCallback?(.success(peripheral))
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // No-op.
    }
}

// MARK: - Error

enum FirmwareUpgradeManagerPeripheralFinderError: LocalizedError {
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .timeout:
            return "Failed due to timeout: unable to find device in a reasonable time."
        }
    }
}
