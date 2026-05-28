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

enum Keychain {
    private static let keychainService = "no.nordicsemi.ios.nrfmesh"
    private static let emailAccount = "nrfcloud_email"
    private static let apiKeyAccount = "nrfcloud_api_key"
    private static let userProfileAccount = "user_data"
    private static let projectKeyAccount = "project_key"
    
    static func saveProjectKey(_ projectKey: ProjectKey) throws {
        let data = try JSONEncoder().encode(projectKey)
        try save(service: keychainService,
                 account: projectKeyAccount,
                 value: data)
    }
    
    static func loadProjectKey() throws -> ProjectKey? {
        guard let key = try load(service: keychainService, account: projectKeyAccount)
        else { return nil }
        return try JSONDecoder().decode(ProjectKey.self, from: key)
    }
    
    static func deleteProjectKey() throws {
        try delete(service: keychainService, account: projectKeyAccount)
    }
    
    static func saveUserProfile(_ data: Data) throws {
        try save(service: keychainService, account: userProfileAccount, value: data)
    }
    
    static func loadUserProfile() throws -> Data? {
        return try load(service: keychainService, account: userProfileAccount)
    }
    
    static func deleteUserProfile() throws {
        try delete(service: keychainService, account: userProfileAccount)
    }
    
    static func saveUserApiKey(_ apiKey: UserApiKey) throws {
        try save(service: keychainService,
                 account: emailAccount,
                 value: Data(apiKey.email.utf8))
        try save(service: keychainService,
                 account: apiKeyAccount,
                 value: Data(apiKey.apiKey.utf8))
    }

    static func loadUserApiKey() throws -> UserApiKey? {
        guard
            let emailData = try load(service: keychainService, account: emailAccount),
            let apiKeyData = try load(service: keychainService, account: apiKeyAccount),
            let email = String(data: emailData, encoding: .utf8),
            let apiKey = String(data: apiKeyData, encoding: .utf8)
        else { return nil }
        return UserApiKey(email: email, apiKey: apiKey)
    }

    static func deleteUserApiKey() throws {
        try delete(service: keychainService, account: emailAccount)
        try delete(service: keychainService, account: apiKeyAccount)
    }
    
    private static func save(service: String, account: String, value: Data) throws {
        // Delete any existing item
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: value,
            // Recommended access control for background usage; adjust as needed
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
    }
    
    private static func load(service: String, account: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = item as? Data else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
        return data
    }
    
    private static func delete(service: String, account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
    }
    
}
