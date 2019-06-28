//
//  ConfigNetKeyList.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 27/06/2019.
//

import Foundation

public struct ConfigNetKeyList: ConfigMessage {
    public static let opCode: UInt32 = 0x8043
    
    public var parameters: Data? {
        return encodeIndexes(networkKeyIndexs[...])
    }
    
    public var isSegmented: Bool {
        return false
    }
    
    public let networkKeyIndexs: [KeyIndex]
    
    public init(networkKeys: [NetworkKey]) {
        self.networkKeyIndexs = networkKeys.map { return $0.index }
    }
    
    public init?(parameters: Data) {
        self.networkKeyIndexs = ConfigAppKeyList.decodeIndexes(from: parameters, at: 0)
    }
}