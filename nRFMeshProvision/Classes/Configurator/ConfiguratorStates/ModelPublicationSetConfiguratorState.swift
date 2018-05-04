//
//  ModelPublicationSetConfiguratorState.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 18/04/2018.
//

import CoreBluetooth
import Foundation

class ModelPublicationSetConfiguratorState: NSObject, ConfiguratorStateProtocol {
    
    // MARK: - Properties
    private var proxyService            : CBService!
    private var dataInCharacteristic    : CBCharacteristic!
    private var dataOutCharacteristic   : CBCharacteristic!
    private var networkLayer            : NetworkLayer!
    private var elementAddress          : Data!
    private var appKeyIndex             : Data!
    private var modelIdentifier         : Data!
    private var publishAddress          : Data!
    private var publishTTL              : Data!
    private var publishPeriod           : Data!
    private var publishRetransmitCount  : Data!
    private var publishRetransmitInterval: Data!
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
        super.init()
        target.basePeripheral().delegate = self
        //If services and characteristics are already discovered, set them now
        let discovery           = target.discoveredServicesAndCharacteristics()
        proxyService            = discovery.proxyService
        dataInCharacteristic    = discovery.dataInCharacteristic
        dataOutCharacteristic   = discovery.dataOutCharacteristic

        networkLayer = NetworkLayer(withStateManager: aStateManager, andSegmentAcknowlegdement: { (ackData, delay) -> (Void) in
            self.acknowlegeSegment(withAckData: ackData, withDelay: delay)
        })
    }
    
    public func setPublish(elementAddress anElementAddress: Data,
                           appKeyIndex anAppKeyIndex: Data,
                           publishAddress aPublishAddress: Data,
                           publishTTL aPublishTTL: Data,
                           publishPeriod aPeriod: Data,
                           retransmitCount aCount: Data,
                           retransmitInterval anInterval: Data,
                           andModelIdentifier aModelIdentifier: Data) {
        elementAddress              = anElementAddress
        appKeyIndex                 = anAppKeyIndex
        modelIdentifier             = aModelIdentifier
        publishAddress              = aPublishAddress
        publishTTL                  = aPublishTTL
        publishPeriod               = aPeriod
        publishRetransmitCount      = aCount
        publishRetransmitInterval   = anInterval
    }
    
    func humanReadableName() -> String {
        return "Model Publication Set"
    }
    
    func execute() {
        let message = ModelPublicationSetMessage(withElementAddress: elementAddress,
                                                 publishAddress: publishAddress,
                                                 appKeyIndex: appKeyIndex,
                                                 credentialFlag: false,
                                                 publishTTL: publishTTL,
                                                 publishPeriod: publishPeriod,
                                                 retransmitCount: publishRetransmitCount,
                                                 retransmitInterval: publishRetransmitInterval,
                                                 andModelIdentifier: modelIdentifier)
        //Send to destination (unicast)
        let payloads = message.assemblePayload(withMeshState: stateManager.state(), toAddress: destinationAddress)
        for aPayload in payloads! {
            var data = Data([0x00]) //Type => Network
            data.append(aPayload)
            if data.count <= target.basePeripheral().maximumWriteValueLength(for: .withoutResponse) {
                print("sending model publish address set data: \(data.hexString())")
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
                    chunkData.append(Data(data[aRange]))
                    segmentedProvisioningData.append(chunkData)
                }
                for aSegment in segmentedProvisioningData {
                    print("sending model publish address set segment: \(aSegment.hexString())")
                    target.basePeripheral().writeValue(aSegment, for: dataInCharacteristic, type: .withoutResponse)
                }
            }
        }
    }
    
    func receivedData(incomingData : Data) {
        if incomingData[0] == 0x01 {
            print("Secure beacon: \(incomingData.hexString())")
        } else {
            print("incoming DPU: \(incomingData.hexString())")
            let strippedOpcode = Data(incomingData.dropFirst())
            if let result = networkLayer.incomingPDU(strippedOpcode) {
                if result is ModelPublicationStatusMessage {
                    let publicationStatus = result as! ModelPublicationStatusMessage
                    target.delegate?.receivedModelPublicationStatus(publicationStatus)
                } else {
                    print("ignoring non model publication status message")
                }
            }
        }
    }

    private func acknowlegeSegment(withAckData someData: Data, withDelay aDelay: DispatchTime) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() - DispatchTimeInterval.nanoseconds(Int(aDelay.uptimeNanoseconds))) {
            print("Sending acknowledgement: \(someData.hexString())")
            if someData.count <= self.target.basePeripheral().maximumWriteValueLength(for: .withoutResponse) {
                self.target.basePeripheral().writeValue(someData, for: self.dataInCharacteristic, type: .withoutResponse)
            } else {
                print("Maximum write length is shorter than ACK PDU, will Segment")
                var segmentedData = [Data]()
                let dataToSegment = Data(someData.dropFirst()) //Remove old header as it's going to be added in SAR
                let chunkRanges = self.calculateDataRanges(dataToSegment, withSize: 19)
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
                    chunkData.append(Data(dataToSegment[aRange]))
                    segmentedData.append(Data(chunkData))
                }
                for aSegment in segmentedData {
                    print("Sending Ack segment: \(aSegment.hexString())")
                    self.target.basePeripheral().writeValue(aSegment, for: self.dataInCharacteristic, type: .withoutResponse)
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

    var lastMessageType = 0xC0

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("Cahrcateristic value updated: \(characteristic.value!.hexString())")
        //SAR handling
        if characteristic.value![0] & 0xC0 == 0x40 {
            if lastMessageType == 0x40 {
                //Drop repeated 0x40's
                print("CMP:Reduntand SAR start, dropping")
                segmentedData = Data()
            }
            lastMessageType = 0x40
            //Add message type header
            segmentedData.append(Data([characteristic.value![0] & 0x3F]))
            segmentedData.append(Data(characteristic.value!.dropFirst()))
        } else if characteristic.value![0] & 0xC0 == 0x80 {
            lastMessageType = 0x80
            print("Segmented data cont")
            segmentedData.append(Data(characteristic.value!.dropFirst()))
        } else if characteristic.value![0] & 0xC0 == 0xC0 {
            lastMessageType = 0xC0
            print("Segmented data end")
            segmentedData.append(Data(characteristic.value!.dropFirst()))
            print("Reassembled data!: \(segmentedData.hexString())")
            //Copy data and send it to NetworkLayer
            receivedData(incomingData: Data(segmentedData))
            segmentedData = Data()
        } else {
            receivedData(incomingData: Data(characteristic.value!))
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("Characteristic notification state changed")
    }
}
