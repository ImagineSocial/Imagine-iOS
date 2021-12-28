//
//  DescriptionView.swift
//  Imagine
//
//  Created by Malte Schoppe on 28.02.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

class DescriptionView: UIView {
    
    //MARK:- Initialization
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .systemBackground
        
        setDescriptionViewUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    //MARK:- Set Up View
    func setDescriptionViewUI() {   // have to set descriptionview topanchor
        addSubview(descriptionLabel)
        descriptionLabel.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
        descriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
        descriptionLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        addSubview(descriptionTextView)
        descriptionTextView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor).isActive = true
        descriptionTextView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
        descriptionTextView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
        descriptionTextView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    
    //MARK:- UI Init
    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = NSLocalizedString("decriptionLabelText", comment: "...:")
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 15)
        
        return label
    }()
    
    let descriptionTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = UIFont(name: "IBMPlexSans", size: 14)
        
        return textView
    }()
    
}
