//
//  FlagSettingsPopoverViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Mostafa Berg on 30/07/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit

class FlagSettingsPopoverViewController: UIViewController {

    //MARK: - Outlets and actions
    @IBAction func saveButtonTapped(_ sender: Any) {
        handleSave()
    }

    @IBAction func cancelButtonTapped(_ sender: Any) {
        handleCancel()
    }

    @IBOutlet weak var ivUpdateControl: UISegmentedControl!
    @IBOutlet weak var keyRefreshPhaseControl: UISegmentedControl!

    //MARK: - Properties
    var completionHandler: ((Data?) -> (Void))?
    var flagData: Data!
    var cancelled: Bool = true

    //MARK: - UIViewController
    override func viewWillDisappear(_ animated: Bool) {
        guard cancelled == false else {
            completionHandler?(nil)
            super.viewWillDisappear(animated)
            return
        }
        //Save changes
        var flags: UInt8 = 0
        if keyRefreshPhaseControl.selectedSegmentIndex == 1 {
            flags |= 0x80
        }
        if ivUpdateControl.selectedSegmentIndex == 1 {
            flags |= 0x40
        }
        if flagData[0] == flags {
            completionHandler?(nil)
        } else {
            flagData = Data([flags])
            completionHandler?(flagData)
        }
        super.viewWillDisappear(animated)
    }
    
    //MARK: - Implementation
    public func setFlagData(_ someData: Data, andCompletionHandler aHandler:@escaping (Data?) -> (Void)) {
        completionHandler = aHandler
        flagData = someData
        if flagData[0] & 0x80 == 0x80 {
            keyRefreshPhaseControl.selectedSegmentIndex = 1
        }
        if flagData[0] & 0x40 == 0x40 {
            ivUpdateControl.selectedSegmentIndex = 1
        }
    }
    
    private func handleSave() {
        cancelled = false
        self.dismiss(animated: true, completion: nil)
    }

    private func handleCancel() {
        cancelled = true
        self.dismiss(animated: true, completion: nil)
    }
}
