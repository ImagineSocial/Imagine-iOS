//
//  BaseLabel.swift
//  Imagine
//
//  Created by Don Malte on 27.11.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

class BaseLabel: UILabel {
    
    init(text: String = "", textColor: UIColor = .label, font: UIFont? = UIFont.standard(), textAlignment: NSTextAlignment = .left, backgroundColor: UIColor = .clear, cornerRadius: CGFloat = 0) {
        super.init(frame: .zero)
        
        self.translatesAutoresizingMaskIntoConstraints = false
        self.text = text
        self.textColor = textColor
        self.font = font
        self.textAlignment = textAlignment
        self.backgroundColor = backgroundColor
        self.layer.cornerRadius = cornerRadius
        
        self.clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
