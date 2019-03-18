//
//  MeshStateManager.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 06/03/2018.
//

import Foundation

public class MeshStateManager: NSObject {
    
    public private (set) var meshState: MeshState!

    private override init() {
        super.init()
    }

    public init(withState aState: MeshState) {
        meshState = aState
    }
   
    public func state() -> MeshState {
        //restoreState()
        return meshState
    }

    public func saveState() {
        print("Saving state \(self.debugDescription) on Thread \(Thread.current) (is main: \(Thread.current === Thread.main))")
        let encodedData = try? JSONEncoder().encode(self.meshState)
        print("-----")
        print("Saved state")
        self.meshState.provisionedNodes.forEach {  print("node: \($0.nodeId.hexString()) deviceKey: \($0.deviceKey.hexString()) netKey \(self.meshState.netKey.hexString())  nodeUnicast: \($0.nodeUnicast?.hexString() ?? "null")") }
        print("-----")
        if let documentsPath = MeshStateManager.getDocumentDirectory() {
            let filePath = documentsPath.appending("/meshState.bin")
            let fileURL = URL(fileURLWithPath: filePath)
            do {
                try encodedData!.write(to: fileURL)
            } catch {
                print(error)
            }
        }
    }
    
    public func restoreState() {
        print("Restoring state \(self.debugDescription) on Thread \(Thread.current) (is main: \(Thread.current === Thread.main))")
        if let documentsPath = MeshStateManager.getDocumentDirectory() {
            let filePath = documentsPath.appending("/meshState.bin")
            let fileURL = URL(fileURLWithPath: filePath)
            do {
                let data = try Data(contentsOf: fileURL)
                let decodedState = try JSONDecoder().decode(MeshState.self, from: data)
                self.meshState = decodedState
                print("-----")
                print("Restored state")
                self.meshState.provisionedNodes.forEach {  print("node: \($0.nodeId.hexString()) deviceKey: \($0.deviceKey.hexString()) nodeUnicast: \($0.nodeUnicast?.hexString() ?? "null")") }
                print("-----")
            } catch {
                print("Error reading state from file")
            }
        }
    }

    public func generateState() -> Bool {
        
        let networkKey = generateRandomKey()
        
        guard networkKey != nil else {
            print("Failed to generate network key")
            return false
        }
        let keyIndex = Data([0x00, 0x00])
        let flags = Data([0x00])
        let ivIndex = Data([0x00, 0x00, 0x00, 0x00])
        let unicastAddress = Data([0x7F, 0xFF]) //TODO: check if we get composition data now
        let globalTTL: UInt8 = 5
        let networkName = "My Network"
        let appkey1 = generateRandomKey()
        let appkey2 = generateRandomKey()
        let appkey3 = generateRandomKey()
        
        // FIXME: add network identify
        /*
        public static byte[] calculateIdentityKey(final byte[] n) {
            final byte[] salt = calculateSalt(NKIK);
            ByteBuffer buffer = ByteBuffer.allocate(ID128.length + 1);
            buffer.put(ID128);
            buffer.put((byte) 0x01);
            final byte[] p = buffer.array();
            return calculateK1(n, salt, p);
        }
        */
        
        guard appkey1 != nil, appkey2 != nil, appkey3 != nil else {
            print("Failed to generate appkeys")
            return false
        }
        
        let appKeys = [["AppKey 1": appkey1!],
                       ["AppKey 2": appkey2!],
                       ["AppKey 3": appkey3!]]
        let newState = MeshState(withNodeList: [], netKey: networkKey!, keyIndex: keyIndex,
                                 IVIndex: ivIndex, globalTTL: globalTTL, unicastAddress: unicastAddress,
                                 flags: flags, appKeys: appKeys, andName: networkName)
        self.meshState = newState
        
        return true
    
    }

    public func deleteState() -> Bool {
        if let documentsPath = MeshStateManager.getDocumentDirectory() {
            let filePath = documentsPath.appending("/meshState.bin")
            let fileURL = URL(fileURLWithPath: filePath)
            if FileManager.default.isDeletableFile(atPath: filePath) {
                do {
                    try FileManager.default.removeItem(at: fileURL)
                    return true
                } catch {
                    print(error.localizedDescription)
                    return false
                }
            }
        }
        return false;
    
    }

    // MARK: - Static accessors
    public static func restoreState() -> MeshStateManager? {
        if MeshStateManager.stateExists() {
            let aStateManager = MeshStateManager()
            aStateManager.restoreState()
            return aStateManager
        } else {
            return nil
        }
    }

    public static func stateExists() -> Bool {
        if let documentsPath = MeshStateManager.getDocumentDirectory() {
            let filePath = documentsPath.appending("/meshState.bin")
            return FileManager.default.fileExists(atPath: filePath)
        } else {
            return false
        }
    }
    
    public static func generateState() -> MeshStateManager? {
        let aStateManager = MeshStateManager()
        if aStateManager.generateState() {
            aStateManager.saveState()
        } else {
            print("Failed to create MeshStateManager object")
            return nil
        }
        return aStateManager
    }
    private static func getDocumentDirectory() -> String? {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
    }
    
    // MARK: - Generation helper
    private func generateRandomKey() -> Data? {
        return OpenSSLHelper().generateRandom()
    }
}
