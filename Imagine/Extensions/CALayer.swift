//
//  CALayer.swift
//  Imagine
//
//  Created by Don Malte on 04.12.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

extension CALayer {
    func createStandardShadow(with size: CGSize, cornerRadius: CGFloat = Constants.cellCornerRadius) {
        let shadowRadius = UITraitCollection.current.userInterfaceStyle == .light ? Constants.Numbers.feedShadowRadius : 5
        let shadowOffset: CGFloat = UITraitCollection.current.userInterfaceStyle == .light ? 5 : 0
        
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
