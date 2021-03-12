//
//  CampaignCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 29.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class CampaignCell: UICollectionViewCell {
    
    //MARK:- IBOutlets
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var CellHeaderLabel: UILabel!
    @IBOutlet weak var cellBodyLabel: UILabel!
    @IBOutlet weak var cellCreateCampaignLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var supporterLabel: UILabel!
    @IBOutlet weak var vetoLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    
    //MARK:- Variables
    var campaign:Campaign? {
        didSet {
            if let campaign = campaign {
                
                CellHeaderLabel.text = campaign.title
                cellBodyLabel.text = campaign.cellText
                cellCreateCampaignLabel.text = campaign.createDate
                
                let progress: Float = Float(campaign.supporter) / (Float(campaign.opposition) + Float(campaign.supporter))
                progressView.setProgress(progress, animated: true)
                supporterLabel.text = "\(campaign.supporter) Supporter"
                vetoLabel.text = "\(campaign.opposition) Vetos"
                
                if let category = campaign.category {
                    categoryLabel.text = category.title
                }
            }
        }
    }
    
    //MARK:- Cell Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        
        progressView.layer.cornerRadius = 2
        progressView.clipsToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        let cornerRadius = Constants.cellCornerRadius
        containerView.layer.cornerRadius = cornerRadius
        contentView.setDefaultShadow()
    }
    
}
