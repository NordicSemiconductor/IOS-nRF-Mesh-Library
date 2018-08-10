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
    public var meshManager: NRFMeshManager!

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        meshManager = NRFMeshManager()
        UserDefaults.standard.register(defaults: [UserDefaultsKeys.autoRejoinKey : false])
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
}
