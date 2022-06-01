//
//  BaseTextField.swift
//  Imagine
//
//  Created by Don Malte on 08.01.22.
//  Copyright © 2022 Malte Schoppe. All rights reserved.
//

import UIKit

class BaseTextField: UITextField {
    
    init(text: String = "", textColor: UIColor = .label, font: UIFont? = UIFont.standard(), borderStyle: UITextField.BorderStyle = .none, placeholder: String = "") {
        super.init(frame: .zero)
        
        self.translatesAutoresizingMaskIntoConstraints = false
        self.text = text
        self.textColor = textColor
        self.font = font
        self.borderStyle = borderStyle
        self.placeholder = placeholder
        self.layoutIfNeeded()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
