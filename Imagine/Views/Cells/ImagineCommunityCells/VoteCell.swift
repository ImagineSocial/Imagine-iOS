//
//  VoteCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 22.07.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class VoteCell: UICollectionViewCell {
    
    //MARK:- IBOutlets
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var voteTillDateLabel: UILabel!
    @IBOutlet weak var costLabel: UILabel!
    @IBOutlet weak var timePeriodLabel: UILabel!
    @IBOutlet weak var impactLabel: UILabel!
    @IBOutlet weak var commentCountLabel: UILabel!
    
    //MARK:- Variables
    var needInsets = true
    
    var vote: Vote? {
        didSet {
            guard let vote = vote else { return }
            
            headerLabel.text = vote.title
            bodyLabel.text = vote.subtitle
            voteTillDateLabel.text = "Abstimmung bis: \(vote.endOfVoteDate)"
            costLabel.text = vote.cost
            timePeriodLabel.text = "\(vote.timeToRealization) Monat"
            commentCountLabel.text = "0"
            
            voteTillDateLabel.layer.cornerRadius = 4
            impactLabel.layer.cornerRadius = 4
            
            switch vote.impact {
            case .light:
                impactLabel.text = "Auswirkung: Leicht"
                impactLabel.backgroundColor = Constants.green
            case .medium:
                impactLabel.text = "Auswirkung: Medium"
                impactLabel.backgroundColor = .orange
            case .strong:
                impactLabel.text = "Auswirkung: Stark"
                impactLabel.backgroundColor = Constants.red
            }
        }
    }
    
    //MARK:- Cell Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // add corner radius on `contentView`
        contentView.layer.cornerRadius = 5
        backgroundColor =  .clear
    }
    
    override func prepareForReuse() {
        if #available(iOS 13.0, *) {
            contentView.backgroundColor = .systemBackground
        } else {
            contentView.backgroundColor = .white
        }
        contentView.layer.borderWidth = 0
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if needInsets {
            //set the values for top,left,bottom,right margins
            let margins = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
            contentView.frame = contentView.frame.inset(by: margins)
            
            if #available(iOS 13.0, *) {
                self.contentView.backgroundColor = .secondarySystemBackground
            } else {
                self.contentView.backgroundColor = .ios12secondarySystemBackground
            }
        }
    }
}
