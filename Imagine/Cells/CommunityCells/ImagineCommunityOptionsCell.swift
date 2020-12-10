//
//  ImagineCommunityOptionsCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 03.10.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit

enum CommunityCellButtonType {
    case feedback
    case imagineFund
    case moreInfo
    case proposals
    case help
    case settings
}

protocol CommunityCollectionCellDelegate {
    func buttonTapped(button: CommunityCellButtonType)
}

class ImagineCommunityOptionsCell: UICollectionViewCell {
    
    @IBOutlet weak var imagineFundButton: DesignableButton!
    @IBOutlet weak var visionButton: DesignableButton!
    @IBOutlet weak var moreInfoButton: DesignableButton!
    @IBOutlet weak var settingButton: DesignableButton!
    @IBOutlet weak var helpWantedButton: DesignableButton!
    @IBOutlet weak var proposalsButton: DesignableButton!
    
    var buttons = [DesignableButton]()
    let cornerRadius: CGFloat = 8
    
    var delegate: CommunityCollectionCellDelegate?
    
    override func awakeFromNib() {
        let twoLineButtons = [imagineFundButton!, moreInfoButton!]
        for button in twoLineButtons {
            button.titleLabel?.numberOfLines = 0
            button.titleLabel?.textAlignment = .center
        }
        
        self.buttons.append(contentsOf: [imagineFundButton, visionButton, moreInfoButton, settingButton, helpWantedButton, proposalsButton])
        setButtons()
        
        settingButton.imageView?.contentMode = .scaleAspectFit
        settingButton.imageView?.clipsToBounds = true
    }
    
    func setButtons() {
        for button in buttons {
            let layer = button.layer
            
            if #available(iOS 13.0, *) {
                layer.shadowColor = UIColor.label.cgColor
            } else {
                layer.shadowColor = UIColor.black.cgColor
            }
            layer.shadowOffset = CGSize.zero
            layer.shadowRadius = 3
            layer.shadowOpacity = 0.4
        }
    }
    
    @IBAction func imagineFundButtonTapped(_ sender: Any) {
        delegate?.buttonTapped(button: .imagineFund)
    }
    
    @IBAction func visionButtonTapped(_ sender: Any) {
        delegate?.buttonTapped(button: .feedback)
    }
    
    @IBAction func helpWantedButtonTapped(_ sender: Any) {
        delegate?.buttonTapped(button: .help)
    }
    @IBAction func proposalsButtonTapped(_ sender: Any) {
        delegate?.buttonTapped(button: .proposals)
    }
    @IBAction func settingButtonTapped(_ sender: Any) {
        delegate?.buttonTapped(button: .settings)
    }
    @IBAction func moreInfoButtonTapped(_ sender: Any) {
        delegate?.buttonTapped(button: .moreInfo)
    }
    
}
