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
                    labelColor = .red
                case "Finanzen":
                    labelColor = .green
                case "Kommunikation":
                    labelColor = .blue
                case "Inhalt":
                    labelColor = .purple
                default:
                    labelColor = .black
                }
                
                categoryLabel.textColor = labelColor
            }
        }
    }
    
}
