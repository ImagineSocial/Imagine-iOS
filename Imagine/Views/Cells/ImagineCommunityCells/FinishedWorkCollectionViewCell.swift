//
//  FinishedWorkCollectionViewCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 12.03.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

protocol FinishedWorkCellDelegate {
    func showCampaignTapped(campaignID: String)
}

class FinishedWorkCollectionViewCell: UICollectionViewCell {
    
    //MARK:- IBOutlets
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var showCampaignButton: DesignableButton!
    
    //MARK:- Variables
    var finishedWorkItem: FinishedWorkItem? {
        didSet {
            if let finishedWork = finishedWorkItem {
                mainLabel.text = finishedWork.title
                dateLabel.text = finishedWork.createDateString
            }
        }
    }
    var delegate: FinishedWorkCellDelegate?
    
    //MARK:- Show/Hide Description
    func showDescription() {
        if let item = finishedWorkItem {

            if item.campaignID != nil {
                showCampaignButton.isHidden = false
            }
            descriptionLabel.text = item.description
            mainLabel.font = UIFont(name: "IBMPlexSans-Medium", size: 16)
        }
    }
    
    func hideDescription() {
        showCampaignButton.isHidden = true
        descriptionLabel.text = ""
        mainLabel.font = UIFont(name: "IBMPlexSans", size: 15)
    }
    
    //MARK:- Cell Lifecycle
    override func awakeFromNib() {
        let layer = contentView.layer
        layer.borderWidth = 0.5
        if #available(iOS 13.0, *) {
            layer.borderColor = UIColor.label.cgColor
        } else {
            layer.borderColor = UIColor.black.cgColor
        }
        layer.cornerRadius = 15
    }
    
    override func prepareForReuse() {
        hideDescription()
    }
    
    //MARK:- IBActions
    @IBAction func showCampaignTapped(_ sender: Any) {
        if let finishedWorkItem = self.finishedWorkItem, let id = finishedWorkItem.campaignID {
            delegate?.showCampaignTapped(campaignID: id)
        }
    }
}
