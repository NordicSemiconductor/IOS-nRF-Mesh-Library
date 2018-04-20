//
//  AppDelegate.swift
//  nRFMeshProvision
//
//  Created by mostafaberg on 12/18/2017.
//  Copyright (c) 2017 mostafaberg. All rights reserved.
//

import UIKit
import nRFMeshProvision
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        if MeshStateManager.stateExists() == false {
            let networkKey = generateNewKey()
            let keyIndex = Data([0x00, 0x00])
            let flags = Data([0x00])
            let ivIndex = Data([0x00, 0x00, 0x00, 0x00])
            let unicastAddress = Data([0x01, 0x23])
            let globalTTL: UInt8 = 5
            let networkName = "My Network"
            let appKeys = [["AppKey 1": generateNewKey()],
                           ["AppKey 2": generateNewKey()],
                           ["AppKey 3": generateNewKey()]]
            let state = MeshState(withNodeList: [], netKey: networkKey, keyIndex: keyIndex,
                                  IVIndex: ivIndex, globalTTL: globalTTL, unicastAddress: unicastAddress,
                                  flags: flags, appKeys: appKeys, andName: networkName)
            MeshStateManager(withState: state).saveState()
        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
    }

    func applicationWillTerminate(_ application: UIApplication) {
    }

    // MARK: - Generation helper
    func generateNewKey() -> Data {
        let helper = OpenSSLHelper()
        let newKey = helper.generateRandom()
        return newKey!
    }
}
