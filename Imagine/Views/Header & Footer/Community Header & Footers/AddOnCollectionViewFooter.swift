//
//  AddOnCollectionViewFooter.swift
//  Imagine
//
//  Created by Malte Schoppe on 01.09.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit

protocol AddOnFooterViewDelegate: class {
    func goToAddOnStore()
}

class AddOnCollectionViewFooter: UICollectionReusableView {
    
    @IBOutlet weak var addOnStoreButton: DesignableButton!
    weak var delegate: AddOnFooterViewDelegate?
    
    override func awakeFromNib() {
        let layer = addOnStoreButton.layer
        layer.cornerRadius = 4
        if #available(iOS 13.0, *) {
            layer.borderColor = UIColor.label.cgColor
        } else {
            layer.borderColor = UIColor.black.cgColor
        }
        layer.borderWidth = 0.5
        
    }
    
    
    @IBAction func addOnStoreTapped(_ sender: Any) {
        delegate?.goToAddOnStore()
    }
    @IBAction func infoButtonTapped(_ sender: Any) {
    }
    
}
