//
//  NewPostLinkCell.swift
//  Imagine
//
//  Created by Don Malte on 08.01.22.
//  Copyright © 2022 Malte Schoppe. All rights reserved.
//

import UIKit

class NewPostLinkCell: NewPostBaseCell {
    
    static let identifier = "NewPostLinkCell"
        
    // MARK: - Elements
    
    let linkLabel = BaseLabel(text: "Link:", font: titleLabelFont)
    let linkTextField = BaseTextField(font: .standard(size: 14), placeholder: "https://...")
    let linkInfoButton = BaseButtonWithImage(image: Icons.info)
    let youTubeImageView = BaseImageView(image: Icons.youTube, tintColor: .secondaryLabel)
    let GIFImageView = BaseImageView(image: Icons.gif, tintColor: .secondaryLabel)
    let songWhipImageView = BaseImageView(image: Icons.music, tintColor: .secondaryLabel)
    let internetImageView = BaseImageView(image: Icons.globe, tintColor: .secondaryLabel)
    
    lazy var webImageViewStackView = BaseStackView(subviews: [internetImageView, youTubeImageView, GIFImageView, songWhipImageView], spacing: 10, axis: .horizontal, distribution: .fillEqually)
        
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        linkTextField.delegate = self
        backgroundColor = .systemBackground
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        
        addSubview(linkLabel)
        addSubview(webImageViewStackView)
        addSubview(linkTextField)
        addSubview(linkInfoButton)
        
        linkLabel.topAnchor.constraint(equalTo: topAnchor, constant: 7).isActive = true
        linkLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding).isActive = true
        linkLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        internetImageView.constrainSquare(width: 20)
        youTubeImageView.constrainSquare(width: 20)
        GIFImageView.constrainSquare(width: 20)
        songWhipImageView.constrainSquare(width: 20)
        
        webImageViewStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding).isActive = true
        webImageViewStackView.centerYAnchor.constraint(equalTo: linkLabel.centerYAnchor).isActive = true
        webImageViewStackView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        webImageViewStackView.widthAnchor.constraint(equalToConstant: 110).isActive = true
        
        linkTextField.topAnchor.constraint(equalTo: linkLabel.bottomAnchor, constant: 10).isActive = true
        linkTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding).isActive = true
        linkTextField.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5).isActive = true
        
        linkInfoButton.centerYAnchor.constraint(equalTo: linkTextField.centerYAnchor).isActive = true
        linkInfoButton.leadingAnchor.constraint(equalTo: linkTextField.trailingAnchor, constant: -10).isActive = true
        linkInfoButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding).isActive = true
        linkInfoButton.heightAnchor.constraint(equalToConstant: infoButtonSize).isActive = true
        linkInfoButton.widthAnchor.constraint(equalToConstant: infoButtonSize).isActive = true
        
        youTubeImageView.alpha = 0.4
        songWhipImageView.alpha = 0.4
        internetImageView.alpha = 0.4
        GIFImageView.alpha = 0.4
        
        linkInfoButton.addTarget(self, action: #selector(linkInfoButtonTapped), for: .touchUpInside)
    }
    
    override func resetInput() {
        super.resetInput()
        
        linkTextField.text = ""
        linkTextField.resignFirstResponder()
    }
    
    //MARK: - Actions
    
    @objc func linkInfoButtonTapped() {
        delegate?.buttonTapped(newPostButton: .linkInfo)
    }
}

extension NewPostLinkCell: UITextFieldDelegate {
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        guard let text = textField.text, text.isValidURL else {
            return
        }
        
        delegate?.textChanged(for: .link, text: text)
        
        internetImageView.alpha = 0.4
        youTubeImageView.alpha = 0.4
        songWhipImageView.alpha = 0.4
        GIFImageView.alpha = 0.4
        
        if let _ = text.youtubeID {
            youTubeImageView.alpha = 1
        } else if text.contains("songwhip.com") || text.contains("music.apple.com") || text.contains("open.spotify.com/") || text.contains("deezer.page.link") {
            songWhipImageView.alpha = 1
        } else if text.contains(".mp4") {
            GIFImageView.alpha = 1
        } else {
            internetImageView.alpha = 1
        }
    }
}
