//
//  AddFactTableViewCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 14.09.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class AddFactCell: UITableViewCell {
        
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        
        self.contentView.addSubview(TextLabel)
        TextLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        TextLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 10).isActive = true
        TextLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true
        TextLabel.widthAnchor.constraint(equalToConstant: 90).isActive = true
        
        contentView.clipsToBounds = true
        backgroundColor =  .clear
        
        // add Border
        if #available(iOS 13.0, *) {
            TextLabel.layer.borderColor = UIColor.label.cgColor
        } else {
            TextLabel.layer.borderColor = UIColor.black.cgColor
        }
        TextLabel.layer.borderWidth = 0.75
        TextLabel.layer.cornerRadius = 6
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    let TextLabel :UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 14)
        if #available(iOS 13.0, *) {
            label.textColor = .label
        } else {
            label.textColor = .black
        }
        label.minimumScaleFactor = 0.5
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .center
        label.text = "Hinzufügen"
        
        return label
    }()
}

