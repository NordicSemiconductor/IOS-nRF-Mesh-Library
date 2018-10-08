//
//  SliderControlTableViewCell.swift
//  nRFMeshProvision_Example
//
//  Created by Mostafa Berg on 01/10/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit

class SliderControlTableViewCell: UITableViewCell {
    // MARK: - Properties
    public var delegate: SliderCellDelegate?
    // MARK: - Outlets and actions
    @IBOutlet weak var titleLabel   : UILabel!
    @IBOutlet weak var sliderControl : UISlider!
    @IBOutlet weak var sliderReadableValue: UILabel!
    @IBAction func didSlide(_ sender: Any) {
        self.handleSliderStateChange(value: sliderControl.value, didEnd: false)
    }

    @IBAction func didChangeValue(_ sender: Any) {
        self.handleSliderStateChange(value: sliderControl.value, didEnd: true)
    }

    // MARK: - Implementation
    public func setTitle(aTitle: String) {
        titleLabel.text = aTitle
    }

    private func handleSliderStateChange(value: Float, didEnd: Bool) {
        delegate?.didChangeSliderOnCell(aCell: self, didSetSliderValueTo: sliderControl.value, asLastValue: didEnd)
    }
}
