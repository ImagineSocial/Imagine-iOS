//
//  DesignableButton.swift
//  Imagine
//
//  Created by Malte Schoppe on 25.02.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class DesignableButton: UIButton {
    
    init(image: UIImage? = nil, cornerRadius: CGFloat = 0, tintColor: UIColor = .label, backgroundColor: UIColor = .clear, clipsToBounds: Bool = true, imageContentMode: ContentMode = .scaleAspectFit) {
        super.init(frame: .zero)
        
        self.translatesAutoresizingMaskIntoConstraints = false
        self.layer.cornerRadius = cornerRadius
        self.tintColor = tintColor
        self.backgroundColor = backgroundColor
        self.clipsToBounds = true
        self.imageView?.contentMode = imageContentMode
        
        self.setImage(image, for: .normal)
    }
    
    init(title: String, font: UIFont? = UIFont(name: "IBMPlexSans", size: 16), cornerRadius: CGFloat = 0, tintColor: UIColor = .label, backgroundColor: UIColor = .clear, clipsToBounds: Bool = true) {
        super.init(frame: .zero)
        
        self.setTitle(title, for: .normal)
        self.setTitleColor(tintColor, for: .normal)
        self.titleLabel?.font = font
        self.translatesAutoresizingMaskIntoConstraints = false
        self.layer.cornerRadius = cornerRadius
        self.tintColor = tintColor
        self.backgroundColor = backgroundColor
        self.clipsToBounds = true
    }
    
    init(sort: Bool) {
        super.init(frame: .zero)
        
        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = .clear
        self.titleLabel?.font = UIFont(name: "IBMPlexSans", size: 13)
        self.contentHorizontalAlignment = .left
        self.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0);
        
        self.setTitleColor(.label, for: .normal)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            self.layer.cornerRadius = cornerRadius
        }
    }
    
    
    
    // MARK: - Bounce Effect
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        self.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 6, options: .allowUserInteraction, animations: {
            self.transform = CGAffineTransform.identity
        }, completion: nil)
        
        super.touchesBegan(touches, with: event)
    }
}

