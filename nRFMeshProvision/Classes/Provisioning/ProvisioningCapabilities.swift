//
//  ProvisioningCapabilities.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 07/05/2019.
//

import Foundation

public struct ProvisioningCapabilities {
    /// Number of elements supported by the device.
    public let numberOfElements: UInt8
    /// Supported algorithms and other capabilities.
    public let algorithms:       Algorithms
    /// Supported public key types.
    public let publicKeyType:    PublicKeyType
    /// Supported statuc OOB Types.
    public let staticOobType:    StaticOobType
    /// Maximum size of Output OOB supported.
    public let outputOobSize:    UInt8
    /// Supoprted Output OOB Actions.
    public let outputOobActions: OutputOobActions
    /// Maximum size of Input OOB supported.
    public let inputOobSize:     UInt8
    /// Supoprted Input OOB Actions.
    public let inputOobActions:  InputOobActions
    
    init?(_ data: Data) {
        guard data.count == 12 && data[0] == ProvisioningPduType.capabilities.type else {
            return nil
        }
        numberOfElements = data.read(fromOffset: 1)
        algorithms       = Algorithms(data: data, offset: 2)
        publicKeyType    = PublicKeyType(data: data, offset: 4)
        staticOobType    = StaticOobType(data: data, offset: 5)
        outputOobSize    = data.read(fromOffset: 6)
        outputOobActions = OutputOobActions(data: data, offset: 7)
        inputOobSize     = data.read(fromOffset: 9)
        inputOobActions  = InputOobActions(data: data, offset: 10)
    }
}

extension ProvisioningCapabilities: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return """
        Number of elements: \(numberOfElements)
        Algorithms: \(algorithms)
        Public Key Type: \(publicKeyType)
        Static OOB Type: \(staticOobType)
        Output OOB Size: \(outputOobSize)
        Output OOB Actions: \(outputOobActions)
        Input OOB Size: \(inputOobSize)
        Input OOB Actions: \(inputOobActions)
        """
    }
    
}
