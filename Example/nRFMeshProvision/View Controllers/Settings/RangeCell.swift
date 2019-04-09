//
//  RangeCell.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 08/04/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class RangeCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var rangeView: RangeView!
    
    var range: ClosedRange<UInt16>! {
        didSet {
            label.text = range.asString()
            rangeView.clearRanges()
            rangeView.addRange(range)
        }
    }
    
    var otherRanges: [ClosedRange<UInt16>]! {
        didSet {
            rangeView.addOtherRanges(otherRanges)
        }
    }
    
}
