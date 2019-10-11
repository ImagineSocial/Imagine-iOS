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
    @IBOutlet weak var contraCountLabel: UILabel!
    @IBOutlet weak var proCountLabel: UILabel!
    @IBOutlet weak var sourceLabel: UILabel!
    
    
    var argument: Argument? {
        didSet {
            if let argument = argument {
                //                if row % 2 != 0 {
                //                    cell.backgroundColor = UIColor(red:0.96, green:0.96, blue:0.96, alpha:1.0)
                //                    cell.layer.cornerRadius = 4
                //                }
                
                headerLabel.text = argument.title
                bodyLabel.text = argument.description
                let upString = NSLocalizedString("consent: %d", comment: "How many people agree with the argument")
                proCountLabel.text = String.localizedStringWithFormat(upString, argument.upvotes)
                let downString = NSLocalizedString("doubt: %d", comment: "How many people disagree with the given argument")
                contraCountLabel.text = String.localizedStringWithFormat(downString, argument.downvotes)
                
                sourceLabel.text = "Quelle: Nicht überprüft ⚠️"
                
                
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
        
        // add corner radius on `contentView`
        contentView.layer.cornerRadius = 5
        contentView.clipsToBounds = true
        backgroundColor =  .clear
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        //set the values for top,left,bottom,right margins
        let margins = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        contentView.frame = contentView.frame.inset(by: margins)
    }
}
