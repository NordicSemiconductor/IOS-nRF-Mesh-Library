//
//  ToggleCellDelegate.swift
//  nRFMeshProvision_Example
//
//  Created by Mostafa Berg on 28/05/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation

protocol ToggleCellDelegate {
    func didToggleCell(aCell: ToggleControlTableViewCell, didSetOnStateTo newOnState: Bool)
}
