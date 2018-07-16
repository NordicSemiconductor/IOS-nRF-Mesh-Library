//
//  PublicKeyProvisioningState.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 21/12/2017.
//

import Foundation
import CoreBluetooth
import Security

class PublicKeyProvisioningState: NSObject, ProvisioningStateProtocol {

    // MARK: - Protocol properties
    private var provisioningService: CBService!
    private var dataInCharacteristic: CBCharacteristic!
    private var dataOutCharacteristic: CBCharacteristic!

    // MARK: - State properties
    private var publicKey: SecKey?
    private var privateKey: SecKey?
    private var lastReceivedHeader: UInt8?
    private var segmentedPublicKeyData: Data?

    func humanReadableName() -> String {
        return "Public Key"
    }

    //SAR with PublicKey PDU (0x03) (0x43, 0x83 and 0xC3)
    let pubKeySARStart    : UInt8 = 0x43
    let pubKeySARContinue : UInt8 = 0x83
    let pubKeySARLast     : UInt8 = 0xC3

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
   
    func execute() {
        print("Executing public key provision PDU")
        print("generating keypair")
        (privateKey, publicKey) = generateKeyPair()
        print("keypair generated")
        var copyExternalError: Unmanaged<CFError>?
        let representation = SecKeyCopyExternalRepresentation(publicKey!, &copyExternalError)
        guard copyExternalError == nil else {
            print("Keypair copy external representation failed: \(copyExternalError!.takeRetainedValue().localizedDescription)")
            return
        }
   
        target.generatedProvisionerPrivateKey(privateKey!)

        let provisioningKeyPairPDU: UInt8 = 0x03
        let dataLength: Int = CFDataGetLength(representation!)
        let bytesBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: dataLength)
        bytesBuffer.initialize(to: 0)
        CFDataGetBytes(representation, CFRange(location:0, length:dataLength), bytesBuffer)
        var dataArray = Array(UnsafeBufferPointer(start: bytesBuffer, count: dataLength))
        //First byte is 0x04, which is simply a header for uncompressed raw data and is unused
        dataArray = Array(dataArray.dropFirst())
        let publicKeyData = Data(bytes:dataArray)
        
        //Store device public key data for future use in the process
        target.generatedProvisionerPublicKeyData(publicKeyData)
        
