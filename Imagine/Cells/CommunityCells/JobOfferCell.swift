//
//  JobOfferCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 29.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class JobOfferCell: UITableViewCell {
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var cellBodyLabel: UILabel!
    @IBOutlet weak var interestedCountLabel: UILabel!
    @IBOutlet weak var createDateLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var jobOfferIconImageView: UIImageView!
    
    var needInsets = true
    
    var jobOffer: JobOffer? {
        didSet {
            guard let jobOffer = jobOffer else { return }
            
            headerLabel.text = jobOffer.title
            cellBodyLabel.text = jobOffer.cellText
            createDateLabel.text = jobOffer.stringDate
            interestedCountLabel.text = "\(jobOffer.interested) Interessenten"
            categoryLabel.text = jobOffer.category
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentView.clipsToBounds = true
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
            
            if #available(iOS 13.0, *) {
                self.contentView.backgroundColor = .secondarySystemBackground
            } else {
                self.contentView.backgroundColor = .ios12secondarySystemBackground
            }
            //set the values for top,left,bottom,right margins
            let margins = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
            contentView.frame = contentView.frame.inset(by: margins)
        }
    }
}

