//
//  CompositionElement.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 04/04/2018.
//

import Foundation

public struct CompositionElement: Codable {
    
    // MARK: - Properties
    var location                    : Data
    var sigModelCount               : Int
    var vendorModelCount            : Int
    var sigModels                   : [Data]
    var vendorModels                : [Data]
    var allModels                   : [Data]
    var modelKeyBindings            : [Data: Data]
    var modelPublishAddress         : [Data: Data]
    var modelSubscriptionAddresses  : [Data: [Data]]

    // MARK: - Initialization
    init(withData data: Data) {
        modelKeyBindings            = [Data: Data]()
        modelPublishAddress         = [Data: Data]()
        modelSubscriptionAddresses  = [Data: [Data]]()
        location = Data([data[1], data[0]])
        sigModelCount = Int(data[2])
        vendorModelCount = Int(data[3])
        sigModels = [Data]()
        vendorModels = [Data]()
        for aSigModelIndex in 0..<sigModelCount {
            sigModels.append(Data([data[(2 * aSigModelIndex) + 5], data[(2 * aSigModelIndex) + 4]]))
        }
        for aVendorModelIndex in 0..<vendorModelCount {
            vendorModels.append(
                Data([
                    data[(2 * sigModelCount) + (4 * aVendorModelIndex) + 5],
                    data[(2 * sigModelCount) + (4 * aVendorModelIndex) + 4],
                    data[(2 * sigModelCount) + (4 * aVendorModelIndex) + 7],
                    data[(2 * sigModelCount) + (4 * aVendorModelIndex) + 6]
                    ])
            )
        }
        allModels = [Data]()
        allModels.append(contentsOf: sigModels)
        allModels.append(contentsOf: vendorModels)
    }
    
    // MARK: - Accessors
    public func publishAddressForModelId(_ aModelId: Data) -> Data? {
        return modelPublishAddress[aModelId]
    }
    
    public func subscriptionAddressesForModelId(_ aModelId: Data) -> [Data]? {
        return modelSubscriptionAddresses[aModelId]
    }
    
    public func boundAppKeyIndexForModelId(_ aModelId: Data) -> Data? {
        return modelKeyBindings[aModelId]
    }

    public mutating func setPublishAddress(_ anAddress: Data, forModelId aModelId: Data) {
        modelPublishAddress[aModelId] = anAddress
    }

    public mutating func removeSubscriptionAddress(_ anAddress: Data, forModelId aModelId: Data) {
        if modelSubscriptionAddresses[aModelId] == nil {
            return
        }
        if let foundIndex = modelSubscriptionAddresses[aModelId]!.index(of: anAddress) {
            modelSubscriptionAddresses[aModelId]?.remove(at: foundIndex)
        }
    }

    public mutating func addSubscriptionAddress(_ anAddress: Data, forModelId aModelId: Data) {
        if modelSubscriptionAddresses[aModelId] == nil {
            modelSubscriptionAddresses[aModelId] = [Data]()
        }
        if !modelSubscriptionAddresses[aModelId]!.contains(anAddress) {
            modelSubscriptionAddresses[aModelId]!.append(anAddress)
        }
    }

    public mutating func removeKeyBinding(_ aKey: Data, forModelId aModelId: Data) {
        if let modelIndex = modelKeyBindings.index(forKey: aModelId) {
            modelKeyBindings.remove(at: modelIndex)
        }
    }
    public mutating func setKeyBinding(_ aKey: Data, forModelId aModelId: Data) {
        if modelKeyBindings[aModelId] == nil {
            modelKeyBindings[aModelId] = aKey
        } else {
            if let modelIndex = modelKeyBindings.index(forKey: aModelId) {
                //Replace old value with newer one
                modelKeyBindings.remove(at: modelIndex)
                modelKeyBindings[aModelId] = aKey
            }
        }
    }

    public func allSigAndVendorModels() -> [Data] {
        return allModels
    }

    public func allVendorModels() -> [Data] {
        return vendorModels
    }

    public func allSigModels() -> [Data] {
        return sigModels
    }

    public func totalModelCount() -> Int {
        return allModels.count
    }
    
    public func elementLocation() -> Data {
        return location;
    }
}
