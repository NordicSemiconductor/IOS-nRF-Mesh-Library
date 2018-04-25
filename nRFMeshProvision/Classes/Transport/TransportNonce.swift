//
//  TransportNonce.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 26/02/2018.
//

import Foundation

public enum TransportNonceType : UInt8 {
    case Network        = 0x00
    case Application    = 0x01
    case Device         = 0x02
    case Proxy          = 0x03
}

public struct TransportNonce {
    let type: TransportNonceType
    public let data: Data
    
    public init(networkNonceWithIVIndex anIVIndex: Data, ctl aCTL: Data, ttl aTTL: Data, seq aSeq: Data, src aSRC: Data) {
        type = .Network
        let typeData = Data([self.type.rawValue])
        let ctlTTL = Data([(aCTL[0] << 7) | (aTTL[0] & 0x7F)])
        var nonceData = Data()
        nonceData.append(Data(typeData))
        nonceData.append(Data(ctlTTL))
        nonceData.append(Data(aSeq))
        nonceData.append(Data(aSRC))
        nonceData.append(Data([0x00, 0x00]))
        nonceData.append(Data(anIVIndex))
        data = Data(nonceData)
    }

    public init(appNonceWithIVIndex anIVIndex: Data, isSegmented isASegmentedMessage: Bool, seq aSeq: Data, src aSRC: Data, dst aDST: Data){
        type = .Application
        let typeData = Data([self.type.rawValue])
        var nonceData = Data()
        nonceData.append(Data(typeData))
        if isASegmentedMessage {
            //ASZMIC is assumed to be 0 for this app
            //TODO: Support both 0 and 1 ASZMIC
            nonceData.append(Data([0x00]))
            nonceData.append(Data(aSeq))
        } else {
            nonceData.append(Data([0x00]))
            nonceData.append(Data(aSeq))
        }
        nonceData.append(Data(aSRC))
        nonceData.append(Data(aDST))
        nonceData.append(Data(anIVIndex))
        data = Data(nonceData)
    }
   
    public init(deviceNonceWithIVIndex anIVIndex: Data, isSegmented isASegmentedMessage: Bool, szMIC aMICSize: UInt8, seq aSeq: Data, src aSRC: Data, dst aDST: Data) {
        type = .Device
        let typeData = Data([self.type.rawValue])
        var nonceData = Data()
        nonceData.append(Data(typeData))
        if isASegmentedMessage {
            if aMICSize == 1 {
                //64bit MIC
                nonceData.append(Data([0x80]))
            } else {
                //32bit MIC
                nonceData.append(Data([0x00]))
            }
            nonceData.append(Data(aSeq))
        } else {
            nonceData.append(Data([0x00]))
            nonceData.append(Data(aSeq))
        }
        nonceData.append(Data(aSRC))
        nonceData.append(Data(aDST))
        nonceData.append(Data(anIVIndex))
        data = Data(nonceData)
    }
   
    public init(proxyNonceWithIVIndex anIVIndex: Data, seq aSeq: Data, src aSRC: Data) {
        type = .Proxy
        let typeData = Data([self.type.rawValue])
        var nonceData = Data()
        nonceData.append(Data(typeData))
        nonceData.append(Data([0x00])) //PAD 1
        nonceData.append(Data(aSeq))
        nonceData.append(Data(aSRC))
        nonceData.append(Data([0x00, 0x00])) //PAD 2
        nonceData.append(Data(anIVIndex))
        data = nonceData
    }
}
