/*
* Copyright (c) 2019, Nordic Semiconductor
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
import CoreBluetooth
import nRFMeshProvision

/// The `NetworkConnection` object maintains connections to Bluetooth
/// mesh proxies. It scans in the background and connects to nodes that
/// advertise with Network ID or Node Identity beacon.
///
/// The maximum number of simultaneous connections is defined by
/// ``NetworkConnection/maxConnections``. By connecting to more than one device, this
/// object allows quick switching to another proxy in case link
/// to one of the devices is lost. Only the first device will
/// receive outgoing messages. However, the ``NetworkConnection/dataDelegate`` will be
/// notified about messages received from any of the connected proxies.
class NetworkConnection: NSObject, Bearer {
    private let connectionModeKey = "connectionMode"
    
    /// Maximum number of connections that ``NetworkConnection`` can handle.
    ///
    /// - note: In nRF Mesh app this value is set to 1 due to UI limitations.
    ///         When applying in 3rd party app, higher values should work.
    static let maxConnections = 1
    /// The Bluetooth Central Manager instance that will scan and
    /// connect to proxies.
    let centralManager: CBCentralManager
    /// The Mesh Network for this connection.
    let meshNetwork: MeshNetwork
    /// The list of connected GATT Proxies.
    var proxies: [GattBearer] = []
    /// A flag set to `true` when any of the underlying bearers is open.
    var isOpen: Bool = false
    
    weak var delegate: BearerDelegate?
    weak var dataDelegate: BearerDataDelegate?
    weak var logger: LoggerDelegate? {
        didSet {
            proxies.forEach {
                $0.logger = logger
            }
        }
    }
    
    public var supportedPduTypes: PduTypes {
        return [.networkPdu, .meshBeacon, .proxyConfiguration]
    }
    
    /// A flag indicating whether the network connection is open.
    /// When open, it will scan for mesh nodes in range and connect to
    /// them if found.
    private var isStarted: Bool = false
    
    /// Returns `true` if at least one Proxy is connected, `false` otherwise.
    var isConnected: Bool {
        return proxies.contains { $0.isOpen }
    }
    /// Returns the name of the first connected Proxy.
    var name: String? {
        return proxies.first { $0.isOpen }?.name
    }
    /// Whether the connection to mesh network should be managed automatically,
    /// or manually.
    var isConnectionModeAutomatic: Bool {
        get {
            return UserDefaults.standard.bool(forKey: connectionModeKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: connectionModeKey)
            if newValue && isStarted && centralManager.state == .poweredOn &&
               proxies.count < NetworkConnection.maxConnections {
                centralManager.scanForPeripherals(withServices: [MeshProxyService.uuid], options: nil)
            }
        }
    }
    
    init(to meshNetwork: MeshNetwork) {
        centralManager = CBCentralManager()
        self.meshNetwork = meshNetwork
        super.init()
        centralManager.delegate = self
        
        // By default, the connection mode is automatic.
        UserDefaults.standard.register(defaults: [connectionModeKey : true])
    }
    
    func open() {
        if !isStarted && isConnectionModeAutomatic && centralManager.state == .poweredOn {
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
    
    func disconnect() {
        proxies.forEach { $0.close() }
    }
    
    func send(_ data: Data, ofType type: PduType) throws {
        // Send the message to all open GATT Proxy nodes.
        var success = false
        var e: Error = BearerError.bearerClosed
        proxies.filter { $0.isOpen }.forEach {
            do {
                try $0.send(data, ofType: type)
                success = true
            } catch {
                e = error
            }
        }
        if !success {
            throw e
        }
    }
    
    /// Switches connection to the given GATT Bearer.
    ///
    /// If the limit of ``NetworkConnection/maxConnections`` connections is reached,
    /// the olders one will be closed.
    ///
    /// - parameter bearer: The GATT Bearer proxy to use.
    func use(proxy bearer: GattBearer) {
        // Make sure we're not adding a duplicate.
        guard !proxies.contains(where: { $0.identifier == bearer.identifier }) else {
            return
        }
        // If we reached the limit, disconnect the one added as a first.
        if proxies.count >= NetworkConnection.maxConnections {
            proxies.last?.close()
        }
        // Add new proxy.
        bearer.delegate = self
        bearer.dataDelegate = self
        bearer.logger = logger
        proxies.append(bearer)
        
        // Open the bearer or notify a delegate that the connection is open.
        if bearer.isOpen {
            bearerDidOpen(self)
        } else {
            bearer.open()
        }
        // Is the limit reached?
        if proxies.count >= NetworkConnection.maxConnections {
            centralManager.stopScan()
        }
    }
    
}

extension NetworkConnection: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            if isStarted && isConnectionModeAutomatic &&
               proxies.count < NetworkConnection.maxConnections {
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
        // Is it a Network ID or Private Network Identity beacon?
        if let networkIdentity = advertisementData.networkIdentity {
            guard meshNetwork.matches(networkIdentity: networkIdentity) else {
                // A Node from another mesh network.
                return
            }
        } else {
            // Is it a Node Identity or Private Node Identity beacon?
            guard let nodeIdentity = advertisementData.nodeIdentity,
                  meshNetwork.matches(nodeIdentity: nodeIdentity) else {
                // A Node from another mesh network.
                return
            }
        }
        // Add a new bearer.
        use(proxy: GattBearer(target: peripheral))
    }
}

extension NetworkConnection: GattBearerDelegate, BearerDataDelegate {
    
    func bearerDidOpen(_ bearer: Bearer) {
        guard !isOpen else { return }
        isOpen = true
        delegate?.bearerDidOpen(self)
    }
    
    func bearer(_ bearer: Bearer, didClose error: Error?) {
        if let index = proxies.firstIndex(of: bearer as! GattBearer) {
            proxies.remove(at: index)
        }
        if isStarted && isConnectionModeAutomatic &&
           proxies.count < NetworkConnection.maxConnections {
            centralManager.scanForPeripherals(withServices: [MeshProxyService.uuid], options: nil)
        }
        if proxies.isEmpty {
            isOpen = false
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
