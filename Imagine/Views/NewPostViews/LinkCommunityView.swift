//
//  LinkedCommunityView.swift
//  Imagine
//
//  Created by Malte Schoppe on 01.03.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

class LinkCommunityView: UIView {
    
    //MARK:- Variables
    var newPostVC: NewPostViewController?
    let infoButtonSize = Constants.NewPostConstants.infoButtonSize
    let defaultOptionViewHeight = Constants.NewPostConstants.defaultOptionViewHeight
    
    //MARK:- Initialization
    init(newPostVC: NewPostViewController) {
        super.init(frame: CGRect())
        self.newPostVC = newPostVC
        
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .systemBackground
        
        setUpLinkedCommunityViewUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK:- Show Linked Community
    func showLinkedCommunity(community: Community) {
        
        addFactButton.isHidden = true
        cancelLinkedFactButton.isHidden = false
        cancelLinkedFactButton.cornerRadius = cancelLinkedFactButton.frame.width/2
        addedFactImageView.isHidden = false
        addedFactDescriptionLabel.isHidden = false
        
        if let url = URL(string: community.imageURL) {
            addedFactImageView.sd_setImage(with: url, completed: nil)
        } else {
            addedFactImageView.image = UIImage(named: "default-community")
        }
         
        addedFactDescriptionLabel.text = "'\(community.title)'"
    }
    
    //MARK:- Hide Linked Community
    func hideLinkedCommunity() {
        distributionInformationLabel.text = "Feed"
        distributionInformationImageView.image = UIImage(named: "Feed")
        
        cancelLinkedFactButton.isHidden = true
        addedFactImageView.isHidden = true
        addedFactDescriptionLabel.isHidden = true
        addFactButton.isHidden = false
    }
    
    
    //MARK:- Set Up View
    
    private func setUpLinkedCommunityViewUI() {

        let labelHeight: CGFloat = 17
        let smallOptionViewHeight = defaultOptionViewHeight-4
        
        addSubview(distributionLabel)
        distributionLabel.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
        distributionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
        distributionLabel.heightAnchor.constraint(equalToConstant: labelHeight).isActive = true

        addSubview(linkedFactInfoButton)
        linkedFactInfoButton.centerYAnchor.constraint(equalTo: centerYAnchor, constant: labelHeight/2).isActive = true
        linkedFactInfoButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
        linkedFactInfoButton.widthAnchor.constraint(equalToConstant: infoButtonSize-1).isActive = true
        linkedFactInfoButton.heightAnchor.constraint(equalToConstant: infoButtonSize-1).isActive = true
        
        addSubview(addFactButton)
        addFactButton.centerYAnchor.constraint(equalTo: centerYAnchor, constant: labelHeight/2).isActive = true
        addFactButton.trailingAnchor.constraint(equalTo: linkedFactInfoButton.leadingAnchor, constant: -10).isActive = true
        addFactButton.heightAnchor.constraint(equalToConstant: 35).isActive = true
        
        distributionInformationView.addSubview(distributionInformationImageView)
        distributionInformationImageView.leadingAnchor.constraint(equalTo: distributionInformationView.leadingAnchor).isActive = true
        distributionInformationImageView.centerYAnchor.constraint(equalTo: distributionInformationView.centerYAnchor).isActive = true
        distributionInformationImageView.widthAnchor.constraint(equalToConstant: 23).isActive = true
        distributionInformationImageView.heightAnchor.constraint(equalToConstant: 23).isActive = true
        
        distributionInformationView.addSubview(distributionInformationLabel)
        distributionInformationLabel.leadingAnchor.constraint(equalTo: distributionInformationImageView.trailingAnchor, constant: 5).isActive = true
        distributionInformationLabel.trailingAnchor.constraint(equalTo: distributionInformationView.trailingAnchor, constant: -3).isActive = true
        distributionInformationLabel.centerYAnchor.constraint(equalTo: distributionInformationView.centerYAnchor).isActive = true
        
        addSubview(distributionInformationView)
        distributionInformationView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
//        distributionInformationView.trailingAnchor.constraint(equalTo: addFactButton.leadingAnchor, constant: -3).isActive = true
        distributionInformationView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: labelHeight/2).isActive = true
        distributionInformationView.heightAnchor.constraint(equalToConstant: smallOptionViewHeight-15).isActive = true

        addSubview(addedFactImageView)
        addSubview(cancelLinkedFactButton)
        addSubview(addedFactDescriptionLabel)
        
        NSLayoutConstraint.activate([
            addedFactImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 10),
            addedFactImageView.heightAnchor.constraint(equalToConstant: defaultOptionViewHeight-15),
            addedFactImageView.trailingAnchor.constraint(equalTo: linkedFactInfoButton.leadingAnchor, constant: -10),
            addedFactImageView.widthAnchor.constraint(equalToConstant: defaultOptionViewHeight-15),
            
            addedFactDescriptionLabel.centerYAnchor.constraint(equalTo: addedFactImageView.centerYAnchor),
            addedFactDescriptionLabel.trailingAnchor.constraint(equalTo: addedFactImageView.leadingAnchor, constant: -10),
            
            cancelLinkedFactButton.trailingAnchor.constraint(equalTo: addedFactImageView.trailingAnchor, constant: 9),
            cancelLinkedFactButton.topAnchor.constraint(equalTo: addedFactImageView.topAnchor, constant: -9),
            cancelLinkedFactButton.widthAnchor.constraint(equalToConstant: 18),
            cancelLinkedFactButton.heightAnchor.constraint(equalToConstant: 18)
        ])
    }

    
    //MARK:- UI Init
    
    let addFactButton: DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .imagineColor
        button.setTitle(NSLocalizedString("distribution_button_text", comment: "link community"), for: .normal)
        button.addTarget(self, action: #selector(linkFactToPostTapped), for: .touchUpInside)
        button.titleLabel?.font = UIFont(name: "IBMPlexSans-Medium", size: 14)
        button.setTitleColor(.imagineColor, for: .normal)
        
        return button
    }()
    
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
    
    let addedFactDescriptionLabel: UILabel = {
       let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 14)
        label.textAlignment = .right
        
        return label
    }()
    
    let distributionLabel: UILabel = {
       let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 14)
        label.textAlignment = .left
        label.text = NSLocalizedString("distribution_label_text", comment: "destination:")
        label.textColor = .label
        
        return label
    }()
    
    let distributionInformationLabel: UILabel = {   // Shows where the post will be posted: In a topic only or in the main Feed
       let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 14)
        label.textAlignment = .left
        label.text = "Feed"
        label.textColor = .secondaryLabel
        
        return label
    }()
    
    let distributionInformationImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "Feed")    //topicIcon
        imageView.tintColor = .secondaryLabel
        
        return imageView
    }()
    
    let distributionInformationView: UIView = {
       let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        view.backgroundColor = .systemBackground
        
        return view
    }()
    
    let linkedFactInfoButton :DesignableButton = {
        let button = DesignableButton(type: .detailDisclosure)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .imagineColor
        button.addTarget(self, action: #selector(linkedFactInfoButtonTapped), for: .touchUpInside)
        
        return button
    }()
    
    let cancelLinkedFactButton: DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "DismissTemplate"), for: .normal)
        button.addTarget(self, action: #selector(cancelLinkedFactTapped), for: .touchUpInside)
        button.tintColor = .darkRed
        button.backgroundColor = .systemBackground
        button.imageEdgeInsets = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
        button.isHidden = true
        button.clipsToBounds = true

        return button
    }()
    
    //MARK:- Actions
    
    @objc func linkFactToPostTapped() {
        guard let newPostVC = newPostVC else { return }
        newPostVC.linkFactToPostTapped()
    }
    
    @objc func linkedFactInfoButtonTapped() {
        guard let newPostVC = newPostVC else { return }
        newPostVC.linkedFactInfoButtonTapped()
    }
    
    @objc func cancelLinkedFactTapped() {
        guard let newPostVC = newPostVC else { return }
        newPostVC.cancelLinkedFactTapped()
    }
}
