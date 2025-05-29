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
    
    static func resultOf(_ status: StatusMessage) -> MeshTaskStatus {
        if status.isSuccess {
            return .success
        }
        return .failed("\(status.message)")
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

extension Array where Element == (node: Node, tasks: [(task: MeshTask, status: MeshTaskStatus)]) {
    
    mutating func merge(with tasks: [MeshTask], for node: Node) {
        if let index = firstIndex(where: { $0.node.uuid == node.uuid }) {
            self[index].tasks.append(contentsOf: tasks.map { ($0, .pending) })
        } else {
            self.append((node: node, tasks: tasks.map { ($0, .pending) }))
        }
    }
    
    var hasAnyFailed: Bool {
        return contains { (node, tasks) in
            return tasks.contains { task in
                switch task.status {
                case .failed, .cancelled:
                    return true
                default:
                    return false
                }
            }
        }
    }
    
    var taskCount: Int {
        return reduce(0) { $0 + $1.tasks.count }
    }
    
    func task(at index: Int) -> (task: MeshTask, status: MeshTaskStatus)? {
        var currentIndex = 0
        for (_, tasks) in self {
            for task in tasks {
                if currentIndex == index {
                    return task
                }
                currentIndex += 1
            }
        }
        return nil
    }
    
    @discardableResult
    mutating func updateStatus(at index: Int, with status: MeshTaskStatus) -> IndexPath? {
        var currentIndex = 0
        for (nodeIndex, (_, tasks)) in self.enumerated() {
            for (taskIndex, _) in tasks.enumerated() {
                if currentIndex == index {
                    self[nodeIndex].tasks[taskIndex].status = status
                    return IndexPath(row: taskIndex, section: nodeIndex)
                }
                currentIndex += 1
            }
        }
        return nil
    }
}
