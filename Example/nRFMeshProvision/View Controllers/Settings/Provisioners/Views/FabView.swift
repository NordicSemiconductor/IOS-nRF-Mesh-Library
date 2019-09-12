//
//  FabView.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 11/04/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

@IBDesignable
class FabView: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        setup()
    }

    private func setup() {
        tintColor = UIColor.white
        contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        layer.cornerRadius = 16
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.cgColor
        layer.backgroundColor = UIColor.nordicRed.cgColor
        layer.shadowColor = UIColor.gray.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 2
        
        addTarget(self, action: #selector(pressed), for: .touchDown)
        addTarget(self, action: #selector(released), for: .touchUpInside)
        addTarget(self, action: #selector(released), for: .touchUpOutside)
    }
    
    @objc func pressed() {
        layer.backgroundColor = UIColor.nordicRedDark.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 1.5
    }
    
    @objc func released() {
        layer.backgroundColor = UIColor.nordicRed.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 2
    }

}
