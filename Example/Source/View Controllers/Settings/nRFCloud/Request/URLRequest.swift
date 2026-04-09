/*
* Copyright (c) 2026, Nordic Semiconductor
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

extension URLRequest {
    
    enum Error: LocalizedError {
        case unknown
        case unauthorized    // 401: Invalid credentials
        case notFound        // 404: Api Key does not exist
        case httpStatus(Int) // Other HTTP status codes
    }
    
    mutating func authenticate(with username: String, password: String) {
        let credentials = "\(username):\(password)"
        if let credentialData = credentials.data(using: .utf8) {
            let base64Credentials = credentialData.base64EncodedString()
            self.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        }
    }
    
    mutating func authenticate(with apiKey: UserApiKey) {
        authenticate(with: apiKey.email, password: apiKey.apiKey)
    }
    
    mutating func get() async throws -> Data {
        httpMethod = "GET"
        return try await call()
    }
    
    mutating func post() async throws -> Data {
        httpMethod = "POST"
        return try await call()
    }
    
    private func call() async throws -> Data  {
        let (data, response) = try await URLSession.shared.data(for: self)
        guard let status = response as? HTTPURLResponse else {
            NSLog("Unexpected response: \(String(describing: response))")
            throw Error.unknown
        }
        guard 401 != status.statusCode else {
            // Invalid credentials.
            throw Error.unauthorized
        }
        guard 404 != status.statusCode else {
            // Resource not found.
            throw Error.notFound
        }
        guard (200..<299).contains(status.statusCode) else {
            NSLog("Server returned error code: %i", status.statusCode)
            throw Error.httpStatus(status.statusCode)
        }
        return data
    }
    
}
