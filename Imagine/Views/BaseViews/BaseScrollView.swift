//
//  BaseScrollView.swift
//  Imagine
//
//  Created by Don Malte on 01.12.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

class BaseScrollView: UIScrollView {
    
    init() {
        super.init(frame: .zero)
        
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

