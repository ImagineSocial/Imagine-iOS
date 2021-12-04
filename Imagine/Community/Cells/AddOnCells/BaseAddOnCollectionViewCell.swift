//
//  BaseAddOnCollectionViewCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 17.09.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit

protocol AddOnCellDelegate: class {
    func showDescription()
    func settingsTapped(itemRow: Int)
    func thanksTapped(info: AddOn)
    
    //CollectionViewDelegate
    func itemTapped(item: Any)
    func newPostTapped(addOn: AddOn)
}

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
            
            contentView.layer.createStandardShadow(with: contentView.bounds.size, cornerRadius: cornerRadius)
        }
    }
}