        let maximumWriteLength = target.basePeripheral().maximumWriteValueLength(for: .withoutResponse)
        // Public Key X,Y (64 bytes) + provisioning PDU (2 bytes) + PublicKey PDU (2 bytes) = 66 bytes
        if maximumWriteLength >= publicKeyData.count + 2 {
            print("No SAR needed, maximum write length for write without response \(maximumWriteLength)")
            target.basePeripheral().writeValue(Data([0x03, provisioningKeyPairPDU]) + publicKeyData, for: dataInCharacteristic, type: .withoutResponse)
        } else {
            var segmentedKey  : [Data] = [Data]()
            segmentedKey.append(Data(bytes:[pubKeySARStart, provisioningKeyPairPDU]))
            //This will always fallback to just 20 octets
            //TODO: Dynamically assign the minimum possible length depending on MTU.
            segmentedKey[0].append(contentsOf: publicKeyData[0..<18])

            segmentedKey.append(Data(bytes:[pubKeySARContinue]))
            segmentedKey[1].append(contentsOf: publicKeyData[18..<37])

            segmentedKey.append(Data(bytes: [pubKeySARContinue]))
            segmentedKey[2].append(contentsOf: publicKeyData[37..<56])

            segmentedKey.append(Data(bytes:[pubKeySARLast]))
            segmentedKey[3].append(contentsOf: publicKeyData[56..<64])

            for aSegment in segmentedKey {
                if aSegment[0] == pubKeySARStart {
                    print("PubKey SAR Start, Part \(segmentedKey.index(of: aSegment)!)/\(segmentedKey.count) => \(aSegment.hexString())")
                } else if aSegment[0] == pubKeySARContinue {
                    print("PubKey SAR Cont., Part \(segmentedKey.index(of: aSegment)!)/\(segmentedKey.count) => \(aSegment.hexString())")
                } else if aSegment[0] == pubKeySARLast {
                    print("PubKey SAR Last, Part \(segmentedKey.index(of: aSegment)!)/\(segmentedKey.count) => \(aSegment.hexString())")
                }
                target.basePeripheral().writeValue(aSegment, for: dataInCharacteristic, type: .withoutResponse)
            }
        }
    }
   
    private func generateKeyPair() -> (privateKey: SecKey?, publicKey: SecKey?) {
        // private key parameters
        let privateKeyParams = [kSecAttrIsPermanent : false] as CFDictionary
        
        // public key parameters
        let publicKeyParams = [kSecAttrIsPermanent : false] as CFDictionary
        
        // global parameters
        let parameters = [kSecAttrKeyType : kSecAttrKeyTypeECSECPrimeRandom,
                          kSecAttrKeySizeInBits : 256,
                          kSecPublicKeyAttrs : publicKeyParams,
                          kSecPrivateKeyAttrs : privateKeyParams] as CFDictionary
        
        var pubKey, privKey: SecKey?
        let status = SecKeyGeneratePair(parameters as CFDictionary, &pubKey, &privKey)
        
        guard status == 0 else {
            print("An error occured")
            return (pubKey!, privKey!)
        }
        return (privKey!, pubKey!)
    }

    private func receivedSegmentedPublicKeyStart(data segmentedData: Data) {
        //First Segment, drop SAR/PDU byte
        segmentedPublicKeyData = Data(capacity: 64)
        segmentedPublicKeyData = segmentedPublicKeyData! + segmentedData.dropFirst()

    }

    private func receivedSegmentedPublicKeyContinuation(data segmentedData: Data) {
        //Continuation segment(s), drop SAR/PDU byte
        segmentedPublicKeyData = segmentedPublicKeyData! + segmentedData.dropFirst()
    }

    private func receivedSegmentedPublicKeyEnd(data segmentedData: Data) {
        //Final Segment, drop SAR/PDU byte
        segmentedPublicKeyData = segmentedPublicKeyData! + segmentedData.dropFirst()
        receivedPublicKeyValue(segmentedPublicKeyData!, isSegmented: true)
    }

    private func receivedPublicKeyValue(_ aValue: Data, isSegmented: Bool) {
        var strippedDevicepublicKey: Data!
        if isSegmented {
            //Drop first byte only, no Provisioning byte
            print("Public Key = \(aValue.dropFirst().hexString())")
            strippedDevicepublicKey = aValue.dropFirst()
        } else {
            //Drop first 2 bytes (PDU byte + Provisioning byte)
            print("Public Key = \(aValue.dropFirst().dropFirst().hexString())")
            strippedDevicepublicKey = aValue.dropFirst().dropFirst()
        }

        var devicePublicKeyData = Data(bytes:[0x04]) //First value has to be 0x04 to indicate uncompressed representation
        devicePublicKeyData.append(contentsOf: strippedDevicepublicKey)
        target.receivedDevicePublicKeyData(strippedDevicepublicKey)
        
        //Create public key SecKey from data
        let pubKeyParameters = [kSecAttrKeyType : kSecAttrKeyTypeECSECPrimeRandom,
                                kSecAttrKeyClass: kSecAttrKeyClassPublic] as CFDictionary
        
        var createKeyError: Unmanaged<CFError>?
        let devicePublicKey = SecKeyCreateWithData(devicePublicKeyData as CFData,
                                                   pubKeyParameters,
                                                   &createKeyError)
        guard createKeyError == nil else {
            print((createKeyError!.takeRetainedValue() as Error).localizedDescription)
            return
        }
   
        let exchangeResultParams = [kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom] as CFDictionary
        
        var error: Unmanaged<CFError>?
        guard let shared = SecKeyCopyKeyExchangeResult(privateKey!,
                                                       SecKeyAlgorithm.ecdhKeyExchangeStandardX963SHA256,
                                                       devicePublicKey!,
                                                       exchangeResultParams,
                                                       &error) else {
                                                        print((error!.takeRetainedValue() as Error).localizedDescription)
                                                        return
        }

        let ecdh = shared as Data
        target.calculatedECDH(ecdh)
        let nextState = ConfirmationProvisioningState(withTargetNode: target)
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
        if var aValue = characteristic.value {
            if aValue[0] == 0x03 {
                lastReceivedHeader = 0x03
                if aValue[1] == 0x03 {
                    print("Received an unsegmented device public key")
                    self.receivedPublicKeyValue(aValue, isSegmented: false)
                } else {
                    if aValue[1] == 0x09 {
                        print("Provisioning failed!, error code received.")
                        target.shouldDisconnect()
                    }
                    print("Received unexpected PDU \(aValue[0]), \(aValue[1])")
                    print("Expected: 0x03, 0x03")
                }
       } else if aValue[0] == 0x43 {
                if lastReceivedHeader == nil {
                    lastReceivedHeader = aValue[0]
                    print("Received SAR start message")
                } else {
                    print("Received SAR start 0x4, while previous state was: \(lastReceivedHeader!)")
                    return
                }
           self.receivedSegmentedPublicKeyStart(data: aValue)
            } else if aValue[0] == 0x83 {
                if lastReceivedHeader == 0x43 {
                    lastReceivedHeader = aValue[0]
                    print("Received first SAR continuation message")
                } else if lastReceivedHeader == 0x83 {
                    print("Received another SAR continuation message")
                } else {
                    print("Received SAR continuation 0x8, while previous state was: \(lastReceivedHeader!)")
                    return
                }
           self.receivedSegmentedPublicKeyContinuation(data: aValue)
            } else if aValue[0] == 0xC3 {
                if lastReceivedHeader == 0x83 {
                    lastReceivedHeader = aValue[0]
                    print("Recevied SAR last message")
                } else {
                    print("Received SAR last 0x8, while previous state was: \(lastReceivedHeader!)")
                    return
                }
           self.receivedSegmentedPublicKeyEnd(data: aValue)
            } else {
                print("Received unexpected PDU \(aValue[0])")
                print("Expected: 0x03 OR Segmented data with headers: 0x67, 0x83 or 0xC3")
            }
        }
   
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        //NOOP
    }
}
