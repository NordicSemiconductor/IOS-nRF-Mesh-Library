/*
* Copyright (c) 2025, Nordic Semiconductor
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

import UIKit
import NordicMesh
import CoreBluetooth

class PasskeyViewController: UIViewController {
    // MARK: - Properties
    
    var node: Node!
    var bearer: GattBearer!
    var applicationKey: ApplicationKey!
    
    // MARK: - Outlets
    
    @IBOutlet weak var passkeyLabel: UILabel!
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.setEmptyView(
            title: "Security",
            message: "Establishing secure connection...",
            messageImage: #imageLiteral(resourceName: "baseline-security")
        )
        view.showEmptyView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // This View Controller reads the passkey from the LE Pairing Responder model.
        // Then it tries to enable notifications on the SMP characteristic.
        // This may trigger pairing / bonding process.
        // If the callback for enabling notifications isn't called immediately,
        // we display the passkey to the user. The passkey needs to be typed by the
        // user on the Pairing dialog presented by iOS / iPadOS.
        readPasskey()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination = segue.destination as! FirmwareSelectionViewController
        destination.node = node
        destination.bearer = bearer
        destination.applicationKey = applicationKey
    }

}

private extension PasskeyViewController {
    
    func readPasskey() {
        guard let lePairingResponderModel = node.models(withModelId: .lePairingResponder, definedBy: .nordicSemiconductorCompanyId).first else {
            performSegue(withIdentifier: "continue", sender: nil)
            return
        }
        Task {
            let manager = MeshNetworkManager.instance
            // Check if the LE Pairing Responder model has a key bound to it.
            if lePairingResponderModel.boundApplicationKeys.isEmpty {
                do {
                    let firmwareDistributorServerModel = node.models(withSigModelId: .firmwareDistributionServerModelId).first!
                    let applicationKey = firmwareDistributorServerModel.boundApplicationKeys.first!
                    let response = try await manager.send(ConfigModelAppBind(applicationKey: applicationKey, to: lePairingResponderModel)!, to: node) as! ConfigModelAppStatus
                    guard response.status == .success else {
                        presentAlert(title: "Error",
                                     message: "Failed to bind the LE Pairing Responder model to the Application Key.\n\nStatus: \(response.status)") { [weak self] _ in
                            self?.navigationController?.popViewController(animated: true)
                        }
                        return
                    }
                } catch {
                    presentAlert(title: "Error",
                                 message: "Failed to bind the LE Pairing Responder model to the Application Key.\n\nError: \(error)") { [weak self] _ in
                        self?.navigationController?.popViewController(animated: true)
                    }
                }
            }
            do {
                let response = try await manager.send(PairingRequest(), to: lePairingResponderModel) as! PairingResponse
                guard response.status == 0x00 else {
                    presentAlert(title: "Error",
                                 message: "Failed to read the passkey using LE Pairing Responder model.\n\nStatus: \(response.status)") { [weak self] _ in
                        self?.navigationController?.popViewController(animated: true)
                    }
                    return
                }
                let task = Task.detached { @MainActor [weak self] in
                        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                        UIView.animate(withDuration: 0.5) {
                            self?.passkeyLabel.alpha = 1.0
                        }
                        self?.passkeyLabel.text = String(format: "%06d", response.passkey)
                }
                guard let bearer = bearer else {
                    throw ConnectionError.peripheralNotFound
                }
                do {
                    try await pair(bearer: bearer)
                } catch {
                    task.cancel()
                    throw error
                }
                Task { @MainActor in
                    performSegue(withIdentifier: "continue", sender: nil)
                }
            } catch {
                Task { @MainActor in
                    UIView.animate(withDuration: 0.5) {
                        self.passkeyLabel.alpha = 0.0
                    }
                }
                presentAlert(title: "Error",
                             message: error.localizedDescription) { [weak self] _ in
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    enum ConnectionError: LocalizedError {
        case invalidState(state: CBManagerState)
        case peripheralNotFound
        case connectionFailed
        case smpNotSupported
        case pairingFailedBefore
        
        var errorDescription: String? {
            switch self {
            case .invalidState(let state):
                return "Bluetooth is not powered on. State: \(state)"
            case .peripheralNotFound:
                return "Peripheral not found."
            case .connectionFailed:
                return "Failed to connect to peripheral."
            case .smpNotSupported:
                return "SMP not supported."
            case .pairingFailedBefore:
                return "Pairing already failed during this connection. Disconnect and try again."
            }
        }
    }
    
    func pair(bearer: GattBearer) async throws {
        class Connection: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
            public static let SmpServiceUUID        = CBUUID(string: "8D53DC1D-1DB7-4CD3-868B-8A527460AA84")
            public static let SmpCharacteristicUUID = CBUUID(string: "DA2E7828-FBCE-4E01-AE9E-261174997C48")
            
            private let continuation: CheckedContinuation<Void, Error>
            private var identifier: UUID
            private var peripheral: CBPeripheral?
            private var pairingTime: CFAbsoluteTime?
            
            init(for bearer: GattBearer, _ continuation: CheckedContinuation<Void, Error>) {
                self.continuation = continuation
                self.identifier = bearer.identifier
            }
            
            func centralManagerDidUpdateState(_ central: CBCentralManager) {
                if central.state == .poweredOn {
                    guard let peripheral = central.retrievePeripherals(withIdentifiers: [identifier]).first else {
                        continuation.resume(throwing: ConnectionError.peripheralNotFound)
                        return
                    }
                    self.peripheral = peripheral
                    peripheral.delegate = self
                    central.connect(peripheral)
                } else {
                    continuation.resume(throwing: ConnectionError.invalidState(state: central.state))
                }
            }
            
            func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
                continuation.resume(throwing: ConnectionError.connectionFailed)
            }
            
            func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
                peripheral.discoverServices([Connection.SmpServiceUUID])
            }
            
            func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let services = peripheral.services,
                      let service = services.first(where: { $0.uuid == Connection.SmpServiceUUID }) else {
                    continuation.resume(throwing: ConnectionError.smpNotSupported)
                    return
                }
                peripheral.discoverCharacteristics([Connection.SmpCharacteristicUUID], for: service)
            }
            
            func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let characteristics = service.characteristics,
                      let characteristic = characteristics.first(where: { $0.uuid == Connection.SmpCharacteristicUUID }),
                      characteristic.properties.contains(.notify) else {
                    continuation.resume(throwing: ConnectionError.smpNotSupported)
                    return
                }
                pairingTime = CFAbsoluteTimeGetCurrent()
                peripheral.setNotifyValue(true, for: characteristic)
            }
            
            func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: (any Error)?) {
                let elapsed = CFAbsoluteTimeGetCurrent() - pairingTime!
                if let error = error {
                    // If an error occurs before 2 seconds, we assume that no pairing dialog
                    // was presented. This means, that an invalid passkey was typed in this
                    // connection and iOS will just try to reuse the same one.
                    // User needs to disconnect and try again.
                    if elapsed < 2.0 {
                        continuation.resume(throwing: ConnectionError.pairingFailedBefore)
                    } else {
                        continuation.resume(throwing: error)
                    }
                    return
                }
                // Notifications are enabled after the device is paired.
                continuation.resume(returning: ())
            }
            
        }
        var manager: CBCentralManager!
        var strongReference: Connection!
        defer {
            strongReference = nil
            manager.delegate = nil
            manager = nil
        }
        try await withCheckedThrowingContinuation { continuation in
            strongReference = Connection(for: bearer, continuation)
            manager = CBCentralManager(delegate: strongReference, queue: nil)
        }
    }
    
}
