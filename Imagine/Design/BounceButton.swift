//
//  BounceButton.swift
//  Imagine
//
//  Created by Malte Schoppe on 25.02.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//
import UIKit

class BounceButton: UIButton {
    
    override func  touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        self.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 6, options: .allowUserInteraction, animations: {
            self.transform = CGAffineTransform.identity
        }, completion: nil)
        
        super.touchesBegan(touches, with: event)
    }
}

