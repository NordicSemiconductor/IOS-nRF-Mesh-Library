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
        guard data.count == 11 else {
            return nil
        }
        numberOfElements = data.convert(offset: 0)
        algorithms = Algorithms(data: data, offset: 1)
        publicKeyType = PublicKeyType(data: data, offset: 3)
        staticOobType = StaticOobType(data: data, offset: 4)
        outputOobSize = data.convert(offset: 5)
        outputOobActions = OutputOobActions(data: data, offset: 6)
        inputOobSize = data.convert(offset: 8)
        inputOobActions = InputOobActions(data: data, offset: 9)
    }
}

extension ProvisioningCapabilities: CustomStringConvertible {
    
    public var description: String {
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
