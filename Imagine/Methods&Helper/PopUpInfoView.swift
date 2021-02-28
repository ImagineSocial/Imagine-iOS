//
//  PopUpInfoView.swift
//  Imagine
//
//  Created by Malte Schoppe on 10.10.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit

enum PopUpInfoType {
    case communityHeader
    case likes
    case userFeed
    case newPost
}

class PopUpInfoView: UIView {
    
    let defaults = UserDefaults.standard
    
    var type: PopUpInfoType? {
        didSet {
            if let type = type {
                switch type {
                case .communityHeader:
                    imageView.image = UIImage(named: "infoViewCommunityHeader")
                case .likes:
                    imageView.image = UIImage(named: "infoViewLikes")
                case .userFeed:
                    imageView.image = UIImage(named: "infoViewProfile")
                case .newPost:
                    imageView.image = UIImage(named: "infoViewNewPost")
                }
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(imageView)
        imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        
        self.addSubview(dismissButton)
        dismissButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -50).isActive = true
        dismissButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -50).isActive = true
        dismissButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        dismissButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        
        dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
    }
    
    @objc func dismissTapped() {
        print("Dismiss tapped")
        if let type = type {
            switch type {
            case .communityHeader:
                defaults.set(true, forKey: "communityHeaderInfo")
            case .likes:
                defaults.set(true, forKey: "likesInfo")
            case .userFeed:
                defaults.set(true, forKey: "userFeedInfo")
            case .newPost:
                defaults.set(true, forKey: "newPostInfo")
            }
        }
        
        UIView.animate(withDuration: 0.5) {
            self.alpha = 0
        } completion: { (_) in
            self.removeFromSuperview()
        }        
    }
    
    let dismissButton: DesignableButton = {
       let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(NSLocalizedString("done", comment: "done"), for: .normal)
        button.titleLabel?.font = UIFont(name: "IBMPlexSans-Medium", size: 20)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .white
        button.cornerRadius = 12
        button.clipsToBounds = true
        
        return button
    }()
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true
        
        return imageView
    }()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
