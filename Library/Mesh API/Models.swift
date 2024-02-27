/*
* Copyright (c) 2019, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

import Foundation

public extension Model {
    
    /// Returns whether the Model is subscribed to the given ``Group``.
    ///
    /// - parameter group: The Group to check subscription to.
    /// - returns: `True` if the Model is subscribed to the Group,
    ///            `false` otherwise.
    func isSubscribed(to group: Group) -> Bool {
        return isSubscribed(to: group.address)
    }
    
    /// Returns whether the Model is subscribed to the given ``MeshAddress``.
    ///
    /// - parameter address: The address to check subscription to.
    /// - returns: `True` if the Model is subscribed to a ``Group`` with given,
    ///            address, `false` otherwise.
    func isSubscribed(to address: MeshAddress) -> Bool {
        return subscribe.contains(address.hex)
    }
    
    /// Whether the Model supports model publication defined in Section 4.2.3 in
    /// Bluetooth Mesh Profile 1.0.1 specification.
    ///
    /// - returns: `true` if the model supports model publication, `false` ir it doesn't
    ///            or `nil` if unknown.
    /// - since: 4.0.0
    var supportsModelPublication: Bool? {
        if !isBluetoothSIGAssigned {
            return nil
        }
        switch modelIdentifier {
        // Foundation
        case .configurationServerModelId: return false
        case .configurationClientModelId: return false
        case .healthServerModelId: return true
        case .healthClientModelId: return true
        // Configuration models added in Mesh Protocol 1.1
        case .remoteProvisioningServerModelId: return false
        case .remoteProvisioningClientModelId: return false
        case .directedForwardingConfigurationServerModelId: return false
        case .directedForwardingConfigurationClientModelId: return false
        case .bridgeConfigurationServerModelId: return false
        case .bridgeConfigurationClientModelId: return false
        case .privateBeaconServerModelId: return false
        case .privateBeaconClientModelId: return false
        case .onDemandPrivateProxyServerModelId: return false
        case .onDemandPrivateProxyClientModelId: return false
        case .sarConfigurationServerModelId: return false
        case .sarConfigurationClientModelId: return false
        case .opcodesAggregatorServerModelId: return false
        case .opcodesAggregatorClientModelId: return false
        case .largeCompositionDataServerModelId: return false
        case .largeCompositionDataClientModelId: return false
        case .solicitationPduRplConfigurationServerModelId: return false
        case .solicitationPduRplConfigurationClientModelId: return false
        // Generic
        case .genericOnOffServerModelId: return true
        case .genericOnOffClientModelId: return true
        case .genericLevelServerModelId: return true
        case .genericLevelClientModelId: return true
        case .genericDefaultTransitionTimeServerModelId: return true
        case .genericDefaultTransitionTimeClientModelId: return true
        case .genericPowerOnOffServerModelId: return true
        case .genericPowerOnOffSetupServerModelId: return false
        case .genericPowerOnOffClientModelId: return true
        case .genericPowerLevelServerModelId: return true
        case .genericPowerLevelSetupServerModelId: return false
        case .genericPowerLevelClientModelId: return true
        case .genericBatteryServerModelId: return true
        case .genericBatteryClientModelId: return true
        case .genericLocationServerModelId: return true
        case .genericLocationSetupServerModelId: return false
        case .genericLocationClientModelId: return true
        case .genericAdminPropertyServerModelId: return true
        case .genericManufacturerPropertyServerModelId: return true
        case .genericUserPropertyServerModelId: return true
        case .genericClientPropertyServerModelId: return true
        case .genericPropertyClientModelId: return true
        // Sensors
        case .sensorServerModelId: return true
        case .sensorSetupServerModelId: return true
        case .sensorClientModelId: return true
        // Time and Scenes
        case .timeServerModelId: return true
        case .timeSetupServerModelId: return false
        case .timeClientModelId: return true
        case .sceneServerModelId: return true
        case .sceneSetupServerModelId: return false
        case .sceneClientModelId: return true
        case .schedulerServerModelId: return true
        case .schedulerSetupServerModelId: return false
        case .schedulerClientModelId: return true
        // Lighting
        case .lightLightnessServerModelId: return true
        case .lightLightnessSetupServerModelId: return false
        case .lightLightnessClientModelId: return true
        case .lightCTLServerModelId: return true
        case .lightCTLSetupServerModelId: return false
        case .lightCTLClientModelId: return true
        case .lightCTLTemperatureServerModelId: return true
        case .lightHSLServerModelId: return true
        case .lightHSLSetupServerModelId: return false
        case .lightHSLClientModelId: return true
        case .lightHSLHueServerModelId: return true
        case .lightHSLSaturationServerModelId: return true
        case .lightXyLServerModelId: return true
        case .lightXyLSetupServerModelId: return false
        case .lightXyLClientModelId: return true
        case .lightLCServerModelId: return true
        case .lightLCSetupServerModelId: return true
        case .lightLCClientModelId: return true
        default: return nil
        }
    }
    
    /// Whether the Model supports model subscription defined in Section 4.2.4 in
    /// Bluetooth Mesh Profile 1.0.1 specification.
    ///
    /// - returns: `true` if the model supports model subscription, `false` ir it doesn't
    ///            or `nil` if unknown.
    /// - since: 4.0.0
    var supportsModelSubscriptions: Bool? {
        if !isBluetoothSIGAssigned {
            return nil
        }
        switch modelIdentifier {
        // Foundation
        case .configurationServerModelId: return false
        case .configurationClientModelId: return false
        case .healthServerModelId: return true
        case .healthClientModelId: return true
        // Configuration models added in Mesh Protocol 1.1
        case .remoteProvisioningServerModelId: return false
        case .remoteProvisioningClientModelId: return false
        case .directedForwardingConfigurationServerModelId: return false
        case .directedForwardingConfigurationClientModelId: return false
        case .bridgeConfigurationServerModelId: return false
        case .bridgeConfigurationClientModelId: return false
        case .privateBeaconServerModelId: return false
        case .privateBeaconClientModelId: return false
        case .onDemandPrivateProxyServerModelId: return false
        case .onDemandPrivateProxyClientModelId: return false
        case .sarConfigurationServerModelId: return false
        case .sarConfigurationClientModelId: return false
        case .opcodesAggregatorServerModelId: return false
        case .opcodesAggregatorClientModelId: return false
        case .largeCompositionDataServerModelId: return false
        case .largeCompositionDataClientModelId: return false
        case .solicitationPduRplConfigurationServerModelId: return false
        case .solicitationPduRplConfigurationClientModelId: return false
        // Generic
        case .genericOnOffServerModelId: return true
        case .genericOnOffClientModelId: return true
        case .genericLevelServerModelId: return true
        case .genericLevelClientModelId: return true
        case .genericDefaultTransitionTimeServerModelId: return true
        case .genericDefaultTransitionTimeClientModelId: return true
        case .genericPowerOnOffServerModelId: return true
        case .genericPowerOnOffSetupServerModelId: return true
        case .genericPowerOnOffClientModelId: return true
        case .genericPowerLevelServerModelId: return true
        case .genericPowerLevelSetupServerModelId: return true
        case .genericPowerLevelClientModelId: return true
        case .genericBatteryServerModelId: return true
        case .genericBatteryClientModelId: return true
        case .genericLocationServerModelId: return true
        case .genericLocationSetupServerModelId: return true
        case .genericLocationClientModelId: return true
        case .genericAdminPropertyServerModelId: return true
        case .genericManufacturerPropertyServerModelId: return true
        case .genericUserPropertyServerModelId: return true
        case .genericClientPropertyServerModelId: return true
        case .genericPropertyClientModelId: return true
        // Sensors
        case .sensorServerModelId: return true
        case .sensorSetupServerModelId: return true
        case .sensorClientModelId: return true
        // Time and Scenes
        case .timeServerModelId: return true
        case .timeSetupServerModelId: return false
        case .timeClientModelId: return true
        case .sceneServerModelId: return true
        case .sceneSetupServerModelId: return true
        case .sceneClientModelId: return true
        case .schedulerServerModelId: return true
        case .schedulerSetupServerModelId: return true
        case .schedulerClientModelId: return true
        // Lighting
        case .lightLightnessServerModelId: return true
        case .lightLightnessSetupServerModelId: return true
        case .lightLightnessClientModelId: return true
        case .lightCTLServerModelId: return true
        case .lightCTLSetupServerModelId: return true
        case .lightCTLClientModelId: return true
        case .lightCTLTemperatureServerModelId: return true
        case .lightHSLServerModelId: return true
        case .lightHSLSetupServerModelId: return true
        case .lightHSLClientModelId: return true
        case .lightHSLHueServerModelId: return true
        case .lightHSLSaturationServerModelId: return true
        case .lightXyLServerModelId: return true
        case .lightXyLSetupServerModelId: return true
        case .lightXyLClientModelId: return true
        case .lightLCServerModelId: return true
        case .lightLCSetupServerModelId: return true
        case .lightLCClientModelId: return true
        default: return nil
        }
    }
    
    /// A list of direct base ``Model``s to the Model.
    ///
    /// The *Extend* relationship is explained in Mesh Profile 1.0.1, chapter 2.3.6.
    ///
    /// - note: Models that operate on bound states share a single instance of a Subscription List per Element.
    ///
    /// - note: Model extension is only defined for SIG Models. Currently it is not possible to
    ///         get relationships between Vendor Models, and for those this method returns an empty list.
    /// - since: 4.0.0
    var directBaseModels: [Model] {
        // The Model must be on an Element on a Node.
        guard let parentElement = parentElement,
              let node = parentElement.parentNode else {
            return []
        }
        // Get all direct base models of this Model.
        return node.elements
            // Look only on that and previous Elements.
            // Models can't extend Models on Elements with higher index.
            .filter { $0.index <= parentElement.index }
            // Sort in reverse order so that unifying the list will
            // remove those on Elements with lowest indexes.
            .sorted { $0.index > $1.index }
            // Get a list of all models.
            .flatMap { $0.models }
            // Remove duplicates.
            .uniqued()
            // Get all direct base models of this Model.
            .filter { extendsDirectly($0) }
    }
    
    /// A list of all ``Model``s extended by this Model, directly or indirectly.
    ///
    /// The *Extend* relationship is explained in Mesh Profile 1.0.1, chapter 2.3.6.
    ///
    /// - note: Models that operate on bound states share a single instance of a Subscription List per Element.
    ///
    /// - note: Model extension is only defined for SIG Models. Currently it is not possible to
    ///         get relationships between Vendor Models, and for those this method returns an empty list.
    /// - since: 4.0.0
    var baseModels: [Model] {
        let models = directBaseModels
        // Return the direct base Models and all models that they extend.
        return models + models.flatMap { $0.baseModels }
    }
    
    /// A list of ``Model``s directly extending this Model.
    ///
    /// The *Extend* relationship is explained in Mesh Profile 1.0.1, chapter 2.3.6.
    ///
    /// - note: Models that operate on bound states share a single instance of a Subscription List per Element.
    ///
    /// - note: Model extension is only defined for SIG Models. Currently it is not possible to
    ///         get relationships between Vendor Models, and for those this method returns an empty list.
    /// - since: 4.0.0
    var directExtendingModels: [Model] {
        // The Model must be on an Element on a Node.
        guard let parentElement = parentElement,
              let node = parentElement.parentNode else {
            return []
        }
        // Get all models directly extending this Model.
        return node.elements
            // Look only on that and next Elements.
            // Models can't be extended by Models on Elements with lower index.
            .filter { $0.index >= parentElement.index }
            // Get a list of all models.
            .flatMap { $0.models }
            // Remove duplicates.
            .uniqued()
            // Get all models directly extending this Model.
            .filter { $0.extendsDirectly(self) }
    }
    
    /// A list of all ``Model``s extending this Model, directly and indirectly
    ///
    /// The *Extend* relationship is explained in Mesh Profile 1.0.1, chapter 2.3.6.
    ///
    /// - note: Models that operate on bound states share a single instance of a Subscription List per Element.
    ///
    /// - note: Model extension is only defined for SIG Models. Currently it is not possible to
    ///         get relationships between Vendor Models, and for those this method returns an empty list.
    /// - since: 4.0.0
    var extendingModels: [Model] {
        let models = directExtendingModels
        // Return the extending Models and all models that they extend.
        return models + models.flatMap { $0.extendingModels }
    }
    
    /// Returns all ``Model`` instances that are in a hierarchy of *Extend* relationship with this Model.
    ///
    /// The *Extend* relationship is explained in Mesh Profile 1.0.1, chapter 2.3.6.
    ///
    /// - note: Models that operate on bound states share a single instance of a Subscription List per Element.
    ///
    /// - note: Model extension is only defined for SIG Models. Currently it is not possible to
    ///         get relationships between Vendor Models, and for those this method returns an empty list.
    /// - since: 4.0.0
    var relatedModels: [Model] {
        // The Model must be on an Element on a Node.
        guard let parentElement = parentElement,
              let node = parentElement.parentNode else {
            return []
        }
        // Get a list of all models on the Node.
        let models = node.elements
            .flatMap { $0.models }
        
        var result = [Model]()
        var queue = [self]
        
        while !queue.isEmpty {
            let currentModel = queue.removeFirst()
            if !result.contains(currentModel) {
                if currentModel != self {
                    result.append(currentModel)
                }
                let directlyExtendedModels = models.filter { $0.extendsDirectly(currentModel) }
                queue.append(contentsOf: directlyExtendedModels)
                let extendedByModels = models.filter { currentModel.extendsDirectly($0) }
                queue.append(contentsOf: extendedByModels)
            }
        }
        
        return result.sorted {
            if $0.parentElement!.index != $1.parentElement!.index {
                return $0.parentElement!.index < $1.parentElement!.index
            }
            return $0.modelId < $1.modelId
        }
    }
    
    /// Returns whether that Model extends the given ``Model`` directly or indirectly.
    ///
    /// If a Model A extends B, which extends C, this method will return `true` if checked with A and C.
    /// Base Models may be on the same Element or on an Element with a lower index.
    ///
    /// The *Extend* relationship is explained in Mesh Profile 1.0.1, chapter 2.3.6.
    ///
    /// - note: Models that operate on bound states share a single instance of a Subscription List per Element.
    ///
    /// - note: Model extension is only defined for SIG Models. Currently it is not possible to
    ///         get relationships between Vendor Models, and for those this method returns `false`.
    ///
    /// - parameter model: A Model to be checked.
    /// - returns: `True` if the given Model is a direct or indirect *base* Model of that one,
    ///            `false` otherwise.
    /// - since: 4.0.0
    func extends(_ model: Model) -> Bool {
        // The Models must be on the same Node.
        guard let parentElement = parentElement,
              let otherParentElement = model.parentElement,
              let node = parentElement.parentNode,
              let otherNode = otherParentElement.parentNode,
              node === otherNode else {
            return false
        }
        return baseModels.contains(model)
    }
    
    /// Returns whether that Model directly extends the given ``Model``.
    ///
    /// This method only checks direct Extend relationship, not hierarchical. If a Model A extends B,
    /// which extends C, this method will return `false` if checked with A and C. Base Models
    /// may be on the same Element or on an Element with a lower index.
    ///
    /// The *Extend* relationship is explained in Mesh Profile 1.0.1, chapter 2.3.6.
    ///
    /// - note: Models in Extend relationship share their Subscription List if they are on the same Element.
    ///
    /// - note: Model extension is only defined for SIG Models. Currently it is not possible to
    ///         get relationships between Vendor Models, and for those this method returns `false`.
    ///
    /// - parameter model: A Model to be checked.
    /// - returns: `True` if the given Model is a *base* Model of that one,
    ///            `false` otherwise.
    /// - since: 4.0.0            
    func extendsDirectly(_ model: Model) -> Bool {
        // The Models must be on the same Node.
        guard let parentElement = parentElement,
              let otherParentElement = model.parentElement,
              let node = parentElement.parentNode,
              let otherNode = otherParentElement.parentNode,
              node === otherNode else {
            return false
        }
        // Model can't extend itself or any other instance of the same model.
        if modelIdentifier == model.modelIdentifier {
            return false
        }
        // Currently, it is not possible to get relationships between Vendor models.
        if !isBluetoothSIGAssigned || !model.isBluetoothSIGAssigned {
            return false
        }
        // Check Models on the same Element.
        if model.parentElement == parentElement {
            switch modelIdentifier {
            // Configuration models added in Mesh Protocol 1.1
            case .directedForwardingConfigurationServerModelId,
                 .bridgeConfigurationServerModelId,
                 .privateBeaconServerModelId,
                 .largeCompositionDataServerModelId:
                return model.modelIdentifier == .configurationServerModelId
            case .onDemandPrivateProxyServerModelId:
                return model.modelIdentifier == .privateBeaconServerModelId
            // Generics
            case .genericPowerOnOffServerModelId:
                return model.modelIdentifier == .genericOnOffServerModelId
            case .genericPowerOnOffSetupServerModelId:
                return model.modelIdentifier == .genericPowerOnOffServerModelId ||
                       model.modelIdentifier == .genericDefaultTransitionTimeServerModelId
            case .genericPowerLevelServerModelId:
                return model.modelIdentifier == .genericPowerOnOffServerModelId ||
                       model.modelIdentifier == .genericLevelServerModelId
            case .genericPowerLevelSetupServerModelId:
                return model.modelIdentifier == .genericPowerLevelServerModelId ||
                       model.modelIdentifier == .genericPowerOnOffSetupServerModelId
            case .genericLocationSetupServerModelId:
                return model.modelIdentifier == .genericLocationServerModelId
            case .genericAdminPropertyServerModelId, .genericManufacturerPropertyServerModelId:
                return model.modelIdentifier == .genericUserPropertyServerModelId
            // Sensors
            case .sensorSetupServerModelId:
                return model.modelIdentifier == .sensorServerModelId
            // Time and Scenes
            case .timeSetupServerModelId:
                return model.modelIdentifier == .timeServerModelId
            case .sceneSetupServerModelId:
                return model.modelIdentifier == .sceneServerModelId ||
                       model.modelIdentifier == .genericDefaultTransitionTimeServerModelId
            case .schedulerSetupServerModelId:
                return model.modelIdentifier == .schedulerServerModelId
            // Lighting
            case .lightLightnessServerModelId:
                return model.modelIdentifier == .genericPowerOnOffServerModelId ||
                       model.modelIdentifier == .genericLevelServerModelId
            case .lightLightnessSetupServerModelId:
                return model.modelIdentifier == .lightLightnessServerModelId ||
                       model.modelIdentifier == .genericPowerOnOffSetupServerModelId
            case .lightCTLServerModelId,
                 .lightHSLServerModelId,
                 .lightXyLServerModelId:
                return model.modelIdentifier == .lightLightnessServerModelId
            case .lightCTLTemperatureServerModelId,
                 .lightHSLHueServerModelId,
                 .lightHSLSaturationServerModelId:
                return model.modelIdentifier == .genericLevelServerModelId
            case .lightCTLSetupServerModelId:
                return model.modelIdentifier == .lightCTLServerModelId ||
                       model.modelIdentifier == .lightLightnessSetupServerModelId
            case .lightHSLSetupServerModelId:
                return model.modelIdentifier == .lightHSLServerModelId ||
                       model.modelIdentifier == .lightLightnessSetupServerModelId
            case .lightXyLSetupServerModelId:
                return model.modelIdentifier == .lightXyLServerModelId ||
                       model.modelIdentifier == .lightLightnessSetupServerModelId
            case .lightLCServerModelId:
                // It also extends a Light Lightness Server on another Element.
                return model.modelIdentifier == .genericOnOffServerModelId
            case .lightLCSetupServerModelId:
                return model.modelIdentifier == .lightLCServerModelId
            // Device Firmware Update
            case .firmwareUpdateServer,
                 .firmwareDistributionServer:
                return model.modelIdentifier == .blobTransferServer
            default:
                return false
            }
        } else {
            // Some features are split into 2 Elements.
            switch modelIdentifier {
            case .lightLCServerModelId:
                // Light LC Server Model extends a Light Lightness Server
                // Model that cannot be on the same Element.
                // Search for a Model on an Element with lower Index.
                let modelWithLightLigthnessServer = node.elements
                    // Filter to Elements with lower Index number.
                    .filter { $0.index < parentElement.index }
                    // Reverse the ordering to look for a first Element with LLS model.
                    .sorted { $0.index > $1.index }
                    // Find an Element with Light Lightness Server model.
                    .first { $0.contains(modelWithSigModelId: .lightLightnessServerModelId) }?
                    // And return that model.
                    .model(withSigModelId: .lightLightnessServerModelId)
                return model === modelWithLightLigthnessServer
            default:
                return false
            }
        }
    }
    
}

public extension UInt16 {
    // Foundation
    static let configurationServerModelId: UInt16 = 0x0000
    static let configurationClientModelId: UInt16 = 0x0001
    static let healthServerModelId: UInt16 = 0x0002
    static let healthClientModelId: UInt16 = 0x0003
    // Configuration models added in Mesh Protocol 1.1
    static let remoteProvisioningServerModelId: UInt16 = 0x0004
    static let remoteProvisioningClientModelId: UInt16 = 0x0005
    static let directedForwardingConfigurationServerModelId: UInt16 = 0x0006
    static let directedForwardingConfigurationClientModelId: UInt16 = 0x0007
    static let bridgeConfigurationServerModelId: UInt16 = 0x0008
    static let bridgeConfigurationClientModelId: UInt16 = 0x0009
    static let privateBeaconServerModelId: UInt16 = 0x000A
    static let privateBeaconClientModelId: UInt16 = 0x000B
    static let onDemandPrivateProxyServerModelId: UInt16 = 0x000C
    static let onDemandPrivateProxyClientModelId: UInt16 = 0x000D
    static let sarConfigurationServerModelId: UInt16 = 0x000E
    static let sarConfigurationClientModelId: UInt16 = 0x000F
    static let opcodesAggregatorServerModelId: UInt16 = 0x0010
    static let opcodesAggregatorClientModelId: UInt16 = 0x0011
    static let largeCompositionDataServerModelId: UInt16 = 0x0012
    static let largeCompositionDataClientModelId: UInt16 = 0x0013
    static let solicitationPduRplConfigurationServerModelId: UInt16 = 0x0014
    static let solicitationPduRplConfigurationClientModelId: UInt16 = 0x0015
    // Generic
    static let genericOnOffServerModelId: UInt16 = 0x1000
    static let genericOnOffClientModelId: UInt16 = 0x1001
    static let genericLevelServerModelId: UInt16 = 0x1002
    static let genericLevelClientModelId: UInt16 = 0x1003
    static let genericDefaultTransitionTimeServerModelId: UInt16 = 0x1004
    static let genericDefaultTransitionTimeClientModelId: UInt16 = 0x1005
    static let genericPowerOnOffServerModelId: UInt16 = 0x1006
    static let genericPowerOnOffSetupServerModelId: UInt16 = 0x1007
    static let genericPowerOnOffClientModelId: UInt16 = 0x1008
    static let genericPowerLevelServerModelId: UInt16 = 0x1009
    static let genericPowerLevelSetupServerModelId: UInt16 = 0x100A
    static let genericPowerLevelClientModelId: UInt16 = 0x100B
    static let genericBatteryServerModelId: UInt16 = 0x100C
    static let genericBatteryClientModelId: UInt16 = 0x100D
    static let genericLocationServerModelId: UInt16 = 0x100E
    static let genericLocationSetupServerModelId: UInt16 = 0x100F
    static let genericLocationClientModelId: UInt16 = 0x1010
    static let genericAdminPropertyServerModelId: UInt16 = 0x1011
    static let genericManufacturerPropertyServerModelId: UInt16 = 0x1012
    static let genericUserPropertyServerModelId: UInt16 = 0x1013
    static let genericClientPropertyServerModelId: UInt16 = 0x1014
    static let genericPropertyClientModelId: UInt16 = 0x1015
    // Sensors
    static let sensorServerModelId: UInt16 = 0x1100
    static let sensorSetupServerModelId: UInt16 = 0x1101
    static let sensorClientModelId: UInt16 = 0x1102
    // Time and Scenes
    static let timeServerModelId: UInt16 = 0x1200
    static let timeSetupServerModelId: UInt16 = 0x1201
    static let timeClientModelId: UInt16 = 0x1202
    static let sceneServerModelId: UInt16 = 0x1203
    static let sceneSetupServerModelId: UInt16 = 0x1204
    static let sceneClientModelId: UInt16 = 0x1205
    static let schedulerServerModelId: UInt16 = 0x1206
    static let schedulerSetupServerModelId: UInt16 = 0x1207
    static let schedulerClientModelId: UInt16 = 0x1208
    // Lighting
    static let lightLightnessServerModelId: UInt16 = 0x1300
    static let lightLightnessSetupServerModelId: UInt16 = 0x1301
    static let lightLightnessClientModelId: UInt16 = 0x1302
    static let lightCTLServerModelId: UInt16 = 0x1303
    static let lightCTLSetupServerModelId: UInt16 = 0x1304
    static let lightCTLClientModelId: UInt16 = 0x1305
    static let lightCTLTemperatureServerModelId: UInt16 = 0x1306
    static let lightHSLServerModelId: UInt16 = 0x1307
    static let lightHSLSetupServerModelId: UInt16 = 0x1308
    static let lightHSLClientModelId: UInt16 = 0x1309
    static let lightHSLHueServerModelId: UInt16 = 0x130A
    static let lightHSLSaturationServerModelId: UInt16 = 0x130B
    static let lightXyLServerModelId: UInt16 = 0x130C
    static let lightXyLSetupServerModelId: UInt16 = 0x130D
    static let lightXyLClientModelId: UInt16 = 0x130E
    static let lightLCServerModelId: UInt16 = 0x130F
    static let lightLCSetupServerModelId: UInt16 = 0x1310
    static let lightLCClientModelId: UInt16 = 0x1311
    // BLOB Transfer
    static let blobTransferServer: UInt16 = 0x1400
    static let blonTransferClient: UInt16 = 0x1401
    // Device Firmware Update
    static let firmwareUpdateServer: UInt16 = 0x1402
    static let firmwareUpdateClient: UInt16 = 0x1403
    static let firmwareDistributionServer: UInt16 = 0x1404
    static let firmwareDistributionClient: UInt16 = 0x1405
}
