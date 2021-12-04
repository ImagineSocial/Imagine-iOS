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
                
        contentView.layer.cornerRadius = cornerRadius ?? Constants.cellCornerRadius
        
        let shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius ?? Constants.cellCornerRadius)
        layer.masksToBounds = false
        layer.shadowColor = UIColor.label.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowOpacity = 0.5
        layer.shadowRadius = 3
        layer.shadowPath = shadowPath.cgPath
        layer.cornerRadius = cornerRadius ?? Constants.cellCornerRadius
    }
}

/*
let shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: Values.cornerRadius)
layer.masksToBounds = false
layer.shadowColor = UIColor.black.cgColor
layer.shadowOffset = CGSize(width: 0, height: 7.5)
layer.shadowOpacity = 0.1
layer.shadowRadius = 10
layer.shadowPath = shadowPath.cgPath
 */
