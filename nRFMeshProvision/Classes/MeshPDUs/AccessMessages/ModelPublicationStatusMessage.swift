//
//  ModelPublicationStatusMessage.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 18/04/2018.
//
import Foundation

public struct ModelPublicationStatusMessage {

    public var sourceAddress            : Data
    public var statusCode               : MessageStatusCodes
    public var credentialFlag           : Bool
    public var elementAddress           : Data
    public var appKeyIndex              : Data
    public var modelIdentifier          : Data
    public var publishAddress           : Data
    public var publishTTL               : Data
    public var publishPeriod            : Data
    public var publishRetransmitCount   : Data
    public var publishRetransmitInterval: Data

    public init(withPayload aPayload: Data, andSoruceAddress srcAddress: Data) {
        sourceAddress = srcAddress
        if let aStatusCode = MessageStatusCodes(rawValue: aPayload[0]) {
            statusCode = aStatusCode
        } else {
            statusCode = .success
        }
        elementAddress = Data([aPayload[2], aPayload[1]])
        publishAddress = Data([aPayload[4], aPayload[3]])
        
        appKeyIndex = Data()
        appKeyIndex.append(aPayload[6] >> 4)
        appKeyIndex.append(aPayload[6] << 4 | aPayload[5] >> 4)
        credentialFlag = (aPayload[6] & 0x08 == 0x08) //Bit 5 is the credential flag
        publishTTL = Data([aPayload[7]])
        publishPeriod = Data([aPayload[8]])
        publishRetransmitCount = Data([aPayload[9] >> 5])
        publishRetransmitInterval = Data([aPayload[9] & 0x1F])
        if aPayload.count == 12 {
            //Vendor model
            modelIdentifier = Data([aPayload[11], aPayload[10]])
        } else {
            //Sig model
            modelIdentifier = Data([
                aPayload[11], aPayload[10],
                aPayload[13], aPayload[12]
                ])
        }
    }
}
