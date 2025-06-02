//
//  McuMgrSuitManifest.swift
//  iOSMcuManagerLibrary
//
//  Created by Dinesh Harjani on 19/3/24.
//

import Foundation
import SwiftCBOR

// MARK: - McuMgrSuitManifest

class McuMgrSuitManifest: CBORMappable {
    
    // MARK: Properties
    
    private var version: UInt64?
    private var sequenceNumber: UInt64?
    private var common: McuMgrSuitCommonStructure?
    
    // MARK: Init
    
    public required init(cbor: CBOR?) throws {
        try super.init(cbor: cbor)
        guard case CBOR.byteString(let byteString)? = cbor,
              let decodedCbor = try CBOR.decode(byteString) else { return }
        if case let CBOR.unsignedInt(version)? = decodedCbor[0x01] {
            self.version = version
        }
        if case let CBOR.unsignedInt(sequenceNumber)? = decodedCbor[0x02] {
            self.sequenceNumber = sequenceNumber
        }
        self.common = try? McuMgrSuitCommonStructure(cbor: decodedCbor[0x03])
    }
}

// MARK: - McuMgrSuitCommonStructure

class McuMgrSuitCommonStructure: CBORMappable {
    
    public var components: [[[UInt8]]]
    public var sharedSequences: McuMgrSuitSharedSequence?
    
    // MARK: Init
    
    public required init(cbor: CBOR?) throws {
        self.components = [[[UInt8]]]()
        try super.init(cbor: cbor)
        guard case CBOR.byteString(let byteString)? = cbor,
              let decodedCbor = try CBOR.decode(byteString) else { return }
        if case let CBOR.array(components)? = decodedCbor[0x02] {
            for cborComponent in components {
                guard case CBOR.array(let componentArray) = cborComponent else { continue }
                var component = [[UInt8]]()
                for componentBytes in componentArray {
                    guard case CBOR.byteString(let decodedBytes) = componentBytes else { continue }
                    component.append(decodedBytes)
                }
                self.components.append(component)
            }
        }
        
        if case let CBOR.byteString(sharedSequence)? = decodedCbor[0x04],
           let decodedCbor = try? CBOR.decode(sharedSequence) {
            self.sharedSequences = try? McuMgrSuitSharedSequence(cbor: decodedCbor)
        }
    }
}

// MARK: - McuMgrSuitSharedSequence

class McuMgrSuitSharedSequence: CBORMappable {
    
    public var conditionClassIdentifier: UInt64?
    
    public required init(cbor: CBOR?) throws {
        if case let CBOR.unsignedInt(classIdentifier)? = cbor?[2] {
            self.conditionClassIdentifier = classIdentifier
        }
        try super.init(cbor: cbor)
    }
}
