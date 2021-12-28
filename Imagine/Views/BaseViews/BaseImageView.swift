//
//  BaseImageView.swift
//  Imagine
//
//  Created by Don Malte on 01.12.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

class BaseImageView: UIImageView {
    
    var alignmentInsets: UIEdgeInsets = .zero
    
    init(image: UIImage?, tintColor: UIColor = .label, contentMode: ContentMode = .scaleAspectFit, alignmentInsets: UIEdgeInsets = .zero) {
        super.init(frame: .zero)
        
        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.image = image?.withAlignmentRectInsets(alignmentInsets)
        self.contentMode = contentMode
        self.tintColor = tintColor
        
        self.alignmentInsets = alignmentInsets
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setInsets(insets: UIEdgeInsets) {
        self.image = image?.withAlignmentRectInsets(insets)
    }
}

