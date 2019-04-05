//
//  DesignablePopUp.swift
//  Imagine
//
//  Created by Malte Schoppe on 04.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

@IBDesignable class DesignablePopUp: UIView {
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            self.layer.cornerRadius = cornerRadius
        }
    }
}
