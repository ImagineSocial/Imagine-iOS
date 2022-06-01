//
//  BaseButtonWithText.swift
//  Imagine
//
//  Created by Don Malte on 27.11.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

class BaseButtonWithText: DesignableButton {
    
    init(text: String = "", titleColor: UIColor = .label, font: UIFont? = UIFont.standard(), cornerRadius: CGFloat = 0, backgroundColor: UIColor = .clear, borderColor: CGColor? = nil) {
        super.init()
        
        self.translatesAutoresizingMaskIntoConstraints = false
        self.setTitle(text, for: .normal)
        self.setTitleColor(titleColor, for: .normal)
        self.titleLabel?.font = font
        
        self.layer.cornerRadius = cornerRadius
        
        self.layer.borderColor = borderColor
        self.layer.borderWidth = borderColor != nil ? 1 : 0
        
        self.backgroundColor = backgroundColor
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
