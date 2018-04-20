//
//  StartProvisionProvisioningState.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 20/12/2017.
//

import Foundation
import CoreBluetooth

class StartProvisionProvisioningState: NSObject, ProvisioningStateProtocol {
    // MARK: - Protocol properties
    private var provisioningService: CBService!
    private var dataInCharacteristic: CBCharacteristic!
    private var dataOutCharacteristic: CBCharacteristic!

    // MARK: - State properties
    private var elementCount                    : Int!
    private var algorithm                       : ProvisioningAlgorithm!
    private var publicKeyAvailability           : PublicKeyInformationAvailability!
    private var staticOutOfBoundAvailability    : StaticOutOfBoundInformationAvailability!
    private var outputOutOfBoundSize            : UInt8!
    private var outputOutOfBoundAction          : OutputOutOfBoundActions!
    private var inputOutOfBoundSize             : UInt8!
    private var inputOutOfBoundAction           : InputOutOfBoundActions!
    
    func humanReadableName() -> String {
        return "ProvisioningStart"
    }
   // MARK: - ProvisioningStateProtocol
    var target: UnprovisionedMeshNodeProtocol
    
    required init(withTargetNode aNode: UnprovisionedMeshNodeProtocol) {
        target = aNode
        super.init()
        target.basePeripheral().delegate = self
        //If services and characteristics are already discovered, set them now
        let discovery = target.discoveredServicesAndCharacteristics()
        provisioningService     = discovery.provisionService
        dataInCharacteristic    = discovery.dataInCharacteristic
        dataOutCharacteristic   = discovery.dataOutCharacteristic
    }
   
    public func setCapabilities(_ someCapabilities: (elementcount: Int, algorithm: ProvisioningAlgorithm, publicKeyAvailability: PublicKeyInformationAvailability, staticOutOfBoundAvailability: StaticOutOfBoundInformationAvailability, outOfBoundSize: UInt8, outOfBoundAction: OutputOutOfBoundActions, inputOutOfBoundsize: UInt8, inputOutOfBoundAction: InputOutOfBoundActions)) {
        elementCount                    = someCapabilities.elementcount
        algorithm                       = someCapabilities.algorithm
        publicKeyAvailability           = someCapabilities.publicKeyAvailability
        staticOutOfBoundAvailability    = someCapabilities.staticOutOfBoundAvailability
        outputOutOfBoundSize            = someCapabilities.outOfBoundSize
        outputOutOfBoundAction          = someCapabilities.outOfBoundAction
        inputOutOfBoundSize             = someCapabilities.inputOutOfBoundsize
        inputOutOfBoundAction           = someCapabilities.inputOutOfBoundAction
    }

    func execute() {
        guard algorithm! == .fipsp256EllipticCurve else {
            print("Error: Unsupported algorithm, only supported algorithm is FIPS P-256 Elliptic curve")
            return
        }

        print("Executing Start provision PDU")
        let provisionStartCommand   : UInt8 = 0x02
        let fipsEllipticAlgorithm   : UInt8 = 0x00 //FIPS P-256
        let oobpubkeyAvailability   : UInt8 = 0x00 //No OOB public key has been used
        var startPDU = Data([0x03, provisionStartCommand, fipsEllipticAlgorithm, oobpubkeyAvailability])
        if outputOutOfBoundAction! == .noOutput {
            startPDU.append(contentsOf: [0x00, 0x00, 0x00 ]) //No OOB = 0, Action = 0 & size = 0
        } else {
            if outputOutOfBoundAction! == .outputNumeric {
                startPDU.append(contentsOf: [0x02, //Output OOB opcode, better implementation TBD when we support all methods
                                             outputOutOfBoundAction.toByteValue()!,
                                             outputOutOfBoundSize])
            }
        }

        print("Provision Start PDU Sent: \(startPDU.hexString())")
        
        //Store invitation data, first two bytes are PDU related and are not used further.
        target.generatedProvisioningStartData(startPDU.dropFirst().dropFirst())
        target.basePeripheral().writeValue(startPDU, for: dataInCharacteristic, type: .withoutResponse)

        let nextState = PublicKeyProvisioningState(withTargetNode: target)
        target.switchToState(nextState)
        
    }

    // MARK: - CBPeripheralDelegate
    //
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        //NOOP
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        //NOOP
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        //NOOP
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        //NOOP
    }
}
