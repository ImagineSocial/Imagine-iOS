//
//  HairlineView.swift
//  Imagine
//
//  Created by Malte Schoppe on 07.03.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit

class HairlineView: UIView {
    override func awakeFromNib() {
        super.awakeFromNib()

        for constraint in self.constraints {
            if let _ = constraint.firstItem as? HairlineView,
               constraint.firstAttribute == .height,
               constraint.firstAnchor.isKind(of: NSLayoutDimension.self),
               constraint.secondItem == nil,
               constraint.secondAnchor == nil {
                constraint.constant = (1.0 / UIScreen.main.scale)
                return
            }
        }
    }
}

