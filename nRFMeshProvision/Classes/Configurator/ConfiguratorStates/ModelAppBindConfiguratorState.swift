//
//  ModelAppBindConfiguratorState.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 13/04/2018.
//

import CoreBluetooth
import Foundation

class ModelAppBindConfiguratorState: NSObject, ConfiguratorStateProtocol {
    
    // MARK: - Properties
    private var proxyService            : CBService!
    private var dataInCharacteristic    : CBCharacteristic!
    private var dataOutCharacteristic   : CBCharacteristic!
    private var elementAddress          : Data!
    private var appKeyIndex             : Data!
    private var modelIdentifier         : Data!
    private var networkLayer            : NetworkLayer!
    private var segmentedData: Data
    
    // MARK: - ConfiguratorStateProtocol
    var destinationAddress  : Data
    var target              : ProvisionedMeshNodeProtocol
    var stateManager        : MeshStateManager
    
    required init(withTargetProxyNode aNode: ProvisionedMeshNodeProtocol,
                  destinationAddress aDestinationAddress: Data,
                  andStateManager aStateManager: MeshStateManager) {
        target = aNode
        segmentedData = Data()
        stateManager = aStateManager
        destinationAddress = aDestinationAddress
        networkLayer = NetworkLayer(withStateManager: stateManager)
        super.init()
        target.basePeripheral().delegate = self
        //If services and characteristics are already discovered, set them now
        let discovery           = target.discoveredServicesAndCharacteristics()
        proxyService            = discovery.proxyService
        dataInCharacteristic    = discovery.dataInCharacteristic
        dataOutCharacteristic   = discovery.dataOutCharacteristic
    }
    
    public func setBinding(elementAddress anElementAddress: Data,
                           appKeyIndex anAppKeyIndex: Data,
                           andModelIdentifier aModelIdentifier: Data) {
        elementAddress  = anElementAddress
        appKeyIndex     = anAppKeyIndex
        modelIdentifier = aModelIdentifier
    }

    func humanReadableName() -> String {
        return "Model AppKey Bind"
    }
    
    func execute() {
        let message = ModelAppBindMessage(withElementAddress: elementAddress,
                                          appKeyIndex: appKeyIndex,
                                          andModelIdentifier: modelIdentifier)
        //Send to destination (unicast)
        let payloads = message.assemblePayload(withMeshState: stateManager.state(), toAddress: destinationAddress)
        for aPayload in payloads! {
            var data = Data([0x00]) //Type => Network
            data.append(aPayload)
            if data.count <= target.basePeripheral().maximumWriteValueLength(for: .withoutResponse) {
                print("Sending model app bind data: \(data.hexString())")
                target.basePeripheral().writeValue(data, for: dataInCharacteristic, type: .withoutResponse)
            } else {
                print("maximum write length is shorter than PDU, will Segment")
                var segmentedProvisioningData = [Data]()
                data = Data(data.dropFirst()) //Drop old network haeder, SAR will now set that instead.
                let chunkRanges = self.calculateDataRanges(data, withSize: 19)
                for aRange in chunkRanges {
                    var header = Data()
                    let chunkIndex = chunkRanges.index(of: aRange)!
                    if chunkIndex == 0 {
                        header.append(Data([0x40])) //SAR start
                    } else if chunkIndex == chunkRanges.count - 1 {
                        header.append(Data([0xC0])) //SAR end
                    } else {
                        header.append(Data([0x80])) //SAR cont.
                    }
                    var chunkData = Data(header)
                    chunkData.append(data[aRange])
                    segmentedProvisioningData.append(chunkData)
                }
                for aSegment in segmentedProvisioningData {
                    print("Sending model app bind segment: \(aSegment.hexString())")
                    target.basePeripheral().writeValue(aSegment, for: dataInCharacteristic, type: .withoutResponse)
                }
            }
        }
    }
    
    func receivedData(incomingData : Data) {
        if incomingData[0] == 0x01 {
            print("Secure beacon: \(incomingData.hexString())")
        } else {
            print("Incoming DPU: \(incomingData.hexString())")
            let strippedOpcode = incomingData.dropFirst()
            if let result = networkLayer.incomingPDU(strippedOpcode) {
                if result is ModelAppBindStatusMessage {
                    let modelKeyStatus = result as! ModelAppBindStatusMessage
                    target.delegate?.receivedModelAppBindStatus(modelKeyStatus)
                } else {
                    print("Ignoring non model app status message")
                }
            }
        }
    }
    
    private func calculateDataRanges(_ someData: Data, withSize aChunkSize: Int) -> [Range<Int>] {
        var totalLength = someData.count
        var ranges = [Range<Int>]()
        
        var partIdx = 0
        while (totalLength > 0) {
            var range : Range<Int>
            if totalLength > aChunkSize {
                totalLength -= aChunkSize
                range = (partIdx * aChunkSize) ..< aChunkSize + (partIdx * aChunkSize)
            } else {
                range = (partIdx * aChunkSize) ..< totalLength + (partIdx * aChunkSize)
                totalLength = 0
            }
            ranges.append(range)
            partIdx += 1
        }
        
        return ranges
    }
    
    // MARK: - CBPeripheralDelegate
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        //NOOP
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        //NOOP
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        //SAR handling
        if characteristic.value![0] & 0xC0 == 0x40 {
            //Add message type header
            segmentedData.append(characteristic.value![0] & 0x3F)
            segmentedData.append(characteristic.value!.dropFirst())
        } else if characteristic.value![0] & 0xC0 == 0x80 {
            print("Segmented data cont")
            segmentedData.append(characteristic.value!.dropFirst())
        } else if characteristic.value![0] & 0xC0 == 0xC0 {
            print("Segmented data end")
            segmentedData.append(characteristic.value!.dropFirst())
            print("Reassembled data!: \(segmentedData.hexString())")
            //Copy data and send it to NetworkLayer
            receivedData(incomingData: Data(segmentedData))
            segmentedData = Data()
        } else {
            receivedData(incomingData: characteristic.value!)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("Characteristic notification state changed")
    }
}

