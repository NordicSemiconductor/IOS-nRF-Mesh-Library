/*
* Copyright (c) 2023, Nordic Semiconductor
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

import NordicMesh

enum ApplicationTask {
    case clearDfuReceivers(from: Model)
    case addDfuReceivers(_ receivers: [Receiver], to: Model)
    
    var title: String {
        switch self {
        case .clearDfuReceivers(from: let model):
            return "Clear List of Receivers from \(model)"
        case .addDfuReceivers(let receivers, to: let model):
            if receivers.count == 1 {
                return "Add Receiver to \(model)"
            }
            return "Add \(receivers.count) Receivers to \(model)"
        }
    }
    
    var icon: UIImage {
        switch self {
        case .clearDfuReceivers, .addDfuReceivers:
            return #imageLiteral(resourceName: "ic_dfu")
        }
    }
    
    var message: AcknowledgedMeshMessage {
        switch self {
        case .clearDfuReceivers(from: _):
            return FirmwareDistributionReceiversDeleteAll()
        case .addDfuReceivers(let receivers, to: _):
            let dfuReceivers = receivers.map { receiver in
                return FirmwareDistributionReceiversAdd.Receiver(address: receiver.address, imageIndex: receiver.imageIndex)
            }
            return FirmwareDistributionReceiversAdd(receivers: dfuReceivers)
        }
    }
    
    var target: Model {
        switch self {
        case .clearDfuReceivers(from: let model),
             .addDfuReceivers(_, to: let model):
            return model
        }
    }
}
