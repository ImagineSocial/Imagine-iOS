//
//  AddOnHeaderView.swift
//  Imagine
//
//  Created by Malte Schoppe on 29.04.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit

protocol AddOnHeaderDelegate {
    func showDescription(description: String, view: UIView)
    func showAllPosts(documentID: String)
}

class AddOnHeaderView: UIView {
    
    var addOnDescription: String?
    var delegate: AddOnHeaderDelegate?
    
    func initHeader(noOptionalInformation: Bool, info: OptionalInformation) {
        
        layoutIfNeeded()
        
        if let description = info.description {
            self.addOnDescription = description
        }
        if noOptionalInformation {
            label.text = "Erweitere das Thema"
        } else {
            label.text = info.headerTitle
        }
        
        self.addSubview(descriptionButton)
        descriptionButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 5).isActive = true
        descriptionButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10).isActive = true
        descriptionButton.widthAnchor.constraint(equalToConstant: 25).isActive = true
        descriptionButton.heightAnchor.constraint(equalToConstant: 25).isActive = true
        
        self.addSubview(label)
        label.topAnchor.constraint(equalTo: self.topAnchor, constant: 5).isActive = true
        label.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -5).isActive = true
        label.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10).isActive = true
        label.trailingAnchor.constraint(equalTo: descriptionButton.leadingAnchor, constant: -45).isActive = true
        
        if info.items.count >= 10 {
            self.addSubview(showAllPostsButton)
            showAllPostsButton.topAnchor.constraint(equalTo: descriptionButton.bottomAnchor, constant: -5).isActive = true
            showAllPostsButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10).isActive = true
            showAllPostsButton.widthAnchor.constraint(equalToConstant: 75).isActive = true
            showAllPostsButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
            showAllPostsButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -5).isActive = true
        }
    }
    
    let showAllPostsButton: DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Show all", for: .normal)
        button.titleLabel?.font = UIFont(name: "IBMPlexSans-Medium", size: 14)
        button.setTitleColor(.imagineColor, for: .normal)
        button.addTarget(self, action: #selector(showAllTapped), for: .touchUpInside)
        
        return button
    }()
    
    let descriptionButton: DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "about"), for: .normal)
        button.tintColor = .imagineColor
        button.addTarget(self, action: #selector(showDescription), for: .touchUpInside)
        
        return button
    }()
    
    let label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans-Bold", size: 18)
        label.minimumScaleFactor = 0.85
        label.adjustsFontSizeToFitWidth = true
        label.numberOfLines = 0
        
        return label
    }()
    
    @objc func showDescription() {
        if let description = addOnDescription {
            delegate?.showDescription(description: description, view: self)
        }
    }
    
    @objc func showAllTapped() {
        //todo
    }
    
}

