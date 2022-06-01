//
//  RepostView.swift
//  Imagine
//
//  Created by Malte Schoppe on 26.02.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

/// The Repost view inside the PostViewController
class RepostView: UIView {
    
    //MARK: - Variables
    var repost: Post? {
        didSet {
            if let repost = repost {
                repostTitleLabel.text = repost.title
                repostCreateDateLabel.text = repost.createTime
                
                if let imageURL = URL(string: repost.imageURL) {
                    repostImageView.sd_setImage(with: imageURL, completed: nil)
                }
                
                if let repostUser = repost.user {
                    repostNameLabel.text = repostUser.displayName
                    
                    if let urlString = repostUser.imageURL, let url = URL(string: urlString) {
                        repostProfilePictureImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default-user"), options: [], completed: nil)
                    }
                }
            }
        }
    }
    
    ///Set the postViewController to call the dedicated functions
    var postViewController: PostViewController?
    
    //MARK:- Initialization
    init(viewController: PostViewController) {
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        
        self.postViewController = viewController
        
        setUpLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Set Up the View
    
    private func setUpLayout() {
        layoutIfNeeded()
        translatesAutoresizingMaskIntoConstraints = false
        
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 5
        layer.borderColor = UIColor.black.cgColor
        layer.borderWidth = 1
        clipsToBounds = true
        
        addSubview(repostProfilePictureImageView)
        repostProfilePictureImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
        repostProfilePictureImageView.topAnchor.constraint(equalTo: topAnchor, constant: 10).isActive = true
        repostProfilePictureImageView.widthAnchor.constraint(equalToConstant: 36).isActive = true
        repostProfilePictureImageView.heightAnchor.constraint(equalToConstant: 36).isActive = true
        repostProfilePictureImageView.layoutIfNeeded() // Damit er auch rund wird
        
        addSubview(repostNameLabel)
        repostNameLabel.leadingAnchor.constraint(equalTo: repostProfilePictureImageView.trailingAnchor, constant: 10).isActive = true
        repostNameLabel.topAnchor.constraint(equalTo: repostProfilePictureImageView.topAnchor).isActive = true
        
        addSubview(repostCreateDateLabel)
        repostCreateDateLabel.leadingAnchor.constraint(equalTo: repostNameLabel.leadingAnchor).isActive = true
        repostCreateDateLabel.topAnchor.constraint(equalTo: repostNameLabel.bottomAnchor, constant: 3).isActive = true
        
        addSubview(repostTitleLabel)
        repostTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
        repostTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
        repostTitleLabel.topAnchor.constraint(equalTo: repostProfilePictureImageView.bottomAnchor, constant: 10).isActive = true
        
        addSubview(repostImageView)
        repostImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
        repostImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
        repostImageView.topAnchor.constraint(equalTo: repostTitleLabel.bottomAnchor, constant: 10).isActive = true
        repostImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10).isActive = true
        
        addSubview(repostViewButton)
        repostViewButton.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        repostViewButton.topAnchor.constraint(equalTo: topAnchor).isActive = true
        repostViewButton.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        repostViewButton.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        
        addSubview(repostUserButton)
        repostUserButton.leadingAnchor.constraint(equalTo: repostProfilePictureImageView.leadingAnchor).isActive = true
        repostUserButton.topAnchor.constraint(equalTo: repostProfilePictureImageView.topAnchor).isActive = true
        repostUserButton.bottomAnchor.constraint(equalTo: repostProfilePictureImageView.bottomAnchor).isActive = true
        repostUserButton.trailingAnchor.constraint(equalTo: repostNameLabel.trailingAnchor).isActive = true
    }
    
    //MARK:- Report View Button Responses
    @objc func repostImageTapped() {
        if let postVC = postViewController {
            postVC.postImageTapped()
        }
    }
    
    @objc func repostViewTapped() {
        if let postVC = postViewController {
            postVC.repostViewTapped()
        }
    }
    
    @objc func repostUserTapped() {
        if let postVC = postViewController {
            postVC.repostUserTapped()
        }
    }
    
    
    // MARK: - Initialize Repost UI
    
    let repostProfilePictureImageView : UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "default-user")
        imageView.isUserInteractionEnabled = true
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        
        return imageView
    }()
    
    let repostUserButton : DesignableButton = {
        let button = DesignableButton()
        button.addTarget(self, action: #selector(repostUserTapped), for: .touchUpInside)
        
        return button
    }()
    
    let repostViewButton : DesignableButton = {
        let button = DesignableButton()
        button.addTarget(self, action: #selector(repostViewTapped), for: .touchUpInside)
    
        return button
    }()
    
    let repostNameLabel : UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "IBMPlexSans", size: 16)
        
        return label
    }()
    
    let repostCreateDateLabel : UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "IBMPlexSans", size: 10)
        
        return label
    }()
    
    let repostTitleLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 16)
        label.numberOfLines = 0
        label.minimumScaleFactor = 0.7
        
        return label
    }()
    
    let repostImageView : UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        imageView.image = UIImage(named: "default")
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(repostImageTapped)))
        
        let layer = imageView.layer
        layer.cornerRadius = 4
        layer.masksToBounds = true
        
        return imageView
    }()
}
