/*
 * Copyright (c) 2017-2018 Runtime Inc.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import SwiftCBOR

open class McuMgrResponse: CBORMappable {
    
    //**************************************************************************
    // MARK: Value Mapping
    //**************************************************************************
    
    /**
     All `McuMgrResponse`(s) contain a ``McuMgrResponse/rc`` return code value.
     If the response packet does not contain a code, success (`.ok`) is assumed.
     */
    public var rc: McuMgrReturnCode = .ok
    
    /**
     In SMPv2, when a Request makes it into a specific Group, that Group may
     return its own kind of Return Code or Error.
     */
    public var groupRC: McuMgrGroupReturnCode?
    
    //**************************************************************************
    // MARK: Response Properties
    //**************************************************************************

    /// The transport's scheme. This is used to determine how to parse the raw packet.
    public var scheme: McuMgrScheme!
    
    /// The response's raw packet data. For CoAP transport schemes, this will
    /// include the CoAP header.
    public var rawData: Data?
    
    /// The 8-byte McuMgrHeader included in the response.
    public var header: McuMgrHeader!
    
    /// The CBOR payload from.
    public var payload: CBOR?
    
    /// The raw McuMgrResponse payload.
    public var payloadData: Data?
    
    /// The response's result obtained from the payload. If no Return Code (RC)
    /// or Group Error is explicitly stated, success is assumed.
    public var result: Result<Void, McuMgrError> = .success(())
    
    /// The CoAP Response code for CoAP based transport schemes. For non-CoAP
    /// transport schemes this value will always be 0
    public var coapCode: Int = 0
    
    //**************************************************************************
    // MARK: Initializers
    //**************************************************************************
    
    public required init(cbor: CBOR?) throws {
        try super.init(cbor: cbor)
        if case let CBOR.map(err)? = cbor?["err"] {
            self.groupRC = try McuMgrGroupReturnCode(map: err)
        }
        if case let CBOR.unsignedInt(rc)? = cbor?["rc"] {
            self.rc = McuMgrReturnCode(rawValue: rc) ?? .ok
        }
    }
    
    //**************************************************************************
    // MARK: Functions
    //**************************************************************************
    
    /**
     Returns `LocalizedError` if any is present. Either Group Error or McuManager
     Error. If `nil`, success scenario can be assumed.
     */
    public func getError() -> LocalizedError? {
        switch result {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
    
    //**************************************************************************
    // MARK: Static Builders
    //**************************************************************************
    
    /// Build an McuMgrResponse.
    ///
    /// This method will parse the raw packet data according to the transport
    /// scheme to obtain the header, payload, and return code. After getting the
    /// CBOR payload. An object of type <T> will be initialized which will map
    /// the CBOR payload values to the values in the object.
    ///
    /// - parameter scheme: the transport's scheme.
    /// - parameter data: The response's raw packet data.
    /// - parameter coapPayload: (Optional) payload for CoAP transport schemes.
    /// - parameter coapCode: (Optional) CoAP response code.
    ///
    /// - returns: The McuMgrResponse on success or nil on failure.
    public static func buildResponse<T: McuMgrResponse>(scheme: McuMgrScheme, response: Data?, coapPayload: Data? = nil, coapCode: Int = 0) throws -> T {
        guard let bytes = response else {
            throw McuMgrResponseParseError.invalidDataSize
        }
        if bytes.count < McuMgrHeader.HEADER_LENGTH {
            throw McuMgrResponseParseError.invalidDataSize
        }
        
        var payloadData: Data?
        var payload: CBOR?
        var header: McuMgrHeader?
        
        // Get the header and payload based on the transport scheme. CoAP
        // schemes put the header in the CBOR payload while standard schemes
        // prepend the header to the CBOR payload.
        if scheme.isCoap() {
            guard let coapPayload = coapPayload else {
                throw McuMgrResponseParseError.invalidDataSize
            }
            payloadData = coapPayload
            // Parse the raw payload into CBOR.
            payload = try CBOR.decode([UInt8](coapPayload))
            // Get the header from the CBOR.
            if case let CBOR.byteString(rawHeader)? = payload?["_h"] {
                header = try McuMgrHeader(data: Data(rawHeader))
            } else {
                throw McuMgrResponseParseError.invalidPayload
            }
        } else {
            // Parse the header.
            header = try McuMgrHeader(data: bytes)
            // Get header and payload from raw data.
            payloadData = bytes.subdata(in: McuMgrHeader.HEADER_LENGTH..<bytes.count)
            if payloadData != nil {
                // Parse CBOR from raw payload.
                payload = try CBOR.decode([UInt8](payloadData!))
            } else {
                payload = nil
            }
        }
        
        // Init the response with the CBOR payload. This will also map the CBOR
        // values to object values.
        let response = try T(cbor: payload)
        
        // Set remaining properties.
        response.payloadData = payloadData
        response.payload = payload
        response.header = header
        response.scheme = scheme
        response.rawData = bytes
        if let groupRC = response.groupRC, groupRC.rc != .ok {
            response.result = .failure(.groupCode(groupRC))
        } else if response.rc != .ok {
            response.result = .failure(.returnCode(response.rc))
        } else {
            response.result = .success(())
        }
        response.coapCode = coapCode
        
        return response
    }
    
    /// Build an McuMgrResponse for standard transport schemes (i.e. non-CoAP).
    ///
    /// This method will parse the raw packet data according to the transport
    /// scheme to obtain the header, payload, and return code. After getting the
    /// CBOR payload, An object of type <T> will be initialized which will map
    /// the CBOR payload values to the values in the object.
    ///
    /// - parameter scheme: the transport's scheme.
    /// - parameter data: The response's raw packet data.
    ///
    /// - returns: The McuMgrResponse on success or nil on failure.
    public static func buildResponse<T: McuMgrResponse>(scheme: McuMgrScheme, data: Data?) throws -> T {
        return try buildResponse(scheme: scheme, response: data, coapPayload: nil, coapCode: 0)
    }
    
    /// Build a McuMgrResponse for CoAP transport schemes to return to the
    /// McuManager.
    ///
    /// This method will parse the raw packet data according to the transport
    /// scheme to obtain the header, payload, and return code. After getting the
    /// CBOR payload, An object of type <T> will be initialized which will map
    /// the CBOR payload values to the values in the object.
    ///
    /// - parameter scheme: The transport's scheme.
    /// - parameter data: The response's raw packet data.
    /// - parameter coapPayload: The CoAP payload of the response.
    /// - parameter codeClass: The CoAP response code class.
    /// - parameter codeDetail: The CoAP response code detail.
    ///
    /// - returns: The McuMgrResponse on success or nil on failure.
    public static func buildCoapResponse<T: McuMgrResponse>(scheme: McuMgrScheme, data: Data, coapPayload: Data, codeClass: Int, codeDetail: Int) throws -> T? {
        return try buildResponse(scheme: scheme, response: data, coapPayload: coapPayload, coapCode: (codeClass * 100 + codeDetail))
    }
    
    //**************************************************************************
    // MARK: Utilities
    //**************************************************************************
    
    /// Gets the expected length of the entire response from the length field in
    /// the McuMgrHeader. The return value includes the 8-byte McuMgr header.
    ///
    /// - parameter scheme: The transport scheme (Must be BLE to use this
    ///   function).
    ///
    /// - returns: The expected length of the header or nil on error.
    public static func getExpectedLength(scheme: McuMgrScheme, responseData: Data) -> Int? {
        if scheme.isCoap() {
            return nil // TODO
        } else {
            if let header = try? McuMgrHeader(data: responseData) {
                return Int(header.length) + McuMgrHeader.HEADER_LENGTH
            } else {
                return nil
            }
        }
    }
}

extension McuMgrResponse: CustomDebugStringConvertible {
    
    /// String representation of the response.
    public var debugDescription: String {
        return "Header: \(self.header!), Payload: \(payload?.description ?? "nil")"
    }
    
}

//******************************************************************************
// MARK: Errors
//******************************************************************************

public enum McuMgrResponseParseError: Error {
    case invalidDataSize
    case invalidPayload
}

extension McuMgrResponseParseError: LocalizedError {
    
    public var errorDescription: String? {
        switch self {
        case .invalidDataSize:
            return "Invalid data size"
        case .invalidPayload:
            return "Invalid payload"
        }
    }
    
}

//******************************************************************************
// MARK: Default Responses
//******************************************************************************

public class McuMgrEchoResponse: McuMgrResponse {
    
    /// Echo response.
    public var response: String?
    
    public required init(cbor: CBOR?) throws {
        try super.init(cbor: cbor)
        if case let CBOR.utf8String(response)? = cbor?["r"] {
            self.response = response
        }
    }
}

// MARK: - McuMgrTaskStatsResponse

public class McuMgrTaskStatsResponse: McuMgrResponse {
    
    /// A map of task names to task statistics.
    public var tasks: [String:TaskStatistics]?
    
    public required init(cbor: CBOR?) throws {
        try super.init(cbor: cbor)
        if case let CBOR.map(tasks)? = cbor?["tasks"] {
            self.tasks = try CBOR.toObjectMap(map: tasks)
        }
    }
    
    public class TaskStatistics: CBORMappable {
        
        /// The task's priority.
        public var priority: UInt64!
        /// The task's ID.
        public var taskId: UInt64!
        /// The task's state.
        public var state: UInt64!
        /// The actual size of the task's stack that is being used.
        public var stackUse: UInt64!
        /// The size of the task's stack.
        public var stackSize: UInt64!
        /// The number of times the task has switched context.
        public var contextSwitchCount: UInt64!
        /// The time (ms) that the task has been running.
        public var runtime: UInt64!
        /// The last sanity checking with the sanity task.
        public var lastCheckin: UInt64!
        /// The next sanity checkin.
        public var nextCheckin: UInt64!
        
        public required init(cbor: CBOR?) throws {
            try super.init(cbor: cbor)
            if case let CBOR.unsignedInt(priority)? = cbor?["prio"] {self.priority = priority}
            if case let CBOR.unsignedInt(taskId)? = cbor?["tid"] {self.taskId = taskId}
            if case let CBOR.unsignedInt(state)? = cbor?["state"] {self.state = state}
            if case let CBOR.unsignedInt(stackUse)? = cbor?["stkuse"] {self.stackUse = stackUse}
            if case let CBOR.unsignedInt(stackSize)? = cbor?["stksiz"] {self.stackSize = stackSize}
            if case let CBOR.unsignedInt(contextSwitchCount)? = cbor?["cswcnt"] {self.contextSwitchCount = contextSwitchCount}
            if case let CBOR.unsignedInt(runtime)? = cbor?["runtime"] {self.runtime = runtime}
            if case let CBOR.unsignedInt(lastCheckin)? = cbor?["last_checkin"] {self.lastCheckin = lastCheckin}
            if case let CBOR.unsignedInt(nextCheckin)? = cbor?["next_checkin"] {self.nextCheckin = nextCheckin}
        }
    }
}

// MARK: - McuMgrExecResponse

public class McuMgrExecResponse: McuMgrResponse {
    
    /// Command output.
    public var output: String?
    
    public required init(cbor: CBOR?) throws {
        try super.init(cbor: cbor)
        if case let CBOR.utf8String(output)? = cbor?["o"] {
            self.output = output
        }
    }
    
    public override func getError() -> LocalizedError? {
        switch result {
        case .success:
            return nil
        case .failure(let error):
            guard let shellError = ShellManagerError(rawValue: rc.rawValue) else {
                return error
            }
            return shellError
        }
    }
}

// MARK: - McuMgrMemoryPoolStatsResponse

public class McuMgrMemoryPoolStatsResponse: McuMgrResponse {
    
    /// A map of task names to task statistics.
    public var mpools: [String:MemoryPoolStatistics]?
    
    public required init(cbor: CBOR?) throws {
        try super.init(cbor: cbor)
        if case let CBOR.map(mpools)? = cbor?["mpools"] {
            self.mpools = try CBOR.toObjectMap(map: mpools)
        }
    }
    
    public class MemoryPoolStatistics: CBORMappable {
        
        /// The memory pool's block size.
        public var blockSize: UInt64!
        /// The number of blocks in the memory pool.
        public var numBlocks: UInt64!
        /// The number of free blocks in the memory pool.
        public var numFree: UInt64!
        /// The minimum number of free blocks over the memory pool's life.
        public var minFree: UInt64!
        
        public required init(cbor: CBOR?) throws {
            try super.init(cbor: cbor)
            if case let CBOR.unsignedInt(blockSize)? = cbor?["blksiz"] {self.blockSize = blockSize}
            if case let CBOR.unsignedInt(numBlocks)? = cbor?["nblks"] {self.numBlocks = numBlocks}
            if case let CBOR.unsignedInt(numFree)? = cbor?["nfree"] {self.numFree = numFree}
            if case let CBOR.unsignedInt(minFree)? = cbor?["min"] {self.minFree = minFree}
        }
    }
}

// MARK: - McuMgrDateTimeResponse

public class McuMgrDateTimeResponse: McuMgrResponse {
    
    /// String representation of the datetime on the device.
    public var datetime: String?
    
    public required init(cbor: CBOR?) throws {
        try super.init(cbor: cbor)
        if case let CBOR.utf8String(datetime)? = cbor?["datetime"] {
            self.datetime = datetime
        }
    }
}

// MARK: - McuMgrParametersResponse

public final class McuMgrParametersResponse: McuMgrResponse {
    
    public var bufferSize: UInt64!
    public var bufferCount: UInt64!
    
    public required init(cbor: CBOR?) throws {
        try super.init(cbor: cbor)
        
        if case let CBOR.unsignedInt(bufferSize)? = cbor?["buf_size"] { self.bufferSize = bufferSize }
        if case let CBOR.unsignedInt(bufferCount)? = cbor?["buf_count"] { self.bufferCount = bufferCount }
    }
}

// MARK: - McuMgrManifestListResponse

public final class McuMgrManifestListResponse: McuMgrResponse {
    
    public class Manifest: CBORMappable {
        
        public enum Role: UInt64, CustomStringConvertible, CustomDebugStringConvertible {
            /// Manifest role uninitialized (invalid).
            case unknown = 0x00
            /// Manifest describes the entry-point for all Nordic-controlled manifests.
            case secTop = 0x10
            /// Manifest describes SDFW firmware and recovery updates.
            case secSDFW = 0x11
            /// Manifest describes SYSCTRL firmware update and boot procedures.
            case secSYSCTRL = 0x12
            /// Manifest describes the entry-point for all OEM-controlled manifests.
            case appRoot = 0x20
            /// Manifest describes OEM-specific recovery procedure.
            case appRecovery = 0x21
            /// Manifest describes OEM-specific binaries, specific for application core.
            case appLocalOne = 0x22
            /// Manifest describes OEM-specific binaries, specific for application core.
            case appLocalTwo = 0x23
            /// Manifest describes OEM-specific binaries, specific for application core.
            case appLocalThree = 0x24
            /// Manifest describes radio part of OEM-specific recovery procedure.
            case radioRecovery = 0x30
            /// Manifest describes OEM-specific binaries, specific for radio core.
            case radioLocalOne = 0x31
            /// Manifest describes OEM-specific binaries, specific for radio core.
            case radioLocalTwo = 0x32
            
            public var description: String {
                switch self {
                case .unknown:
                    return "UNKNOWN"
                case .secTop:
                    return "SEC_TOP"
                case .secSDFW:
                    return "SEC_SDFW"
                case .secSYSCTRL:
                    return "SEC_SYSCTRL"
                case .appRoot:
                    return "APP_ROOT"
                case .appRecovery:
                    return "APP_RECOVERY"
                case .appLocalOne:
                    return "APP_LOCAL_1"
                case .appLocalTwo:
                    return "APP_LOCAL_2"
                case .appLocalThree:
                    return "APP_LOCAL_3"
                case .radioRecovery:
                    return "RADIO_RECOVERY"
                case .radioLocalOne:
                    return "RADIO_LOCAL_1"
                case .radioLocalTwo:
                    return "RAIDO_LOCAL_2"
                }
            }
            
            public var debugDescription: String {
                switch self {
                case .unknown:
                    return "Unknown"
                case .secTop:
                    return "Entry-point for all Nordic-controlled manifests"
                case .secSDFW:
                    return "SDFW firmware and recovery updates"
                case .secSYSCTRL:
                    return "SYSCTRL firmware update and boot procedures"
                case .appRoot:
                    return "Entry-point for all OEM-controlled manifests"
                case .appRecovery:
                    return "OEM-Specific Application Core Recovery procedure"
                case .appLocalOne, .appLocalTwo, .appLocalThree:
                    return "OEM-Specific Binary for Application Core"
                case .radioRecovery:
                    return "OEM-Specific Radio Core Recovery procedure"
                case .radioLocalOne, .radioLocalTwo:
                    return "OEM-Specific Binary for Radio Core"
                }
            }
        }
        
        public var role: Role?
        
        public required init(cbor: CBOR?) throws {
            try super.init(cbor: cbor)
            if case let CBOR.unsignedInt(roleValue)? = cbor?["role"] {
                self.role = Role(rawValue: roleValue)
            }
        }
    }
    
    public var manifests: [Manifest]
    
    public required init(cbor: CBOR?) throws {
        if case let CBOR.array(manifests)? = cbor?["manifests"] {
            self.manifests = try CBOR.toObjectArray(array: manifests) ?? []
        } else {
            self.manifests = []
        }
        try super.init(cbor: cbor)
    }
}

// MARK: - McuMgrManifestStateResponse

public final class McuMgrManifestStateResponse: McuMgrResponse {
    
    public var classID: [UInt8]?
    public var vendorID: [UInt8]?
    public var downgradePreventionPolicy: DowngradePreventionPolicy?
    public var independentUpdateabilityPolicy: IndependentUpdateabilityPolicy?
    public var signatureVerificationPolicy: SignatureVerificationPolicy?
    public var digest: [UInt8]?
    public var digestAlgorithm: DigestAlgorithm?
    public var signatureCheck: SignatureVerification?
    public var sequenceNumber: UInt64?
    public var semanticVersion: [Int]?
    
    public func classUUID() throws -> UUID? {
        let classData = Data(classID ?? [])
        return try? UUID(classData)
    }
    
    public func vendorUUID() throws -> UUID? {
        let vendorData = Data(vendorID ?? [])
        return try? UUID(vendorData)
    }
    
    public func sequenceNumberHexString() -> String? {
        guard let sequenceNumber else { return nil }
        return "0x\(String(sequenceNumber, radix: 16, uppercase: true))"
    }
    
    public func semanticVersionString() -> String? {
        guard let semanticVersion else { return nil }
        let positiveNumbers = semanticVersion.filter({ $0 >= 0 })
        var version = positiveNumbers
            .map({ "\($0)" })
            .joined(separator: ".")
        if let negativeNumber = semanticVersion.first(where: { $0 < 0 }),
           let release = ReleaseType(rawValue: negativeNumber) {
            version += release.description
        }
        return version
    }
    
    public enum DigestAlgorithm: Int, RawRepresentable, Codable, CustomStringConvertible {
        case sha256 = -16
        case sha512 = -44
        
        public var description: String {
            switch self {
            case .sha256:
                return "SHA-256"
            case .sha512:
                return "SHA-512"
            }
        }
    }
    
    public enum SignatureVerification: UInt64, RawRepresentable, Codable, CustomStringConvertible, CustomDebugStringConvertible {
        case notChecked = 2
        case failed = 3
        case passed = 4
        
        public var description: String {
            switch self {
            case .notChecked:
                return "Not Checked"
            case .failed:
                return "Failed"
            case .passed:
                return "Passed"
            }
        }
        
        public var debugDescription: String {
            switch self {
            case .notChecked:
                return "Signature Verification is not performed."
            case .failed:
                return "Signature Verification has failed."
            case .passed:
                return "Signature Verification passed."
            }
        }
    }
    
    public enum DowngradePreventionPolicy: UInt64, RawRepresentable, Codable, CustomStringConvertible, CustomDebugStringConvertible {
        case disabled = 1
        case enabled = 2
        case unknown = 3
        
        public var description: String {
            switch self {
            case .disabled:
                return "Disabled"
            case .enabled:
                return "Enabled"
            case .unknown:
                return "Unknown"
            }
        }
        
        public var debugDescription: String {
            switch self {
            case .disabled:
                return "No downgrade prevention."
            case .enabled:
                return "Update forbidden if candidate version is lower than installed version."
            case .unknown:
                return "Unknown downgrade prevention policy."
            }
        }
    }
    
    public enum IndependentUpdateabilityPolicy: UInt64, RawRepresentable, Codable, CustomStringConvertible, CustomDebugStringConvertible {
        case denied = 1
        case allowed = 2
        case unknown = 3
        
        public var description: String {
            switch self {
            case .denied:
                return "Denied"
            case .allowed:
                return "Allowed"
            case .unknown:
                return "Unknown"
            }
        }
        
        public var debugDescription: String {
            switch self {
            case .denied:
                return "Independent update is forbidden."
            case .allowed:
                return "Independent update is allowed."
            case .unknown:
                return "Unknown independent updateability policy."
            }
        }
    }
    
    public enum SignatureVerificationPolicy: UInt64, RawRepresentable, Codable, CustomStringConvertible, CustomDebugStringConvertible {
        case disabled = 1
        case enabledOnUpdate = 2
        case enabledOnUpdateAndBoot = 3
        case unknown
        
        public var description: String {
            switch self {
            case .disabled:
                return "Disabled"
            case .enabledOnUpdate:
                return "Enabled on Update"
            case .enabledOnUpdateAndBoot:
                return "Enabled on Update and Boot"
            case .unknown:
                return "Unknown"
            }
        }
        
        public var debugDescription: String {
            switch self {
            case .disabled:
                return "Do not verify manifest signature."
            case .enabledOnUpdate:
                return "Verify the manifest signature only when performing an update."
            case .enabledOnUpdateAndBoot:
                return "Verify the manifest signature both when performing an update and booting."
            case .unknown:
                return "Unknown signature verification policy."
            }
        }
    }
    
    public enum ReleaseType: Int, RawRepresentable, Codable, CustomStringConvertible {
        case normal = 0
        case releaseCandidate = -1
        case beta = -2
        case alpha = -3
        
        public var description: String {
            switch self {
            case .normal:
                return ""
            case .releaseCandidate:
                return "-rc"
            case .beta:
                return "-beta"
            case .alpha:
                return "-alpha"
            }
        }
    }
    
    public required init(cbor: CBOR?) throws {
        try super.init(cbor: cbor)
        if case let CBOR.byteString(classID)? = cbor?["class_id"] {
            self.classID = classID
        }
        if case let CBOR.byteString(vendorID)? = cbor?["vendor_id"] {
            self.vendorID = vendorID
        }
        if case let CBOR.unsignedInt(downgradePreventionPolicy)? = cbor?["downgrade_prevention_policy"] {
            self.downgradePreventionPolicy = DowngradePreventionPolicy(rawValue: downgradePreventionPolicy)
        }
        if case let CBOR.unsignedInt(independentUpdateabilityPolicy)? = cbor?["independent_updateability_policy"] {
            self.independentUpdateabilityPolicy = IndependentUpdateabilityPolicy(rawValue: independentUpdateabilityPolicy)
        }
        if case let CBOR.unsignedInt(signatureVerificationPolicy)? = cbor?["signature_verification_policy"] {
            self.signatureVerificationPolicy = SignatureVerificationPolicy(rawValue: signatureVerificationPolicy)
        }
        if case let CBOR.byteString(digest)? = cbor?["digest"] {
            self.digest = digest
        }
        if case let CBOR.unsignedInt(signatureCheck)? = cbor?["signature_check"] {
            self.signatureCheck = SignatureVerification(rawValue: signatureCheck)
        }
        if case let CBOR.negativeInt(digestAlgorithm)? = cbor?["digest_algorithm"] {
            // -1 due to a known CBOR library issue when parsing negative integers.
            self.digestAlgorithm = DigestAlgorithm(rawValue: (Int(digestAlgorithm) * -1) - 1)
        }
        if case let CBOR.unsignedInt(sequenceNumber)? = cbor?["sequence_number"] {
            self.sequenceNumber = sequenceNumber
        }
        
        if case let CBOR.array(semanticVersion)? = cbor?["semantic_version"],
           let integerArray: [Int] = try? CBOR.toArray(array: semanticVersion) {
            self.semanticVersion = integerArray
        }
    }
}

// MARK: - SuitListResponse

/**
 This response type is not a part of the McuMgr/SUIT Protocol. We've added it to make the library API side match what most other APIs do, which is to return a ``McuMgrResponse`` for List in ``SuitManager``.
 */
public final class SuitListResponse: McuMgrResponse {
    
    public var roles: [McuMgrManifestListResponse.Manifest.Role]?
    public var states: [McuMgrManifestStateResponse]?
    
    /**
     Disclaimer: this is not used. I wrote this to make the library look good. The sole purpose of ``SuitListResponse`` is to have a ``McuMgrResponse`` type to return for its own LIST command variant.
     */
    public required init(cbor: CBOR?) throws {
        try super.init(cbor: cbor)
        if case let CBOR.array(roles)? = cbor?["roles"] {
            self.roles = roles.compactMap { (cbor: CBOR) -> McuMgrManifestListResponse.Manifest.Role? in
                guard case let CBOR.unsignedInt(roleValue) = cbor else { return nil }
                return McuMgrManifestListResponse.Manifest.Role(rawValue: roleValue)
            }
        }
        if case let CBOR.array(states)? = cbor?["states"] {
            self.states = try CBOR.toObjectArray(array: states)
        }
    }
}

// MARK: - McuMgrPollResponse

public final class McuMgrPollResponse: McuMgrResponse {
    
    /**
     * Session identifier. Non-zero value, unique for image request.
     * Not provided if there is no pending image request.
     */
    public var sessionID: UInt64?
    
    /**
     * Resource identifier, typically in form of a URI.
     * Not provided if there is no pending image request.
     */
    public var resourceID: String?
    
    /**
     * Checks whether the device is awaiting a resource.
     *  - Returns: `true`, if the client should deliver requested image to proceed with the update, false otherwise.
     */
    public var isRequestingResource: Bool { sessionID != nil }
    
    public var resource: FirmwareUpgradeResource? {
        guard let resourceID else { return nil }
        if resourceID.hasPrefix("file://") {
            let filename = String(resourceID.suffix(from: "file://".endIndex))
            return .file(name: filename)
        }
        return nil
    }
    
    public required init(cbor: CBOR?) throws {
        try super.init(cbor: cbor)
        if case let CBOR.unsignedInt(sessionID)? = cbor?["stream_session_id"] {
            self.sessionID = sessionID
        }
        if case let CBOR.byteString(resourceID)? = cbor?["resource_id"] {
            self.resourceID = String(bytes: Data(resourceID), encoding: .utf8)
        }
    }
}

// MARK: - AppInfoResponse

public final class AppInfoResponse: McuMgrResponse {
    
    public var response: String!
    
    public required init(cbor: CBOR?) throws {
        try super.init(cbor: cbor)
        if case let CBOR.utf8String(output)? = cbor?["output"] {
            self.response = output
        }
    }
}

// MARK: - BootloaderInfoResponse

public final class BootloaderInfoResponse: McuMgrResponse {
    
    public enum Bootloader: String, Codable, CustomDebugStringConvertible {
        case unknown = ""
        case mcuboot = "MCUboot"
        case suit = "SUIT"
        
        public var description: String {
            switch self {
            case .unknown:
                return "Unknown"
            case .mcuboot, .suit:
                return rawValue
            }
        }
        
        public var debugDescription: String { description }
    }
    
    public enum Mode: Int, Codable, CustomStringConvertible, CustomDebugStringConvertible {
        case unknown = -1
        case singleApplication = 0
        case swapUsingScratch = 1
        case overwrite = 2
        case swapNoScratch = 3
        case directXIPNoRevert = 4
        case directXIPWithRevert = 5
        case RAMLoader = 6
        case firmwareLoader = 7
        
        /**
         Intended for use cases where it's not important to know what kind of DirectXIP
         variant this Bootloader Mode might represent, but instead, whether it's
         DirectXIP or not.
         */
        public var isDirectXIP: Bool {
            return self == .directXIPNoRevert || self == .directXIPWithRevert
        }
        
        /**
         - Returns: `true` if the Bootloader represents Nordic Bare Metal SDK-based firmware.
         */
        public var isBareMetal: Bool {
            return self == .firmwareLoader
        }
        
        public var description: String {
            switch self {
            case .unknown:
                return "Unknown"
            case .singleApplication:
                return "Single application"
            case .swapUsingScratch:
                return "Swap using scratch partition"
            case .overwrite:
                return "Overwrite (upgrade-only)"
            case .swapNoScratch:
                return "Swap without scratch"
            case .directXIPNoRevert:
                return "Direct-XIP without revert"
            case .directXIPWithRevert:
                return "Direct-XIP with revert"
            case .RAMLoader:
                return "RAM Loader"
            case .firmwareLoader:
                return "Firmware Loader"
            }
        }
        
        public var debugDescription: String { description }
    }
    
    public var bootloader: Bootloader?
    public var mode: Mode?
    public var noDowngrade: Bool?
    public var activeSlot: UInt64?
    
    public required init(cbor: CBOR?) throws {
        try super.init(cbor: cbor)
        if case let CBOR.utf8String(bootloaderString)? = cbor?["bootloader"] {
            self.bootloader = Bootloader(rawValue: bootloaderString)
        }
        if case let CBOR.unsignedInt(mode)? = cbor?["mode"] {
            self.mode = Mode(rawValue: Int(mode))
        }
        if case let CBOR.boolean(noDowngrade)? = cbor?["no-downgrade"] {
            self.noDowngrade = noDowngrade
        }
        if case let CBOR.unsignedInt(activeSlot)? = cbor?["active"] {
            self.activeSlot = activeSlot
        }
    }
}

//******************************************************************************
// MARK: Image Responses
//******************************************************************************

public class McuMgrImageStateResponse: McuMgrResponse {
    
    /// The image slots on the device. This may contain one or two values,
    /// depending on whether there is an image loaded in slot 1.
    public var images: [ImageSlot]?
    /// Whether the bootloader is configured to use a split image setup.
    public var splitStatus: UInt64?
    
    public required init(cbor: CBOR?) throws {
        try super.init(cbor: cbor)
        if case let CBOR.unsignedInt(splitStatus)? = cbor?["splitStatus"] {
            self.splitStatus = splitStatus
        }
        if case let CBOR.array(images)? = cbor?["images"] {
            self.images = try CBOR.toObjectArray(array: images)
        }
    }
}

// MARK: - ImageSlot

extension McuMgrImageStateResponse {
    
    public class ImageSlot: CBORMappable, CustomDebugStringConvertible {
        
        // MARK: Properties
        
        /// The (zero) index of this image.
        public var image: UInt64 { unsignedUInt64(defaultValue: 0) }
        /// The (zero) index of this image slot (0 for primary, 1 for secondary).
        public var slot: UInt64 { unsignedUInt64(defaultValue: 0) }
        /// The version of the image.
        public var version: String? { utf8String() }
        /// The SHA256 hash of the image.
        public var hash: [UInt8] { byteString() }
        /// Bootable flag.
        public var bootable: Bool { boolean() }
        /// Pending flag. A pending image will be booted into on reset.
        public var pending: Bool { boolean() }
        /// Confirmed flag. A confirmed image will always be booted into (unless
        /// another image is pending.
        public var confirmed: Bool { boolean() }
        /// Active flag. Set if the image in this slot is active.
        public var active: Bool { boolean() }
        /// Permanent flag. Set if this image is permanent.
        public var permanent: Bool { boolean() }
        // Compressed flag. Set if the image contains a compressed update.
        public var compressed: Bool { boolean() }
        
        // MARK: CustomDebugStringConvertible
        
        public var debugDescription: String {
            return """
            Hash: \(hash)
            Image \(image), Slot \(slot), Version \(version)
            Bootable \(bootable ? "Yes" : "No"), Pending \(pending ? "Yes" : "No"), Confirmed \(confirmed ? "Yes" : "No"), Active \(active ? "Yes" : "No"), Compressed \(compressed ? "Yes" : "No"), Permanent \(permanent ? "Yes" : "No")
            """
        }
        
        // MARK: Init
        
        private let cbor: CBOR?
        
        public required init(cbor: CBOR?) throws {
            self.cbor = cbor
            try super.init(cbor: cbor)
        }
        
        // MARK: Private
        
        private func unsignedUInt64(forKey key: String = #function, defaultValue: UInt64) -> UInt64 {
            guard case let CBOR.unsignedInt(int)? = cbor?[.utf8String(key)] else { return defaultValue }
            return int
        }
        
        private func utf8String(forKey key: String = #function) -> String? {
            guard case let CBOR.utf8String(string)? = cbor?[.utf8String(key)] else { return nil }
            return string
        }
        
        private func byteString(forKey key: String = #function) -> [UInt8] {
            guard case let CBOR.byteString(cString)? = cbor?[.utf8String(key)] else { return [] }
            return cString
        }
        
        private func boolean(forKey key: String = #function) -> Bool {
            guard case let CBOR.boolean(bool)? = cbor?[.utf8String(key)] else { return false }
            return bool
        }
    }
}

// MARK: - McuMgrUploadResponse

public class McuMgrUploadResponse: McuMgrResponse {
    
    /// Offset to send the next packet of image data from.
    public var off: UInt64?
    public var match: Bool?
    
    public required init(cbor: CBOR?) throws {
        try super.init(cbor: cbor)
        if case let CBOR.unsignedInt(off)? = cbor?["off"] {
            self.off = off
        }
        if case let CBOR.boolean(match)? = cbor?["match"] {
            self.match = match
        }
    }
}

// MARK: - McuMgrCoreLoadResponse

public class McuMgrCoreLoadResponse: McuMgrResponse {
    
    /// The offset of the data.
    public var off: UInt64?
    /// The length of the core (in bytes). Set only in the
    /// first packet, when the off is equal to 0.
    public var len: UInt64?
    /// The core data received.
    public var data: [UInt8]?
    
    public required init(cbor: CBOR?) throws {
        try super.init(cbor: cbor)
        if case let CBOR.unsignedInt(off)? = cbor?["off"] {self.off = off}
        if case let CBOR.unsignedInt(len)? = cbor?["len"] {self.len = len}
        if case let CBOR.byteString(data)? = cbor?["data"] {self.data = data}
    }
}

// MARK: - McuMgrSlotInfoResponse

public class McuMgrSlotInfoResponse: McuMgrResponse {
    
    public var images: [SlotInfoImage]?
    
    public required init(cbor: CBOR?) throws {
        try super.init(cbor: cbor)
        if case let CBOR.array(images)? = cbor?["images"] {
            self.images = try CBOR.toObjectArray(array: images)
        }
    }
    
    // MARK: SlotInfoImage
    
    public class SlotInfoImage: CBORMappable {
        
        public var image: UInt64?
        public var slots: [SlotInfoSlot]?
        public var maxImageSize: UInt64?
        
        public required init(cbor: CBOR?) throws {
            try super.init(cbor: cbor)
            if case let CBOR.unsignedInt(image)? = cbor?["image"] {
                self.image = image
            }
            if case let CBOR.array(slots)? = cbor?["slots"] {
                self.slots = try CBOR.toObjectArray(array: slots)
            }
            if case let CBOR.unsignedInt(maxImageSize)? = cbor?["max_image_size"] {
                self.maxImageSize = maxImageSize
            }
        }
    }
    
    // MARK: SlotInfoSlot
    
    public class SlotInfoSlot: CBORMappable {
        
        public var slot: UInt64?
        public var size: UInt64?
        public var uploadImageID: UInt64?
        
        public required init(cbor: CBOR?) throws {
            try super.init(cbor: cbor)
            if case let CBOR.unsignedInt(slot)? = cbor?["slot"] {
                self.slot = slot
            }
            if case let CBOR.unsignedInt(size)? = cbor?["size"] {
                self.size = size
            }
            if case let CBOR.unsignedInt(uploadImageID)? = cbor?["upload_image_id"] {
                self.uploadImageID = uploadImageID
            }
        }
    }
}

//******************************************************************************
// MARK: Fs Responses
//******************************************************************************

public class McuMgrFsUploadResponse: McuMgrResponse {
    
    /// Offset to send the next packet of image data from.
    public var off: UInt64?
    
    public required init(cbor: CBOR?) throws {
        try super.init(cbor: cbor)
        if case let CBOR.unsignedInt(off)? = cbor?["off"] {self.off = off}
    }
}

// MARK: - McuMgrFsDownloadResponse

public class McuMgrFsDownloadResponse: McuMgrResponse {
    
    /// Offset to send the next packet of image data from.
    public var off: UInt64?
    /// The length of the file. This is not nil only if offset = 0.
    public var len: UInt64?
    /// The file data received.
    public var data: [UInt8]?
    
    public required init(cbor: CBOR?) throws {
        try super.init(cbor: cbor)
        if case let CBOR.unsignedInt(off)? = cbor?["off"] {self.off = off}
        if case let CBOR.unsignedInt(len)? = cbor?["len"] {self.len = len}
        if case let CBOR.byteString(data)? = cbor?["data"] {self.data = data}
    }
}

// MARK: - McuMgrFilesystemCrc32Response

public class McuMgrFilesystemCrc32Response: McuMgrResponse {
    
    // Type of hash/checksum that was performed.
    public var type: String?
    // Offset that checksum calculation started at
    public var off: UInt64?
    // Length of input data used for hash/checksum generation (in bytes)
    public var len: UInt64?
    // IEEE CRC32 checksum (uint32 represented as type long)
    public var output: UInt64?
    
    public required init(cbor: CBOR?) throws {
        try super.init(cbor: cbor)
        if case let CBOR.utf8String(type)? = cbor?["type"] {
            self.type = type
        }
        if case let CBOR.unsignedInt(off)? = cbor?["off"] {
            self.off = off
        }
        if case let CBOR.unsignedInt(len)? = cbor?["len"] {
            self.len = len
        }
        if case let CBOR.unsignedInt(output)? = cbor?["output"] {
            self.output = output
        }
    }
}

// MARK: - McuMgrFilesystemSha256Response

public class McuMgrFilesystemSha256Response: McuMgrResponse {
    
    // Type of hash/checksum that was performed.
    public var type: String?
    // Offset that checksum calculation started at.
    public var off: UInt64?
    // Length of input data used for hash/checksum generation (in bytes)
    public var len: UInt64?
    // 32-byte SHA256 (Secure Hash Algorithm)
    public var output: [UInt8]?
    
    public required init(cbor: CBOR?) throws {
        try super.init(cbor: cbor)
        if case let CBOR.utf8String(type)? = cbor?["type"] {
            self.type = type
        }
        if case let CBOR.unsignedInt(off)? = cbor?["off"] {
            self.off = off
        }
        if case let CBOR.unsignedInt(len)? = cbor?["len"] {
            self.len = len
        }
        if case let CBOR.byteString(output)? = cbor?["output"] {
            self.output = output
        }
    }
}

// MARK: - McuMgrFilesystemStatusResponse

public class McuMgrFilesystemStatusResponse: McuMgrResponse {
    
    /// The length of the file.
    public var len: UInt64?
    
    public required init(cbor: CBOR?) throws {
        try super.init(cbor: cbor)
        if case let CBOR.unsignedInt(len)? = cbor?["len"] {
            self.len = len
        }
    }
}

//******************************************************************************
// MARK: Logs Responses
//******************************************************************************

public class McuMgrLevelListResponse: McuMgrResponse {

    /// Log level names.
    public var logLevelNames: [String]?
    
    public required init(cbor: CBOR?) throws {
        try super.init(cbor: cbor)
        if case let CBOR.array(logLevelNames)? = cbor?["level_map"]  {
            self.logLevelNames = try CBOR.toArray(array: logLevelNames)
        }
    }
}

// MARK: - McuMgrLogListResponse

public class McuMgrLogListResponse: McuMgrResponse {
    
    /// Log levels.
    public var logNames: [String]?
    
    public required init(cbor: CBOR?) throws {
        try super.init(cbor: cbor)
        if case let CBOR.array(logNames)? = cbor?["log_list"]  {
            self.logNames = try CBOR.toArray(array: logNames)
        }
    }
}

// MARK: - McuMgrLogResponse

public class McuMgrLogResponse: McuMgrResponse {
    
    /// Next index that the device will log to.
    public var next_index: UInt64?
    /// Logs.
    public var logs: [LogResult]?
    
    public required init(cbor: CBOR?) throws {
        try super.init(cbor: cbor)
        if case let CBOR.unsignedInt(next_index)? = cbor?["next_index"] {
            self.next_index = next_index
        }
        if case let CBOR.array(logs)? = cbor?["logs"]  {
            self.logs = try CBOR.toObjectArray(array: logs)
        }
    }
    
    public class LogResult: CBORMappable {
        public var name: String?
        public var type: UInt64?
        public var entries: [LogEntry]?
        
        public required init(cbor: CBOR?) throws {
            try super.init(cbor: cbor)
            if case let CBOR.utf8String(name)? = cbor?["name"] {self.name = name}
            if case let CBOR.unsignedInt(type)? = cbor?["type"] {self.type = type}
            if case let CBOR.array(entries)? = cbor?["entries"] {
                self.entries = try CBOR.toObjectArray(array: entries)
            }
        }
    }
    
    public class LogEntry: CBORMappable {
        public var msg: [UInt8]?
        public var ts: UInt64?
        public var level: UInt64?
        public var index: UInt64?
        public var module: UInt64?
        public var type: String?
        
        public required init(cbor: CBOR?) throws {
            try super.init(cbor: cbor)
            if case let CBOR.byteString(msg)? = cbor?["msg"] {self.msg = msg}
            if case let CBOR.unsignedInt(ts)? = cbor?["ts"] {self.ts = ts}
            if case let CBOR.unsignedInt(level)? = cbor?["level"] {self.level = level}
            if case let CBOR.unsignedInt(index)? = cbor?["index"] {self.index = index}
            if case let CBOR.unsignedInt(module)? = cbor?["module"] {self.module = module}
            if case let CBOR.utf8String(type)? = cbor?["type"] {self.type = type}
        }
        
        /// Get the string representation of the message based on type.
        public func getMessage() -> String? {
            guard let msg = msg else { return nil }
            if type != nil && type == "cbor" {
                if let messageCbor = try? CBOR.decode(msg) {
                    return messageCbor.description
                }
            } else {
                return String(bytes: msg, encoding: .utf8)
            }
            return nil
        }
    }
}

//******************************************************************************
// MARK: Stats Responses
//******************************************************************************

public class McuMgrStatsResponse: McuMgrResponse {
    
    /// Name of the statistic module.
    public var name: String?
    /// Statistic fields.
    public var fields: [String:Int]?
    /// Statistic group.
    public var group: String?
    
    public required init(cbor: CBOR?) throws {
        try super.init(cbor: cbor)
        if case let CBOR.utf8String(name)? = cbor?["name"] {self.name = name}
        if case let CBOR.utf8String(group)? = cbor?["group"] {self.group = group}
        if case let CBOR.map(fields)? = cbor?["fields"] {
            self.fields = try CBOR.toMap(map: fields)
        }
    }
}

// MARK: - McuMgrStatsListResponse

public class McuMgrStatsListResponse: McuMgrResponse {
    
    /// List of names of the statistic modules on the device.
    public var names: [String]?
    
    public required init(cbor: CBOR?) throws {
        try super.init(cbor: cbor)
        if case let CBOR.array(names)? = cbor?["stat_list"] {
            self.names = try CBOR.toArray(array: names)
        }
    }
}


//******************************************************************************
// MARK: Config Responses
//******************************************************************************

public class McuMgrConfigResponse: McuMgrResponse {
    
    /// Config value.
    public var val: [UInt8]?
    
    public required init(cbor: CBOR?) throws {
        try super.init(cbor: cbor)
        if case let CBOR.byteString(val)? = cbor?["val"] {self.val = val}
    }
}

// MARK: - UUID(data:)

extension UUID {
    
    enum InitError: Error {
        case invalidData
    }
    
    /**
     [Source](https://gist.github.com/dagronf/bb1d42c5d28a25499c2e1aab9f60f6c6)
     */
    init(_ data: Data) throws {
        guard data.count >= MemoryLayout<uuid_t>.size else {
            throw InitError.invalidData
        }
        
        let uuid: NSUUID = try data.withUnsafeBytes { rawBuffer in
            guard let bytes = rawBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                throw InitError.invalidData
            }
            return NSUUID(uuidBytes: bytes)
        }
        self = uuid as UUID
    }
}
