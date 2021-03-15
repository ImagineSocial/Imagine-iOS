//
//  CampaignCollectionHeaderView.swift
//  Imagine
//
//  Created by Malte Schoppe on 12.03.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

protocol CampaignCollectionHeaderDelegate {
    func newCampaignTapped()
}

class CampaignCollectionHeaderView: UICollectionReusableView {

    //MARK:- IBOutlets
    @IBOutlet weak var subHeaderLabel: UILabel!
    @IBOutlet weak var shareIdeaButton: DesignableButton!
    @IBOutlet weak var shareIdeaButtonIcon: UIImageView!
    
    //MARK:- Variables
    var delegate: CampaignCollectionHeaderDelegate?
    
    //MARK:- View Lifecycle
    override func awakeFromNib() {
        let lay = shareIdeaButton.layer
        lay.borderColor = UIColor.imagineColor.cgColor
        lay.borderWidth = 1
    }
    
    @IBAction func shareIdeaTapped(_ sender: Any) {
        delegate?.newCampaignTapped()
    }
}

