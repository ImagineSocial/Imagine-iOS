//
//  UIColor.swift
//  Imagine
//
//  Created by Don Malte on 01.11.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

extension UIColor {
    
    static let imagineColor = UIColor(red:0.33, green:0.47, blue:0.65, alpha:1.0)   //#5377A6
    static let ios12secondarySystemBackground = UIColor(red: 242/255, green: 242/255, blue: 247/255, alpha: 1.0) ////Light Mode Secondary System Background Color for older than ios13
    //#f2f2f7ff
    static let darkRed = UIColor(red: 0.69, green: 0.00, blue: 0.00, alpha: 1.00)
    
    
    
    static let accentColor = blend(color1: .green, color2: .purple)
    
    static func blend(color1: UIColor, intensity1: CGFloat = 0.5, color2: UIColor, intensity2: CGFloat = 0.5) -> UIColor {
        let total = intensity1 + intensity2
        let l1 = intensity1/total
        let l2 = intensity2/total
        guard l1 > 0 else { return color2}
        guard l2 > 0 else { return color1}
        var (r1, g1, b1, a1): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        var (r2, g2, b2, a2): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        
        color1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        return UIColor(red: l1*r1 + l2*r2, green: l1*g1 + l2*g2, blue: l1*b1 + l2*b2, alpha: l1*a1 + l2*a2)
    }
}
