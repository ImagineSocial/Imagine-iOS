//
//  BaseCollectionViewCell.swift
//  Imagine
//
//  Created by Don Malte on 04.12.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

class BaseCollectionViewCell: UICollectionViewCell {
    
    var cornerRadius: CGFloat?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        contentView.clipsToBounds = false
        clipsToBounds = false
        
        contentView.layer.createStandardShadow(with: bounds.size, cornerRadius: cornerRadius ?? Constants.cellCornerRadius)
    }
}
