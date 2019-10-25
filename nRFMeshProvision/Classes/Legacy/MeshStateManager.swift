//
//  MeshStateManager.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 06/03/2018.
//

import Foundation

/// This is a legacy class from nRF Mesh Provision 1.0.x library.
/// The only purpose of this class here is to allow to migrate from
/// the old data format to the new one.
internal struct MeshStateManager {

    /// Private constructor.
    private init() {
        // Empty.
    }
    
    /// This method tries to loads the `MeshState`, saved using the
    /// nRF Mesh Provision library version 1.0.x.
    ///
    /// If the state does not exist, or the state could not be decoded,
    /// this method return `nil`.
    ///
    /// - returns: The `MeshState` object, or `nil` if the state does not
    ///            exist or is invalid.
    static func load() -> MeshState? {
        if let documentsPath = MeshStateManager.getDocumentDirectory() {
            let filePath = documentsPath.appending("/meshState.bin")
            let fileURL = URL(fileURLWithPath: filePath)
            
            if let data = try? Data(contentsOf: fileURL) {
                return try? JSONDecoder().decode(MeshState.self, from: data)
            }
        }
        return nil
    }

    /// Removes the mesh state from the device.
    ///
    /// This method should be called when the state has been migrated to
    /// the new mesh network object.
    static func cleanup() {
        if let documentsPath = MeshStateManager.getDocumentDirectory() {
            let filePath = documentsPath.appending("/meshState.bin")
            let fileURL = URL(fileURLWithPath: filePath)
            if FileManager.default.isDeletableFile(atPath: filePath) {
                do {
                    try FileManager.default.removeItem(at: fileURL)
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    private static func getDocumentDirectory() -> String? {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
    }
}
