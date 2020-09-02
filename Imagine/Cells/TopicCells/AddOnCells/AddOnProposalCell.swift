//
//  AddOnProposalCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 01.09.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit

class AddOnProposalCell: UICollectionViewCell {
    
    @IBOutlet weak var proposalTitleLabel: UILabel!
    @IBOutlet weak var proposalDescriptionLabel: UILabel!
    @IBOutlet weak var proposalImageView: UIImageView!
    @IBOutlet weak var proposalImageWidth: NSLayoutConstraint!
    
    var proposal: ProposalForOptionalInformation? {
        didSet {
            if let proposal = proposal {
                proposalTitleLabel.text = proposal.headerText
                proposalDescriptionLabel.text = proposal.detailText
                
                if proposal.isFirstCell {
                    proposalImageView.isHidden = true
                    proposalImageWidth.constant = 0
                    proposalTitleLabel.font = UIFont(name: "IBMPlexSans-Medium", size: 19)
                    proposalDescriptionLabel.font = UIFont(name: "IBMPlexSans", size: 15)
                }
            }
        }
    }
}
