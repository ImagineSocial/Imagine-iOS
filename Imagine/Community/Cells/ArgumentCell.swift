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
//                let upString = NSLocalizedString("consent: %d", comment: "How many people agree with the argument")
                let downvotes = argument.downvotes
                let upvotes = -downvotes+argument.upvotes
                numberOfUpvotesLabel.text = String(upvotes)
//                nummer für die upvotes berechnen und neues Warnzeichen für Quelle
//                proCountLabel.text = String.localizedStringWithFormat(upString, argument.upvotes)
//                let downString = NSLocalizedString("doubt: %d", comment: "How many people disagree with the given argument")
//                contraCountLabel.text = String.localizedStringWithFormat(downString, argument.downvotes)
                
                sourceLabel.text = "Quelle: Nicht überprüft"
                
                
//                if argument.source.isEmpty {    // For now, später muss wahrheitswert der Quellen überprüft werden
//                    // Keine Quelle
//                    sourceLabel.text = "Quelle: 🚫"
//                } else {
//                    sourceLabel.text = " Quelle: ✅ | ▼ \(downVotes/3)  ▲ \(upvotes/3)"
//                }
                
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
