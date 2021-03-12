//
//  DataReportCollectionViewCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 11.03.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

class DataReportCollectionViewCell: UICollectionViewCell {
    
    //MARK:- IBOutlets
    @IBOutlet weak var containerView: UIView!
    
    //MARK:- Variables
    private let cornerRadius = Constants.cellCornerRadius
    
    override func layoutSubviews() {
        
        containerView.layer.cornerRadius = cornerRadius
        contentView.setDefaultShadow()
    }
    
    
}
