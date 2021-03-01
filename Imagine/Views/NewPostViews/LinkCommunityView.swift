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
        if #available(iOS 13.0, *) {
            backgroundColor = .systemBackground
        } else {
            backgroundColor = .white
        }
        
        setUpLinkedCommunityViewUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK:- Set Up View
    
    func setUpLinkedCommunityViewUI() {

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
        addFactButton.trailingAnchor.constraint(equalTo: linkedFactInfoButton.leadingAnchor, constant: -20).isActive = true
//        addFactButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        addFactButton.heightAnchor.constraint(equalToConstant: 35).isActive = true
        
        distributionInformationView.addSubview(distributionInformationImageView)
        distributionInformationImageView.leadingAnchor.constraint(equalTo: distributionInformationView.leadingAnchor).isActive = true
        distributionInformationImageView.centerYAnchor.constraint(equalTo: distributionInformationView.centerYAnchor).isActive = true
        distributionInformationImageView.widthAnchor.constraint(equalToConstant: 23).isActive = true
        distributionInformationImageView.heightAnchor.constraint(equalToConstant: 23).isActive = true
        
        distributionInformationView.addSubview(distributionInformationLabel)
        distributionInformationLabel.leadingAnchor.constraint(equalTo: distributionInformationImageView.trailingAnchor, constant: 2).isActive = true
        distributionInformationLabel.trailingAnchor.constraint(equalTo: distributionInformationView.trailingAnchor, constant: -3).isActive = true
        distributionInformationLabel.centerYAnchor.constraint(equalTo: distributionInformationView.centerYAnchor).isActive = true
        
        addSubview(distributionInformationView)
        distributionInformationView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
//        distributionInformationView.trailingAnchor.constraint(equalTo: addFactButton.leadingAnchor, constant: -3).isActive = true
        distributionInformationView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: labelHeight/2).isActive = true
        distributionInformationView.heightAnchor.constraint(equalToConstant: smallOptionViewHeight-15).isActive = true

        addSubview(cancelLinkedFactButton)
        cancelLinkedFactButton.trailingAnchor.constraint(equalTo: linkedFactInfoButton.leadingAnchor, constant: -10).isActive = true
        cancelLinkedFactButton.widthAnchor.constraint(equalToConstant: infoButtonSize).isActive = true
        cancelLinkedFactButton.heightAnchor.constraint(equalToConstant: infoButtonSize).isActive = true
        cancelLinkedFactButton.centerYAnchor.constraint(equalTo: centerYAnchor, constant: labelHeight/2).isActive = true
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
        if #available(iOS 13.0, *) {
            label.textColor = .label
        } else {
            label.textColor = .black
        }
        
        return label
    }()
    
    let distributionInformationLabel: UILabel = {   // Shows where the post will be posted: In a topic only or in the main Feed
       let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 14)
        label.textAlignment = .left
        label.text = "Feed"
        if #available(iOS 13.0, *) {
            label.textColor = .secondaryLabel
        } else {
            label.textColor = .lightGray
        }
        
        return label
    }()
    
    let distributionInformationImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "Feed")    //topicIcon
        if #available(iOS 13.0, *) {
            imageView.tintColor = .secondaryLabel
        } else {
            imageView.tintColor = .lightGray
        }
        
        return imageView
    }()
    
    let distributionInformationView: UIView = {
       let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        
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
        button.setImage(UIImage(named: "Dismiss"), for: .normal)
        button.addTarget(self, action: #selector(cancelLinkedFactTapped), for: .touchUpInside)
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
