/*
* Copyright (c) 2024, Nordic Semiconductor
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

/// A stub implementation of Health Server model.
///
/// To test ``HealthFaultGet`` send a ``HealthFaultTest``
/// with an expected id of a fault set as ``HealthFaultTest/testId``.
/// The fault will be added to the Registered Fault state.
///
// TODO: Currently, the Current Fault state always contains no faults.
class HealthServerHandler: ModelDelegate {
    private weak var meshNetwork: MeshNetwork!
    private weak var manager: MeshNetworkManager!
    
    /// Identifier of a most recently performed self-test/
    private var mostRecentTestId: UInt8 = 0
    /// The Current Fault state is empty when no warning or error condition is present.
    ///
    /// The FaultArray reflects a real-time state. This means when a fault condition arises,
    /// a corresponding record is present in the state and when a fault condition is not present,
    /// the corresponding record is removed from the state automatically.
    private var currentFaultState: [HealthFault] = [] {
        didSet {
            if let manager = manager {
                publish(using: manager)
            }
            
            // Whenever a fault condition has been present in the
            // Current Fault state, the corresponding record is added
            // to the Registered Fault state.
            if !currentFaultState.isEmpty {
                registeredFaultState = currentFaultState
            }
        }
    }
    /// Whenever a fault condition has been present in the Current Fault state,
    /// the corresponding record is added to the Registered Fault state.
    ///
    /// The FaultArray is cleared with a dedicated Health Fault Clear message
    private var registeredFaultState: [HealthFault] = []
    /// The Company Identifier (CID) of Nordic Semiconductor ASA.
    private let nordicSemiconductor: UInt16 = 0x0059
    /// Returns the Company Identifier (CID) of the local Node.
    private var companyIdentifier: UInt16 {
        // Defaults to Nordic Semiconductor
        return meshNetwork?.localProvisioner?.node?.companyIdentifier ?? nordicSemiconductor
    }
    
    var messageTypes: [UInt32 : MeshMessage.Type]
    var isSubscriptionSupported: Bool = true
    var publicationMessageComposer: MessageComposer? {
        func compose() -> MeshMessage {
            return HealthCurrentStatus(
                testId: mostRecentTestId,
                companyIdentifier: companyIdentifier,
                faults: currentFaultState
            )
        }
        let status = compose()
        return {
            return status
        }
    }
    
    // TODO: Add some API to emulate faults
    
    init(_ meshNetwork: MeshNetwork?, _ manager: MeshNetworkManager) {
        let types: [StaticMeshMessage.Type] = [
            HealthFaultGet.self,
            HealthFaultClear.self,
            HealthFaultClearUnacknowledged.self,
            HealthFaultTest.self,
            HealthFaultTestUnacknowledged.self,
            HealthAttentionGet.self,
            HealthAttentionSet.self,
            HealthAttentionSetUnacknowledged.self,
            HealthPeriodGet.self,
            HealthPeriodSet.self,
            HealthPeriodSetUnacknowledged.self
        ]
        self.messageTypes = types.toMap()
        self.meshNetwork = meshNetwork
        self.manager = manager
    }
    
    func model(_ model: Model, didReceiveAcknowledgedMessage request: any AcknowledgedMeshMessage,
               from source: Address, sentTo destination: MeshAddress) throws -> any MeshResponse {
        switch request {
            
        case is HealthAttentionGet, is HealthAttentionSet:
            // Attention Timer isn't supported.
            return HealthAttentionStatus()
            
        case is HealthPeriodGet, is HealthPeriodSet:
            // This library does not support Fast Period Divisor.
            // Value 0 means, that the publishing will be using
            // Publish Period without any divisor.
            return HealthPeriodStatus(fastPeriodDivisor: 0)
            
        case let request as HealthFaultGet:
            guard request.companyIdentifier == companyIdentifier else {
                throw ModelError.invalidMessage
            }
            return HealthFaultStatus(
                testId: mostRecentTestId,
                companyIdentifier: companyIdentifier,
                faults: registeredFaultState
            )
            
        case let request as HealthFaultTest:
            // This code allows testing Faults.
            // When HealthFaultTest is sent with Company ID = Nordic Semiconductor (0059),
            // and the "testID" is grater than 0, the fault with the ID equal to the testID
            // is added to the Registered Fault state.
            if request.companyIdentifier == nordicSemiconductor && request.testId > 0,
               let fault = HealthFault.fromId(request.testId) {
                registeredFaultState.append(fault)
            }
            
            guard request.companyIdentifier == companyIdentifier else {
                throw ModelError.invalidMessage
            }
            mostRecentTestId = request.testId
            return HealthFaultStatus(
                testId: mostRecentTestId,
                companyIdentifier: companyIdentifier,
                faults: registeredFaultState
            )
            
        case let request as HealthFaultClear:
            guard request.companyIdentifier == companyIdentifier else {
                throw ModelError.invalidMessage
            }
            registeredFaultState.removeAll()
            return HealthFaultStatus(
                testId: mostRecentTestId,
                companyIdentifier: companyIdentifier
            )
            
        default:
            fatalError("Message not supported: \(request)")
        }
    }
    
    func model(_ model: Model, didReceiveUnacknowledgedMessage message: any UnacknowledgedMeshMessage,
               from source: Address, sentTo destination: MeshAddress) {
        switch message {
            
        case is HealthAttentionSetUnacknowledged,
             is HealthPeriodSetUnacknowledged:
            // This library supports neither of these states.
            break;
            
        case let request as HealthFaultTestUnacknowledged:
            // This code allows testing Faults.
            // When HealthFaultTest is sent with Company ID = Nordic Semiconductor (0059),
            // and the "testID" is grater than 0, the fault with the ID equal to the testID
            // is added to the Registered Fault state.
            if request.companyIdentifier == nordicSemiconductor && request.testId > 0,
               let fault = HealthFault.fromId(request.testId) {
                registeredFaultState.append(fault)
            }
            
            guard request.companyIdentifier == companyIdentifier else {
                break
            }
            mostRecentTestId = request.testId
            
        case let request as HealthFaultClearUnacknowledged:
            guard request.companyIdentifier == companyIdentifier else {
                break
            }
            registeredFaultState.removeAll()
            
        default:
            // Ignore.
            break
        }
    }
    
    func model(_ model: Model, didReceiveResponse response: any MeshResponse,
               toAcknowledgedMessage request: any AcknowledgedMeshMessage,
               from source: NordicMesh.Address) {
        // Ignore. There are no CDB fields matching these parameters.
    }
}
