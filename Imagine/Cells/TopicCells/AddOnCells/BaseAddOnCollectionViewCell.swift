//
//  BaseAddOnCollectionViewCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 17.09.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit

class BaseAddOnCollectionViewCell: UICollectionViewCell {
    
    let cornerRadius: CGFloat = 20
    var isAddOnCell = true  //If the singleTopic is user in the FeedSingleTopicCell
    
    override var isHighlighted: Bool {
        didSet {
            toggleIsHighlighted()
        }
    }

    func toggleIsHighlighted() {
        UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseOut], animations: {
            self.alpha = self.isHighlighted ? 0.9 : 1.0
            self.transform = self.isHighlighted ?
                CGAffineTransform.identity.scaledBy(x: 0.97, y: 0.97) :
                CGAffineTransform.identity
        })
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if isAddOnCell {
            let layer = contentView.layer
            if #available(iOS 13.0, *) {
                layer.shadowColor = UIColor.label.cgColor
            } else {
                layer.shadowColor = UIColor.black.cgColor
            }
            layer.shadowOffset = CGSize(width: 0, height: 0)
            layer.shadowRadius = 4
            layer.shadowOpacity = 0.6
            
            let rect = CGRect(x: 0, y: 0, width: contentView.frame.width, height: contentView.frame.height)
            layer.shadowPath = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).cgPath
        }
    }
}
