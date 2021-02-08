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

internal extension KeyedDecodingContainer {
    
    /// This method tries to decode the field of given type for the specified key.
    /// If it fails, it tries do the same using the legacy key.
    ///
    /// - parameters:
    ///   - type: The type to decode.
    ///   - key: The current key to decode from.
    ///   - legacyKey: The legacy key.
    /// - throws: A `DecodingError` is thrown when the decoding failed.
    /// - returns: The decoded value.
    func decode<T: Decodable>(_ type: T.Type, forKey key: KeyedDecodingContainer<K>.Key,
                              or legacyKey: KeyedDecodingContainer<K>.Key) throws -> T {
        do {
            return try decode(T.self, forKey: key)
        } catch {
            let originalError = error
            do {
                return try decode(T.self, forKey: legacyKey)
            } catch {
                throw originalError
            }
        }
    }
    
    /// This method tries to decode the field of given type for the specified key.
    /// If it fails, it tries do the same using the legacy key and covert its type
    /// to the one used in current version of the database.
    ///
    /// - parameters:
    ///   - type: The type to decode.
    ///   - key: The current key to decode from.
    ///   - legacyType: The legacy type to decode.
    ///   - legacyKey: The legacy key.
    ///   - converter: The converter that will convert the legacy value to the current
    ///                type.
    /// - throws: A `DecodingError` is thrown when the decoding failed.
    /// - returns: The decoded value. 
    func decode<T: Decodable, L: Decodable>(_ type: T.Type, forKey key: KeyedDecodingContainer<K>.Key,
                                            orConvert legacyType: L.Type, forKey legacyKey: KeyedDecodingContainer<K>.Key,
                                            using converter: (L) throws -> T) throws -> T {
        do {
            return try decode(T.self, forKey: key)
        } catch {
            let originalError = error
            do {
                let legacyValue = try decode(L.self, forKey: legacyKey)
                return try converter(legacyValue)
            } catch {
                throw originalError
            }
        }
    }
    
}
