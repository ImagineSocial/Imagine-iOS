//
//  NotificationCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 11.11.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class NotificationCell: UITableViewCell {
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var mainTextLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    override func awakeFromNib() {
        // add corner radius on `contentView`
//        contentView.backgroundColor = Constants.imagineColor
        contentView.layer.cornerRadius = 8
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = Constants.imagineColor.cgColor
        
        messageLabel.backgroundColor = .red
        messageLabel.layer.cornerRadius = messageLabel.frame.height/2
        messageLabel.layer.masksToBounds = true
        
        layer.masksToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        //set the values for top,left,bottom,right margins
        let margins = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
        contentView.frame = contentView.frame.inset(by: margins)
    }
    
    override func prepareForReuse() {
        messageLabel.backgroundColor = .red
    }
    
    var comment:Comment? {
        didSet {
            if let comment = comment {
                
                if let vote = comment.upvotes {
                    
                    let count = vote.thanks+vote.wow+vote.ha+vote.nice
                    
                    if count == 1 {
                        headerLabel.text = "Dein Beitrag wurde geliked"
                    } else {
                        headerLabel.text = "Dein Beitrag wurde \(count) mal geliked"
                    }
                    
                    mainTextLabel.text = comment.title.quoted
                } else {
                    headerLabel.text = "\(comment.author) hat kommentiert:"
                    mainTextLabel.text = "\(comment.text)".quoted
                }
            }
        }
    }
    
}
