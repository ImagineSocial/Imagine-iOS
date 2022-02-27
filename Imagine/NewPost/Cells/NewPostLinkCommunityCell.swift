//
//  NewPostLinkCommunityCell.swift
//  Imagine
//
//  Created by Don Malte on 10.01.22.
//  Copyright © 2022 Malte Schoppe. All rights reserved.
//

import UIKit

class NewPostLinkCommunityCell: NewPostBaseCell {
    
    // MARK: - Variables
    
    static let identifier = "NewPostLinkCommunityCell"
        
    let defaultOptionViewHeight = Constants.NewPostConstants.defaultOptionViewHeight
    
    let linkCommunityButton = BaseButtonWithText(text: Strings.newPostLinkCommunity, titleColor: .imagineColor, font: .standard(with: .medium, size: 14))
    let linkedCommunityLabel = BaseLabel(font: .standard(with: .medium, size: 14), textAlignment: .right)
    let distributionLabel = BaseLabel(text: Strings.newPostDestinationLabel, font: titleLabelFont, textAlignment: .left)
    let distributionInformationLabel = BaseLabel(text: "Feed", textColor: .secondaryLabel, font: .standard(with: .medium, size: 14), textAlignment: .left)
    let distributionInformationImageView = BaseImageView(image: Icons.feed, tintColor: .secondaryLabel)
    let distributionInformationView = BaseView()
    let linkedCommunityInfoButton = BaseButtonWithImage(image: Icons.info)
    let cancelLinkedCommunityButton = BaseButtonWithImage(image: Icons.dismiss, tintColor: .darkRed)
    
    let addedFactImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 4
        imageView.layer.borderColor = UIColor.black.cgColor
        imageView.layer.borderWidth = 0.5
        imageView.contentMode = .scaleAspectFill
        imageView.isHidden = true
        
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
                
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .systemBackground
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Show Linked Community
    
    func showLinkedCommunity(community: Community) {
        
        linkCommunityButton.isHidden = true
        cancelLinkedCommunityButton.isHidden = false
        cancelLinkedCommunityButton.cornerRadius = cancelLinkedCommunityButton.frame.width/2
        addedFactImageView.isHidden = false
        linkedCommunityLabel.isHidden = false
        
        if let url = URL(string: community.imageURL) {
            addedFactImageView.sd_setImage(with: url, completed: nil)
        } else {
            addedFactImageView.image = UIImage(named: "default-community")
        }
         
        linkedCommunityLabel.text = "'\(community.title)'"
    }
    
    func removeLinkedCommunity() {
        changeCommunityDestination(communityOnly: false)
        
        cancelLinkedCommunityButton.isHidden = true
        addedFactImageView.isHidden = true
        linkedCommunityLabel.isHidden = true
        linkCommunityButton.isHidden = false
    }
    
    func changeCommunityDestination(communityOnly: Bool) {
        
        distributionInformationLabel.text = communityOnly ? "Community" : "Feed"
        distributionInformationImageView.image = communityOnly ? UIImage(named: "topicIcon") : UIImage(named: "Feed")
    }
    
    // MARK: - Set Up View
    
