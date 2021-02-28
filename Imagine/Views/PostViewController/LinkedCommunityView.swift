//
//  LinkedCommunityView.swift
//  Imagine
//
//  Created by Malte Schoppe on 26.02.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

class LinkedCommunityView: UIView {
    
    //MARK:- Variables
    var community: Community? {
        didSet {
            if let community = community {
                linkedFactLabel.text = "'\(community.title)'"
                
                if let url = URL(string: community.imageURL) {
                    linkedFactImageView.sd_setImage(with: url, completed: nil)
                } else {
                    linkedFactImageView.image = UIImage(named: "FactStamp")
                }
                
                layer.borderColor = UIColor.imagineColor.cgColor
                linkedFactImageView.layer.borderColor = UIColor.imagineColor.cgColor
            }
        }
    }
    
    //MARK:- View Initializer
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        
        
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 4
        layer.borderWidth = 1
        layer.borderColor = UIColor.clear.cgColor
        
        setUpUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK:- Set Up UI
    
    func setUpUI() {
        let buttonHeight: CGFloat = 35
        
        addSubview(linkedFactImageView)
        linkedFactImageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        linkedFactImageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        linkedFactImageView.widthAnchor.constraint(equalToConstant: buttonHeight).isActive = true
        linkedFactImageView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        
        addSubview(linkedFactLabel)
        linkedFactLabel.leadingAnchor.constraint(equalTo: linkedFactImageView.trailingAnchor, constant: 10).isActive = true
        linkedFactLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
        linkedFactLabel.centerYAnchor.constraint(equalTo: linkedFactImageView.centerYAnchor).isActive = true
        
    }
    
    
    //MARK:- Initialize UI Elements
    
    let linkedFactImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 4
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.clear.cgColor
        imageView.clipsToBounds = true
        
        return imageView
    }()
    
    let linkedFactLabel: UILabel = {
       let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans", size: 14)
        label.minimumScaleFactor = 0.5
        label.textAlignment = .center

        return label
    }()
}
