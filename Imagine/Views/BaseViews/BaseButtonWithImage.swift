//
//  BaseButtonWithImage.swift
//  Imagine
//
//  Created by Don Malte on 28.11.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

class BaseButtonWithImage: DesignableButton {
    
    init(image: UIImage?, tintColor: UIColor = .imagineColor, cornerRadius: CGFloat = 0, borderColor: CGColor?) {
        super.init()
        
        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.tintColor = tintColor
        self.imageView?.contentMode = .scaleAspectFit
        self.setImage(image, for: .normal)
        
        self.layer.cornerRadius = cornerRadius
        self.layer.borderColor = borderColor
        self.layer.borderWidth = borderColor != nil ? 1 : 0
    }
    
    init(tintColor: UIColor) {
        super.init()
        
        self.translatesAutoresizingMaskIntoConstraints = false
        self.imageView?.contentMode = .scaleAspectFit
        
        self.setImage(UIImage(named: "infoIcon"), for: .normal)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
