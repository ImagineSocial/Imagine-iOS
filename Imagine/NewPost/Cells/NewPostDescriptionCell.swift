//
//  NewPostDescriptionCell.swift
//  Imagine
//
//  Created by Don Malte on 08.01.22.
//  Copyright © 2022 Malte Schoppe. All rights reserved.
//

import UIKit

class NewPostDescriptionCell: NewPostBaseCell {
    
    static let identifier = "NewPostDescriptionCell"
        
    // MARK: - Elements
    
    let descriptionLabel = BaseLabel(text: Strings.newPostDescriptionLabel, font: titleLabelFont)
    let descriptionTextView = BaseTextView(font: .standard(size: 14), returnType: .default)
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
                
        descriptionTextView.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    override func setupConstraints() {
        super.setupConstraints()
        
        addSubview(descriptionLabel)
        descriptionLabel.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
        descriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding).isActive = true
        descriptionLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        addSubview(descriptionTextView)
        descriptionTextView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor).isActive = true
        descriptionTextView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding).isActive = true
        descriptionTextView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding).isActive = true
        descriptionTextView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        descriptionTextView.heightAnchor.constraint(equalToConstant: 75).isActive = true
    }
    
    override func resetInput() {
        super.resetInput()
        
        descriptionTextView.text = ""
        descriptionTextView.resignFirstResponder()
    }
}

extension NewPostDescriptionCell: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        
        delegate?.textChanged(for: .description, text: textView.text)
    }
}
