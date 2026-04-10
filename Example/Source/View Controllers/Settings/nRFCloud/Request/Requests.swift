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
import MemfaultCloud

enum nRFCloud {
    private static let api = URL(string: "https://api.memfault.com/")!
    private static let loginPath = "auth/me" // GET
    private static let apiKeyPath = "auth/api_key" // GET, POST, DELETE
    private static let eventsPath = "api/v0/events" // POST
    private static func projectsPath(organization: Organization) -> String {
        return "api/v0/organizations/\(organization.slug)/projects"
    }
    private static func dataRoutesPath(organization: Organization, project: Project) -> String {
        return "api/v0/organizations/\(organization.slug)/projects/\(project.slug)/data-routes"
    }
    
    static func getUserApiKey(email: String, password: String) async throws -> UserApiKey {
        guard let url = api.appending(endpoint: apiKeyPath) else {
            throw URLRequest.Error.unknown
        }
        
        // API returns the API KEY wrapped in a "data" object.
        struct ApiKey: Codable {
            struct Data: Codable {
                let apiKey: String
                
                // MARK: - Codable
                
                private enum CodingKeys: String, CodingKey {
                    case apiKey = "api_key"
                }
            }
            private let data: Data
            
            var value: String {
                return data.apiKey
            }
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.authenticate(with: email, password: password)
        
        // Try to get the API KEY using GET. If it does not exist, create one using POST.
        do {
            let data = try await urlRequest.get()
            let apiKey = try JSONDecoder().decode(ApiKey.self, from: data)
            return UserApiKey(email: email, apiKey: apiKey.value)
        } catch {
            if case URLRequest.Error.notFound = error {
                // If the API Key does not exist, create one using POST.
                let data = try await urlRequest.post()
                let apiKey = try JSONDecoder().decode(ApiKey.self, from: data)
                return UserApiKey(email: email, apiKey: apiKey.value)
            }
            throw error
        }
    }
    
    static func getUser(using userApiKey: UserApiKey) async throws -> User {
        guard let url = api.appending(endpoint: loginPath) else {
            throw URLRequest.Error.unknown
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.authenticate(with: userApiKey)
        
        let data = try await urlRequest.get()
        return try JSONDecoder().decode(User.self, from: data)
    }
    
    static func getProjects(in organization: Organization, using userApiKey: UserApiKey) async throws -> [Project] {
        guard let url = api.appending(endpoint: projectsPath(organization: organization)) else {
            throw URLRequest.Error.unknown
        }
        
        // API returns Projects wrapped in a "data" object.
        struct Projects: Codable {
            let data: [Project]
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.authenticate(with: userApiKey)
        
        let data = try await urlRequest.get()
        return try JSONDecoder().decode(Projects.self, from: data).data
    }
    
    static func getProjectKeys(for project: Project, in organization: Organization, using userApiKey: UserApiKey) async throws -> [ProjectKey] {
        guard let url = api.appending(endpoint: dataRoutesPath(organization: organization, project: project)) else {
            throw URLRequest.Error.unknown
        }
        
        // API returns data routes wrapped in a "data" object.
        struct DataRoutes: Codable {
            let data: [ProjectKey]
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.authenticate(with: userApiKey)
        
        let data = try await urlRequest.get()
        var keys = try JSONDecoder().decode(DataRoutes.self, from: data).data
        for i in keys.indices {
            keys[i].organizationName = organization.name
            keys[i].projectName = project.name
        }
        return keys
    }
    
    static func createDevice(_ info: MemfaultDeviceInfo, using projectKey: ProjectKey) async throws {
        guard let url = api.appending(endpoint: eventsPath) else {
            throw URLRequest.Error.unknown
        }
        
        struct HeartbeatEvent: Codable {
            struct EventInfo: Codable {
                let metrics: [String: Int]
            }
            let type: String = "heartbeat"
            let deviceSerial: String
            let hardwareVersion: String
            let softwareVersion: String
            let softwareType: String
            let sdkVersion: String = AppInfo.version
            let eventInfo: EventInfo
            
            // MARK: - Codable
            
            private enum CodingKeys: String, CodingKey {
                case type
                case deviceSerial = "device_serial"
                case hardwareVersion = "hardware_version"
                case softwareVersion = "software_version"
                case softwareType = "software_type"
                case sdkVersion = "sdk_version"
                case eventInfo = "event_info"
            }
        }

        let event = HeartbeatEvent(
            deviceSerial: info.deviceSerial,
            hardwareVersion: info.hardwareVersion,
            softwareVersion: info.softwareVersion,
            softwareType: info.softwareType,
            eventInfo: .init(metrics: [
                "pre-registered": 1
            ])
        )
        let data = try JSONEncoder().encode([event])
        
        var urlRequest = URLRequest(url: url)
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue(projectKey.token, forHTTPHeaderField: "Memfault-Project-Key")
        urlRequest.httpBody = data
        
        _ = try await urlRequest.post()
    }
}
