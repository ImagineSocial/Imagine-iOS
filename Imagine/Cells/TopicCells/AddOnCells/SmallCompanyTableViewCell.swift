//
//  SmallCompanyTableViewCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 07.03.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit

class SmallCompanyTableViewCell: UITableViewCell {
    
    @IBOutlet weak var companyImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var additionalInformationLabel: UILabel!
    
//    var company: Company? {
//        didSet {
//            nameLabel.text = company!.name
//            
//        }
//    }
    
    override func awakeFromNib() {
        companyImageView.layer.cornerRadius = 4
    }
    
}
