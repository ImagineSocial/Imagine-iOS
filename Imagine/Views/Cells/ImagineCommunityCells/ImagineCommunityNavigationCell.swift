//
//  ImagineCommunityNavigationCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 07.03.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

enum CommunityCellButtonType {
    case feedback
    case imagineFund
    case moreInfo
    case proposals
    case help
    case settings
    case website
}

protocol CommunityCollectionCellDelegate {
    func buttonTapped(button: CommunityCellButtonType)
}

class ImagineCommunityNavigationCell: UICollectionViewCell {
    
    //MARK:- IBOutlets
    @IBOutlet weak var imagineFundButton: UIButton!
    @IBOutlet weak var websiteButton: DesignableButton!
    @IBOutlet weak var proposalButton: DesignableButton!
    @IBOutlet weak var helpButton: DesignableButton!
    @IBOutlet weak var settingButton: DesignableButton!
    @IBOutlet weak var infoButton: DesignableButton!
    @IBOutlet weak var feedbackButton: UIButton!
    
    //MARK:- Variables
    var delegate: CommunityCollectionCellDelegate?
    
    //MARK: - Cell Lifecycle
    override func awakeFromNib() {
        
        // Set contentMode for imageView of buttons
        let buttons: [DesignableButton] = [websiteButton!, proposalButton!, helpButton!, settingButton!, infoButton!]
        for button in buttons {
            button.imageView?.contentMode = .scaleAspectFit
        }
    }
    
    
    //MARK:- IBActions
    @IBAction func imagineFundButtonTapped(_ sender: Any) {
        delegate?.buttonTapped(button: .imagineFund)
    }
    
    @IBAction func websiteButtonTapped(_ sender: Any) {
        delegate?.buttonTapped(button: .website)
    }
    
    @IBAction func proposalButtonTapped(_ sender: Any) {
        delegate?.buttonTapped(button: .proposals)
    }
    
    @IBAction func helpButtonTapped(_ sender: Any) {
        delegate?.buttonTapped(button: .help)
    }
    
    @IBAction func settingButtonTapped(_ sender: Any) {
        delegate?.buttonTapped(button: .settings)
    }
    
    @IBAction func infoButtonTapped(_ sender: Any) {
        delegate?.buttonTapped(button: .moreInfo)
    }
    
    @IBAction func feedbackButtonTapped(_ sender: Any) {
        delegate?.buttonTapped(button: .feedback)
    }
}
