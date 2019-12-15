//
//  VerticalButton.swift
//  Imagine
//
//  Created by Malte Schoppe on 13.12.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import Foundation
import UIKit

extension UILabel {
    @IBInspectable
    var rotation: Int {
        get {
            return 0
        } set {
            let radians = CGFloat(CGFloat(Double.pi) * CGFloat(newValue) / CGFloat(180.0))
            self.transform = CGAffineTransform(rotationAngle: radians)
        }
    }
}

class VerticalButton: UIButton {

    override func titleRect(forContentRect bounds: CGRect) -> CGRect {
        var frame: CGRect = super.titleRect(forContentRect: bounds)

        frame.origin.y = 0
        frame.size.height = bounds.size.height

        return frame
    }
}
