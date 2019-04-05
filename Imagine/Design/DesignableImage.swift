//
//  DesignableImage.swift
//  Imagine
//
//  Created by Malte Schoppe on 05.04.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import Foundation

import UIKit

@IBDesignable class DesignableImage: UIImageView {
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            self.layer.cornerRadius = cornerRadius
        }
    }
}
