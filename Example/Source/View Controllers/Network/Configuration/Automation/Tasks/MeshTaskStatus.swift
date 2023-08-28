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

import nRFMeshProvision

enum MeshTaskStatus {
    case pending
    case inProgress
    case skipped
    case success
    case failed(String)
    case cancelled
    
    static func failed(_ error: Error) -> MeshTaskStatus {
        return .failed(error.localizedDescription)
    }
    
    static func resultOf(_ status: ConfigStatusMessage) -> MeshTaskStatus {
        if status.isSuccess {
            return .success
        }
        return .failed("\(status.status)")
    }
}

extension MeshTaskStatus: CustomStringConvertible {
    
    var description: String {
        switch self {
        case .pending:
            return "Pending"
        case .inProgress:
            return "In Progress..."
        case .skipped:
            return "Skipped"
        case .success:
            return "Success"
        case .failed(let status):
            return status
        case .cancelled:
            return "Cancelled"
        }
    }
    
    var color: UIColor {
        switch self {
        case .pending:
            if #available(iOS 13.0, *) {
                return .secondaryLabel
            } else {
                return .lightGray
            }
        case .inProgress:
            return .dynamicColor(light: .nordicLake, dark: .nordicBlue)
        case .success:
            return .systemGreen
        case .cancelled, .skipped:
            return .nordicFall
        case .failed:
            return .nordicRed
        }
    }
    
}
