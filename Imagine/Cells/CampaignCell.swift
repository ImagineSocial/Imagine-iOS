//
//  CampaignCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 29.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class VoteCampaignCell: UITableViewCell {
    var delegate: CampaignCellDelegate?
    
    @IBOutlet weak var CellHeaderLabel: UILabel!
    @IBOutlet weak var cellBodyLabel: UILabel!
    @IBOutlet weak var cellCreateCampaignLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var supporterLabel: UILabel!
    @IBOutlet weak var vetoLabel: UILabel!
    
    var campaignObject: Campaign!
    
    func setCampaign(campaign: Campaign) {
        campaignObject = campaign
    }
    
    @IBAction func cellButtonPressed(_ sender: Any) {
        
        delegate?.MoreTapped(campaign: campaignObject)
    }
    
}
