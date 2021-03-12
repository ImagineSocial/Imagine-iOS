//
//  CommunityHeader.swift
//  Imagine
//
//  Created by Malte Schoppe on 12.03.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

protocol ImagineCommunityHeaderDelegate {
    func expandButtonTapped()
}

class CommunityHeader: UICollectionReusableView {
    
    //MARK:- IBOutlets
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var expandButton: DesignableButton!
    
    //MARK:- Variables
    var isOpen: Bool? {
        didSet {
            if let isOpen = isOpen, isOpen {
                expandButton.setImage(UIImage(named: "up"), for: .normal)
            } else {
                expandButton.setImage(UIImage(named: "down"), for: .normal)
            }
        }
    }
    
    var delegate: ImagineCommunityHeaderDelegate?
    
    //MARK:- IBActions
    @IBAction func expandButtonTapped(_ sender: Any) {
    
        delegate?.expandButtonTapped()
    }
    
    //MARK:- View Lifecycle
    override func prepareForReuse() {
        expandButton.isHidden = true
    }
}