    override func setupConstraints() {
        super.setupConstraints()
        
        let labelHeight: CGFloat = 17
        let smallOptionViewHeight = defaultOptionViewHeight-4
        
        addSubview(distributionLabel)
        addSubview(linkedCommunityInfoButton)
        addSubview(linkCommunityButton)
        addSubview(distributionInformationView)
        
        addSubview(addedFactImageView)
        addSubview(cancelLinkedCommunityButton)
        addSubview(linkedCommunityLabel)
        
        distributionInformationView.addSubview(distributionInformationLabel)
        distributionInformationView.addSubview(distributionInformationImageView)
        
        NSLayoutConstraint.activate([
            distributionInformationImageView.leadingAnchor.constraint(equalTo: distributionInformationView.leadingAnchor),
            distributionInformationImageView.centerYAnchor.constraint(equalTo: distributionInformationView.centerYAnchor),
            distributionInformationImageView.widthAnchor.constraint(equalToConstant: 23),
            distributionInformationImageView.heightAnchor.constraint(equalToConstant: 23),
            
            distributionInformationLabel.leadingAnchor.constraint(equalTo: distributionInformationImageView.trailingAnchor, constant: 5),
            distributionInformationLabel.trailingAnchor.constraint(equalTo: distributionInformationView.trailingAnchor, constant: -3),
            distributionInformationLabel.centerYAnchor.constraint(equalTo: distributionInformationView.centerYAnchor)
        ])
        
        NSLayoutConstraint.activate([
            
            distributionLabel.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            distributionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            distributionLabel.heightAnchor.constraint(equalToConstant: labelHeight),
            
            distributionInformationView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            distributionInformationView.topAnchor.constraint(equalTo: distributionLabel.bottomAnchor, constant: 10),
            distributionInformationView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
            distributionInformationView.heightAnchor.constraint(equalToConstant: smallOptionViewHeight - 15),
            
            linkedCommunityInfoButton.centerYAnchor.constraint(equalTo: distributionInformationView.centerYAnchor),
            linkedCommunityInfoButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            linkedCommunityInfoButton.widthAnchor.constraint(equalToConstant: infoButtonSize),
            linkedCommunityInfoButton.heightAnchor.constraint(equalToConstant: infoButtonSize),
            
            linkCommunityButton.centerYAnchor.constraint(equalTo: distributionInformationView.centerYAnchor),
            linkCommunityButton.trailingAnchor.constraint(equalTo: linkedCommunityInfoButton.leadingAnchor, constant: -10),
            linkCommunityButton.heightAnchor.constraint(equalToConstant: 35),
            
            addedFactImageView.centerYAnchor.constraint(equalTo: distributionInformationView.centerYAnchor),
            addedFactImageView.heightAnchor.constraint(equalToConstant: defaultOptionViewHeight-15),
            addedFactImageView.trailingAnchor.constraint(equalTo: cancelLinkedCommunityButton.leadingAnchor, constant: -10),
            addedFactImageView.widthAnchor.constraint(equalToConstant: defaultOptionViewHeight-15),
            
            linkedCommunityLabel.centerYAnchor.constraint(equalTo: addedFactImageView.centerYAnchor),
            linkedCommunityLabel.trailingAnchor.constraint(equalTo: addedFactImageView.leadingAnchor, constant: -10),
            
            cancelLinkedCommunityButton.trailingAnchor.constraint(equalTo: linkedCommunityInfoButton.leadingAnchor, constant: -10),
            cancelLinkedCommunityButton.centerYAnchor.constraint(equalTo: distributionInformationView.centerYAnchor),
            cancelLinkedCommunityButton.widthAnchor.constraint(equalToConstant: infoButtonSize),
            cancelLinkedCommunityButton.heightAnchor.constraint(equalToConstant: infoButtonSize)
        ])
        
        linkCommunityButton.addTarget(self, action: #selector(linkFactToPostTapped), for: .touchUpInside)
        linkedCommunityInfoButton.addTarget(self, action: #selector(linkedFactInfoButtonTapped), for: .touchUpInside)
        cancelLinkedCommunityButton.addTarget(self, action: #selector(cancelLinkedFactTapped), for: .touchUpInside)
        cancelLinkedCommunityButton.isHidden = true
    }
    
    override func resetInput() {
        super.resetInput()
        
        removeLinkedCommunity()
    }
    
    // MARK: - Actions
    
    @objc func linkFactToPostTapped() {
        delegate?.buttonTapped(newPostButton: .linkCommunity)
    }
    
    @objc func linkedFactInfoButtonTapped() {
        delegate?.buttonTapped(newPostButton: .linkedCommunityInfo)
    }
    
    @objc func cancelLinkedFactTapped() {
        delegate?.buttonTapped(newPostButton: .cancelLinkedCommunity)
    }
}

