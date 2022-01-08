//
//  TitleView.swift
//  Imagine
//
//  Created by Malte Schoppe on 28.02.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

class TitleView: UIView {
    
    //MARK:- Initialization
    init() {
        super.init(frame: .zero)
        
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .systemBackground
        
        setTitleViewUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK:- Set Up View
    
    func setTitleViewUI() {
        addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
        titleLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        addSubview(characterCountLabel)
        characterCountLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5).isActive = true
        characterCountLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        characterCountLabel.heightAnchor.constraint(equalToConstant: 15).isActive = true
        
        addSubview(titleTextView)
        titleTextView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true
        titleTextView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
        titleTextView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
        titleTextView.bottomAnchor.constraint(equalTo: characterCountLabel.topAnchor).isActive = true
        
    }
    
    //MARK:- UI Init
    let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = NSLocalizedString("newPost_title_label_text", comment: "title:")
        label.font = .standard(with: .medium, size: 15)
        
        return label
    }()
    
    let characterCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "200"
        label.font = .standard(with: .medium, size: 11)
        
        return label
    }()
    
    let titleTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = .standard(size: 14)
        textView.returnKeyType = UIReturnKeyType.next
        textView.enablesReturnKeyAutomatically = true
        
        return textView
    }()
}
