//
//  SliderCellDelegate.swift
//  nRFMeshProvision_Example
//
//  Created by Mostafa Berg on 01/10/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation

protocol SliderCellDelegate {
    func didChangeSliderOnCell(aCell: SliderControlTableViewCell, didSetSliderValueTo newSliderValue: Float, asLastValue isLast: Bool)
}
