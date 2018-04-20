//
//  CompositionElement.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 04/04/2018.
//

import Foundation

public struct CompositionElement: Codable {
    
    // MARK: - Properties
    var location: Data
    var sigModelCount: Int
    var vendorModelCount: Int
    var sigModels: [Data]
    var vendorModels: [Data]
    var allModels: [Data]

    // MARK: - Initialization
    init(withData data: Data) {
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
}
