//
//  FinishedWorkCollectionViewCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 12.03.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

class FinishedWorkCollectionViewCell: UICollectionViewCell {
    
    //MARK:- IBOutlets
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    //MARK:- Variables
    var finishedWorkItem: FinishedWorkItem? {
        didSet {
            if let finishedWork = finishedWorkItem {
                mainLabel.text = finishedWork.title
                dateLabel.text = finishedWork.createDateString
            }
        }
    }
    
    //MARK:- Show/Hide Description
    func showDescription() {
        if let item = finishedWorkItem {

            descriptionLabel.text = item.description
            mainLabel.font = UIFont(name: "IBMPlexSans-Medium", size: 16)
        }
    }
    
    func hideDescription() {
        
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
        descriptionLabel.text = ""
        mainLabel.font = UIFont(name: "IBMPlexSans", size: 15)
    }
    
}
