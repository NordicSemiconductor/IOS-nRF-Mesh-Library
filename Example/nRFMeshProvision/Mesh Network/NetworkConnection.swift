//
//  NetworkConnection.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 23/05/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import CoreBluetooth
import nRFMeshProvision

class NetworkConnection: NSObject, Bearer {
    let centralManager: CBCentralManager
    
    weak var delegate: BearerDelegate?
    weak var dataDelegate: BearerDataDelegate?
    
    /// The Mesh Network for this connection.
    let meshNetwork: MeshNetwork
    
    /// The list of connected GATT Proxies.
    var proxies: [GattBearer] = []
    var buffer: [(data: Data, type: PduType)] = []
    
    public var supportedPduTypes: PduTypes {
        return [.networkPdu, .meshBeacon, .proxyConfiguration]
    }
    
    var isOpen: Bool = false
    
    /// Returns `true` if at least one Proxy is connected.
    var isConnected: Bool {
        return proxies.contains { $0.isOpen }
    }
    
    init(to meshNetwork: MeshNetwork) {
        centralManager = CBCentralManager()
        self.meshNetwork = meshNetwork
        super.init()
        centralManager.delegate = self
    }
    
    func open() {
        if !isOpen && centralManager.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: [MeshProxyService.uuid], options: nil)
        }
        isOpen = true
    }
    
    func close() {
        centralManager.stopScan()
        proxies.forEach { $0.close() }
        proxies.removeAll()
        isOpen = false
    }
    
    func send(_ data: Data, ofType type: PduType) throws {
        guard supports(type) else {
            throw BearerError.pduTypeNotSupported
        }
        guard let proxy = proxies.first else {
            buffer.append((data: data, type: type))
            return
        }
        try proxy.send(data, ofType: type)
    }
    
}

extension NetworkConnection: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            if isOpen {
                central.scanForPeripherals(withServices: [MeshProxyService.uuid], options: nil)
            }
        case .poweredOff, .resetting:
            proxies.forEach { $0.close() }
            proxies.removeAll()
        default:
            break
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Is it a Network ID beacon?ś
        if let networkId = advertisementData.networkId {
            guard meshNetwork.matches(networkId: networkId) else {
                // A Node from another mesh network.
                return
            }
        } else {
            // Is it a Node Identity beacon?
            guard let nodeIdentity = advertisementData.nodeIdentity,
                meshNetwork.matches(hash: nodeIdentity.hash, random: nodeIdentity.random) else {
                // A Node from another mesh network.
                return
            }
        }
        
        let bearer = GattBearer(to: peripheral, using: central)
        bearer.delegate = self
        bearer.dataDelegate = self
        proxies.append(bearer)
        bearer.open()
    }
}

extension NetworkConnection: GattBearerDelegate, BearerDataDelegate {
    
    func bearerDidOpen(_ bearer: Bearer) {
        let connectionsCount = proxies.reduce(0) { (last, bearer) -> Int in
            return last + (bearer.isOpen ? 1 : 0)
        }
        
        if connectionsCount == 0 {
            print("Bearer open")
            delegate?.bearerDidOpen(self)
        }
        
        // If any packets were buffered, send them to the first connected Proxy.
        buffer.forEach {
            try? bearer.send($0.data, ofType: $0.type)
        }
        buffer.removeAll()
    }
    
    func bearer(_ bearer: Bearer, didClose error: Error?) {
        if let index = proxies.firstIndex(of: bearer as! GattBearer) {
            proxies.remove(at: index)
        }
        
        if proxies.isEmpty {
            print("Bearer closed")
            delegate?.bearer(self, didClose: nil)
        }
    }
    
    func bearer(_ bearer: Bearer, didDeliverData data: Data, ofType type: PduType) {
        dataDelegate?.bearer(self, didDeliverData: data, ofType: type)
    }
    
}
