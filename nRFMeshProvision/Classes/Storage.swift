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

/// A protocol used to save and restore the Mesh Network configuration.
///
/// The configuration saved in the storage should not be shared to another device,
/// as it contains some local configuration. Instead, use ``MeshNetworkManager/export()``
/// method to get the JSON compliant with Bluetooth Mesh scheme.
public protocol Storage {
    /// Loads data from the storage.
    ///
    /// - returns: Data or `nil` if not found.
    func load() -> Data?
    
    /// Save given data.
    ///
    /// - returns: `True` in case of success, `false` otherwise.
    func save(_ data: Data) -> Bool
}

/// A Storage implementation which will save the data in a local file
/// with the given name. The file is stored in app's document directory in
/// the user domain.
open class LocalStorage: Storage {
    private let path: String
    
    public init(fileName: String = "MeshNetwork.json") {
        self.path = fileName
    }
    
    public func load() -> Data? {
        // Load JSON form local file
        if let fileURL = getStorageFile() {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                do {
                    return try Data(contentsOf: fileURL)
                } catch {
                    print(error)
                }
            }
        }
        return nil
    }
    
    public func save(_ data: Data) -> Bool {
        if let fileURL = getStorageFile() {
            do {
                try data.write(to: fileURL)
                return true
            } catch {
                print(error)
            }
        }
        return false
    }
    
    /// Returns the local file in which the Mesh configuration is stored.
    open func getStorageFile() -> URL? {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return url?.appendingPathComponent(path)
    }
}
