//
//  BaseTextView.swift
//  Imagine
//
//  Created by Don Malte on 08.01.22.
//  Copyright © 2022 Malte Schoppe. All rights reserved.
//

import UIKit

class BaseTextView: UITextView {
    
    init(text: String = "", textColor: UIColor = .label, font: UIFont? = UIFont.standard(), returnType: UIReturnKeyType = .next) {
        super.init(frame: .zero, textContainer: nil)
        
        self.translatesAutoresizingMaskIntoConstraints = false
        self.text = text
        self.textColor = textColor
        self.font = font
        self.returnKeyType = returnType
        self.layoutIfNeeded()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
