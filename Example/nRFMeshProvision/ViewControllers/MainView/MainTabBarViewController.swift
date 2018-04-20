//
//  MainTabBarViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Mostafa Berg on 06/03/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class MainTabBarViewController: UITabBarController {
    //For a quick demo, this is a quick way to pass around the
    //Target proxy node.
    //TODO: This will be added to the library to avoid having the app to decide
    //What node is the proxy.
    public var targetProxyNode: ProvisionedMeshNode?

    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if let index = tabBar.items?.index(of: item) {
            let targetView = self.viewControllers?[index]
            title = targetView?.title
            navigationItem.leftBarButtonItems = targetView?.navigationItem.leftBarButtonItems
            navigationItem.rightBarButtonItems = targetView?.navigationItem.rightBarButtonItems
        }
    }
}
