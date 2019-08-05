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

/// The Network Connection object maintains connections to Bluetooth
/// mesh proxies. It scans in the background and connects to nodes that
/// advertise with Network ID or Node Identity beacon.
///
/// The maximum number of simultaneous connections is defined by
/// `maxConnections`. By connecting to more than one device, this
/// object allows quick switching to another proxy in case link
/// to one of the devices is lost. Only the first device will
/// receive outgoing messages. However, the `dataDelegate` will be
/// notified about messages received from any of the connected proxies.
class NetworkConnection: NSObject, Bearer {
    /// Maximum number of connections that `NetworkConnection` can
    /// handle.
    static let maxConnections = 1
    /// The Bluetooth Central Manager instance that will scan and
    /// connect to proxies.
    let centralManager: CBCentralManager
    /// The Mesh Network for this connection.
    let meshNetwork: MeshNetwork
    /// The list of connected GATT Proxies.
    var proxies: [GattBearer] = []
    var buffer: [(data: Data, type: PduType)] = []
    var isOpen: Bool = false
    
    weak var delegate: BearerDelegate?
    weak var dataDelegate: BearerDataDelegate?
    
    public var supportedPduTypes: PduTypes {
        return [.networkPdu, .meshBeacon, .proxyConfiguration]
    }
    
    /// A flag indicating whether the network connection is open.
    /// When open, it will scan for mesh nodes in range and connect to
    /// them if found.
    private var isStarted: Bool = false
    
    /// Returns `true` if at least one Proxy is connected, `false` otherwies.
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
        if !isStarted && centralManager.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: [MeshProxyService.uuid], options: nil)
        }
        isStarted = true
    }
    
    func close() {
        centralManager.stopScan()
        proxies.forEach { $0.close() }
        proxies.removeAll()
        isStarted = false
    }
    
    func send(_ data: Data, ofType type: PduType) throws {
        guard supports(type) else {
            throw BearerError.pduTypeNotSupported
        }
        guard let proxy = proxies.first(where: { $0.isOpen }) else {
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
            if isStarted && proxies.count < NetworkConnection.maxConnections {
                central.scanForPeripherals(withServices: [MeshProxyService.uuid], options: nil)
            }
        case .poweredOff, .resetting:
            proxies.forEach { $0.close() }
            proxies.removeAll()
        default:
            break
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Is it a Network ID beacon?
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
        
        guard !proxies.contains(where: { $0.identifier == peripheral.identifier }),
              let bearer = GattBearer(target: peripheral) else {
            return
        }
        proxies.append(bearer)
        bearer.delegate = self
        bearer.dataDelegate = self
        // Is the limit reached?
        if proxies.count >= NetworkConnection.maxConnections {
            central.stopScan()
        }
        bearer.open()
    }
}

extension NetworkConnection: GattBearerDelegate, BearerDataDelegate {
    
    func bearerDidOpen(_ bearer: Bearer) {
        guard !isOpen else {
            return
        }
        isOpen = true
        print("Bearer open")
        delegate?.bearerDidOpen(self)
        
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
        if isStarted && proxies.count < NetworkConnection.maxConnections {
            centralManager.scanForPeripherals(withServices: [MeshProxyService.uuid], options: nil)
        }
        if proxies.isEmpty {
            isOpen = false
            print("Bearer closed")
            delegate?.bearer(self, didClose: nil)
        }
    }
    
    func bearerDidConnect(_ bearer: Bearer) {
        if !isOpen, let delegate = delegate as? GattBearerDelegate {
            delegate.bearerDidConnect(bearer)
        }
    }
    
    func bearerDidDiscoverServices(_ bearer: Bearer) {
        if !isOpen, let delegate = delegate as? GattBearerDelegate {
            delegate.bearerDidDiscoverServices(bearer)
        }
    }
    
    func bearer(_ bearer: Bearer, didDeliverData data: Data, ofType type: PduType) {
        dataDelegate?.bearer(self, didDeliverData: data, ofType: type)
    }
    
}
