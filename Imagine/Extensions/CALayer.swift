//
//  CALayer.swift
//  Imagine
//
//  Created by Don Malte on 04.12.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

extension CALayer {
    func createStandardShadow(with size: CGSize, cornerRadius: CGFloat = Constants.cellCornerRadius, small: Bool = false) {
        
        let smallItem = UITraitCollection.current.userInterfaceStyle == .light || small
        let shadowRadius = smallItem ? Constants.Numbers.feedShadowRadius : Constants.Numbers.feedShadowRadius / 2
        
        let shadowOffset: CGFloat
        
        if UITraitCollection.current.userInterfaceStyle == .light {
            shadowOffset = small ? 2.5 : 5
        } else {
            shadowOffset = 0            
        }
         
        
        self.cornerRadius = cornerRadius
        self.shadowColor = UIColor.label.cgColor
        self.shadowOffset = CGSize(width: 0, height: shadowOffset)
        self.shadowRadius = shadowRadius
        self.shadowOpacity = 0.25
        self.masksToBounds = false
                
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        self.shadowPath = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).cgPath
    }
}
