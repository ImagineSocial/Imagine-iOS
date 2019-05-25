//
//  JobOfferCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 29.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class SupportTheCommunityCell: UITableViewCell {
    var delegate: JobOfferCellDelegate?
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var cellBodyLabel: UILabel!
    @IBOutlet weak var interestedCountLabel: UILabel!
    @IBOutlet weak var createDateLabel: UILabel!
    
    var jobOfferObject: JobOffer!
    
    func setJobOffer(jobOffer: JobOffer) {
        jobOfferObject = jobOffer
    }
    
    @IBAction func morePressed(_ sender: Any) {
        delegate?.MoreTapped(jobOffer: jobOfferObject)
    }
    
    
    
}

