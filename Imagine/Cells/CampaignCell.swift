//
//  CampaignCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 29.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class CampaignCell: UITableViewCell {
    
    @IBOutlet weak var CellHeaderLabel: UILabel!
    @IBOutlet weak var cellBodyLabel: UILabel!
    @IBOutlet weak var cellCreateCampaignLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var supporterLabel: UILabel!
    @IBOutlet weak var vetoLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    
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
                categoryLabel.text = campaign.category
                
                let category = campaign.category
                var labelColor: UIColor?
                
                switch category {
                case "Management":
                    labelColor = Constants.red
                case "Finanzen":
                    labelColor = Constants.green
                case "Kommunikation":
                    labelColor = Constants.imagineColor
                case "Inhalt":
                    labelColor = .purple
                default:
                    labelColor = .black
                }
                
                categoryLabel.textColor = labelColor
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        progressView.layer.cornerRadius = 2
        progressView.clipsToBounds = true
        
        // add corner radius on `contentView`
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 5
        contentView.clipsToBounds = true
        backgroundColor =  Constants.backgroundColorForTableViews
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        //set the values for top,left,bottom,right margins
        let margins = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        contentView.frame = contentView.frame.inset(by: margins)
    }
    
}
