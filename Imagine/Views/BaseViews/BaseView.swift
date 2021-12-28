//
//  BaseView.swift
//  Imagine
//
//  Created by Don Malte on 30.11.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

class BaseView: UIView {
    
    init(backgroundColor: UIColor = .systemBackground) {
        super.init(frame: .zero)
        
        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = backgroundColor
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
