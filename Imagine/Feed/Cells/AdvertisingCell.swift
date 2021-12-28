//
//  AdvertisingCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 24.04.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit

class AdvertisingCell: BaseFeedCell {
    
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var adTitleLabel: UILabel!
    
    var title: String? {
        didSet {
            adTitleLabel.text = title!
        }
    }
    
    override func awakeFromNib() {
        
        contentView.layer.cornerRadius = 8
        backgroundColor = .clear
        
        let gradient = CAGradientLayer()
        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradient.endPoint = CGPoint(x: 0.5, y: 0.6)
        let whiteColor = UIColor.white
        gradient.colors = [whiteColor.withAlphaComponent(0.0).cgColor, whiteColor.withAlphaComponent(0.5).cgColor, whiteColor.withAlphaComponent(0.7).cgColor]
        gradient.locations = [0.0, 0.7, 1]
        gradient.frame = gradientView.bounds
        
        gradientView.layer.mask = gradient
    }
    
}
