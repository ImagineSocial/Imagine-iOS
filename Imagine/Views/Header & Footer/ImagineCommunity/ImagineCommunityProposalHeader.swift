//
//  ImagineCommunityProposalHeader.swift
//  Imagine
//
//  Created by Malte Schoppe on 09.03.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit


protocol ImagineCommunityProposalHeaderDelegate {
    func selectionChanged(selection: CampaignType)
}

class ImagineCommunityProposalHeader: UICollectionReusableView {
    
    //MARK:- IBOutlets
    @IBOutlet weak var selectionAllButton: DesignableButton!
    @IBOutlet weak var selectionFeatureButton: DesignableButton!
    @IBOutlet weak var selectionProposalButton: DesignableButton!
    @IBOutlet weak var selectionComplaintButton: DesignableButton!
    
    
    //MARK:- Variables
    var delegate: ImagineCommunityProposalHeaderDelegate?
    
    //MARK:- Cell Lifecycles
    override func awakeFromNib() {
        let buttons: [DesignableButton] = [selectionAllButton, selectionFeatureButton, selectionProposalButton, selectionComplaintButton]
        
        for button in buttons {
            button.cornerRadius = 15
            button.layer.borderWidth = 1
            
            if #available(iOS 13.0, *) {
                button.layer.borderColor = UIColor.secondaryLabel.cgColor
            } else {
                button.layer.borderColor = UIColor.lightGray.cgColor
            }
        }
        
        buttonSelected(button: selectionAllButton)
    }
    
    //MARK:- Button UI
    func buttonSelected(button: DesignableButton) {
        
        let buttons: [DesignableButton] = [selectionAllButton, selectionFeatureButton, selectionProposalButton, selectionComplaintButton]
        
        for button in buttons {
            button.isSelected = false
            
            if #available(iOS 13.0, *) {
                button.layer.borderColor = UIColor.secondaryLabel.cgColor
            } else {
                button.layer.borderColor = UIColor.lightGray.cgColor
            }
        }
        
        button.isSelected = true
        if #available(iOS 13.0, *) {
            button.layer.borderColor = UIColor.label.cgColor
        } else {
            button.layer.borderColor = UIColor.black.cgColor
        }
    }
        
    //MARK:- IBActions
    @IBAction func selectionAllButtonTapped(_ sender: Any) {
        buttonSelected(button: selectionAllButton)
        delegate?.selectionChanged(selection: .all)
    }
    
    @IBAction func selectionFeatureButtonTapped(_ sender: Any) {
        buttonSelected(button: selectionFeatureButton)
        delegate?.selectionChanged(selection: .feature)
    }
    
    @IBAction func selectionProposalButtonTapped(_ sender: Any) {
        buttonSelected(button: selectionProposalButton)
        delegate?.selectionChanged(selection: .proposal)
    }
    
    @IBAction func selectionComplaintButtonTapped(_ sender: Any) {
        buttonSelected(button: selectionComplaintButton)
        delegate?.selectionChanged(selection: .complaint)
    }
}
