//
//  BaseStackView.swift
//  Imagine
//
//  Created by Don Malte on 30.11.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

class BaseStackView: UIStackView {
    
    init(subviews: [UIView], spacing: CGFloat = 0, axis: NSLayoutConstraint.Axis, distribution: Distribution = .fill) {
        super.init(frame: .zero)
        
        translatesAutoresizingMaskIntoConstraints = false
        subviews.forEach { addArrangedSubview($0) }
        
        self.spacing = spacing
        
        self.axis = axis
        self.distribution = distribution
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
}
