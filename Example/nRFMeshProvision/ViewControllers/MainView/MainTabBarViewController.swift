//
//  MainTabBarViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Mostafa Berg on 06/03/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import CoreBluetooth
import nRFMeshProvision

class MainTabBarViewController: UITabBarController {

    public func switchToNetworkView() {
        switchToViewAtIndex(0)
    }

    public func switchToAddNodesView() {
        switchToViewAtIndex(1)
    }
    
    public func switchToSettingsView() {
        switchToViewAtIndex(2)
    }

    private func switchToViewAtIndex(_ anIndex: Int) {
        selectedViewController = viewControllers?[anIndex]
        tabBar(tabBar, didSelect: tabBar.items![anIndex])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let viewIndex = tabBar.items?.index(of: tabBar.selectedItem!) {
            setupItemsForItemAt(index: viewIndex)
        }
    }

    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if let index = tabBar.items?.index(of: item) {
            setupItemsForItemAt(index: index)
        }
    }
    
    private func setupItemsForItemAt(index anIndex: Int) {
        let targetView = viewControllers?[anIndex]
        title = targetView?.title
        navigationItem.leftBarButtonItems = targetView?.navigationItem.leftBarButtonItems
        navigationItem.rightBarButtonItems = targetView?.navigationItem.rightBarButtonItems
    }
}
