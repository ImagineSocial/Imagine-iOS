//
//  NewPostTitleCell.swift
//  Imagine
//
//  Created by Don Malte on 08.01.22.
//  Copyright © 2022 Malte Schoppe. All rights reserved.
//

import UIKit

class NewPostTitleCell: NewPostBaseCell {
    
    static let identifier = "NewPostTitleCell"
    
    // MARK: - Elements
    
    let titleLabel = BaseLabel(text: Strings.newPostTitleLabel, font: titleLabelFont)
    let characterCountLabel = BaseLabel(text: "200", font: .standard(with: .medium, size: 11))
    let titleTextView = BaseTextView(font: .standard(size: 14), returnType: .done)
    
    let characterLimitForTitle = Constants.characterLimits.postTitleCharacterLimit
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
                
        titleTextView.delegate = self
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        
        addSubview(titleLabel)
        addSubview(characterCountLabel)
        addSubview(titleTextView)
        
        titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding).isActive = true
        titleLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        characterCountLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding).isActive = true
        characterCountLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        characterCountLabel.heightAnchor.constraint(equalToConstant: 15).isActive = true
        
        titleTextView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true
        titleTextView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding).isActive = true
        titleTextView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding).isActive = true
        titleTextView.bottomAnchor.constraint(equalTo: characterCountLabel.topAnchor).isActive = true
        titleTextView.heightAnchor.constraint(equalToConstant: 75).isActive = true
    }
    
    override func resetInput() {
        super.resetInput()
        
        titleTextView.text = ""
        characterCountLabel.text = "200"
        titleTextView.resignFirstResponder()
    }
}

//MARK: - TextViewDelegate

extension NewPostTitleCell: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        // No lineBreaks in titleTextView
        guard text.rangeOfCharacter(from: CharacterSet.newlines) == nil else {
            textView.resignFirstResponder()
            return false  // Switch to description when "continue" is hit on keyboard
        }
        
        return textView.text.count + (text.count - range.length) <= characterLimitForTitle
    }
    
    func textViewDidChange(_ textView: UITextView) {
        
        let characterLeft = characterLimitForTitle - textView.text.count
        characterCountLabel.text = String(characterLeft)
        
        delegate?.textChanged(for: .title, text: textView.text)
    }
}

