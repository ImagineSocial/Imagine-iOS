//
//  FactCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 22.05.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class ArgumentCell: UITableViewCell {

    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var sourceLabel: UILabel!
    @IBOutlet weak var numberOfUpvotesLabel: UILabel!
    
    let cornerRadius: CGFloat = 6
    
    
    var argument: Argument? {
        didSet {
            if let argument = argument {
                
                headerLabel.text = argument.title
                bodyLabel.text = argument.description

                let downvotes = argument.downvotes
                let upvotes = -downvotes+argument.upvotes
                numberOfUpvotesLabel.text = String(upvotes)
                sourceLabel.text = Strings.sourceNotChecked
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
 
        contentView.clipsToBounds = false
        
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        //set the values for top,left,bottom,right margins
        let margins = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        contentView.frame = contentView.frame.inset(by: margins)

        contentView.layer.cornerRadius = cornerRadius
        
        let layer = contentView.layer
        layer.shadowColor = UIColor.label.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowRadius = 2
        layer.shadowOpacity = 0.4

        let frame = CGRect(x: 0, y: 0, width: contentView.frame.width, height: contentView.frame.height)
        layer.shadowPath = UIBezierPath(roundedRect: frame, cornerRadius: cornerRadius).cgPath
    }
}
