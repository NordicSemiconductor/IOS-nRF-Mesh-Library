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
internal class MeshStateManager: NSObject {

    private override init() {
        super.init()
    }
    
    static func restoreState() -> MeshState? {
        if let documentsPath = MeshStateManager.getDocumentDirectory() {
            let filePath = documentsPath.appending("/meshState.bin")
            let fileURL = URL(fileURLWithPath: filePath)
            do {
                let data = try Data(contentsOf: fileURL)
                return try JSONDecoder().decode(MeshState.self, from: data)
            } catch {
                print("Error reading state from file")
            }
        }
        return nil
    }

    static func deleteState() {
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
