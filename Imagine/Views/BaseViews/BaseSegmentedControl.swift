//
//  BaseSegmentedControl.swift
//  Imagine
//
//  Created by Don Malte on 27.11.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

class BaseSegmentedControl: UISegmentedControl {
    
    init(items: [Any], tintColor: UIColor = .imagineColor, font: UIFont? = UIFont.standard(), selectedItem: Int = 0) {
        super.init(items: items)
        self.translatesAutoresizingMaskIntoConstraints = false
        
        let font: [AnyHashable : Any] = [NSAttributedString.Key.font : font as Any]
        self.setTitleTextAttributes(font as? [NSAttributedString.Key : Any], for: .normal)
        self.tintColor = tintColor
        self.selectedSegmentIndex = selectedItem
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
