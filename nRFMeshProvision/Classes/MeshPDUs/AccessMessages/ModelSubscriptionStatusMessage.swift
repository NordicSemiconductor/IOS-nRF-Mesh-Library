//
//  ModelSubscriptionStatusMessage.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 30/04/2018.
//
import Foundation

public struct ModelSubscriptionStatusMessage {

    public var sourceAddress            : Data
    public var statusCode               : MessageStatusCodes
    public var elementAddress           : Data
    public var subscriptionAddress      : Data
    public var modelIdentifier          : Data

    public init(withPayload aPayload: Data, andSoruceAddress srcAddress: Data) {
        sourceAddress = srcAddress
        if let aStatusCode = MessageStatusCodes(rawValue: aPayload[0]) {
            statusCode = aStatusCode
        } else {
            statusCode = .success
        }
        elementAddress      = Data([aPayload[2], aPayload[1]])
        subscriptionAddress = Data([aPayload[4], aPayload[3]])
        if aPayload.count == 7 {
            //Vendor model
            modelIdentifier = Data([aPayload[6], aPayload[5]])
        } else {
            //Sig model
            modelIdentifier = Data([
                aPayload[6], aPayload[5],
                aPayload[8], aPayload[7]
                ])
        }
    }
}
