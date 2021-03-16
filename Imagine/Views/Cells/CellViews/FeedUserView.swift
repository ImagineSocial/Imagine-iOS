//
//  FeedUserView.swift
//  Imagine
//
//  Created by Malte Schoppe on 15.03.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

public protocol NibLoadable {
    static var nibName: String { get }
}

public extension NibLoadable where Self: UIView {

    static var nibName: String {
        return String(describing: Self.self) // defaults to the name of the class implementing this protocol.
    }

    static var nib: UINib {
        let bundle = Bundle(for: Self.self)
        return UINib(nibName: Self.nibName, bundle: bundle)
    }

    func setupFromNib() {
        guard let view = Self.nib.instantiate(withOwner: self, options: nil).first as? UIView else { fatalError("Error loading \(self) from nib") }
        addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 0).isActive = true
        view.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true
        view.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: 0).isActive = true
        view.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: 0).isActive = true
    }
}

@IBDesignable
class FeedUserView: UIView, NibLoadable {
    
    //MARK:- IBOutlets
    @IBOutlet weak var createDateLabel: UILabel!
    @IBOutlet weak var userButton: UIButton!
    @IBOutlet weak var linkedCommunityImageView: UIImageView!
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var communityPostImageView: DesignableImage!
    @IBOutlet weak var linkedCommunityButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var menuButton: DesignableButton!
    
    //MARK:- Initialization
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupFromNib()
        
        setUpUI()
    }
    
    //MARK:- SetUp UI
    func setUpUI() {
        // Profile Picture
        let layer = profilePictureImageView.layer
        layer.cornerRadius = profilePictureImageView.frame.width/2
        
        linkedCommunityImageView.layer.cornerRadius = 3
        linkedCommunityImageView.layer.borderWidth = 1
        linkedCommunityImageView.layer.borderColor = UIColor.clear.cgColor
    }
    
    //MARK:- User
    func setUser(post: Post) {
        
        createDateLabel.text = post.createTime
        if post.anonym {
            if let anonymousName = post.anonymousName {
                nameLabel.text = anonymousName
            } else {
                nameLabel.text = Constants.strings.anonymPosterName
            }
            profilePictureImageView.image = UIImage(named: "anonym-user")
        } else {
            nameLabel.text = post.user.displayName
            
            // Profile Picture
            if let url = URL(string: post.user.imageURL) {
                profilePictureImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default-user"), options: [], completed: nil)
            } else {
                profilePictureImageView.image = UIImage(named: "default-user")
            }
        }
    }
    
    //MARK:- LinkedCommunity
    func setCommunity(post: Post) {
        
        if #available(iOS 13.0, *) {
            self.linkedCommunityImageView.layer.borderColor = UIColor.secondaryLabel.cgColor
        } else {
            self.linkedCommunityImageView.layer.borderColor = UIColor.darkGray.cgColor
        }
        
        if post.isTopicPost {
            communityPostImageView.isHidden = false
        }
        
        if let url = URL(string: post.fact!.imageURL) {
            self.linkedCommunityImageView.sd_setImage(with: url, completed: nil)
        } else {
            print("Set default Picture")
            if #available(iOS 13.0, *) {
                self.linkedCommunityImageView.backgroundColor = .systemBackground
            } else {
                self.linkedCommunityImageView.backgroundColor = .white
            }
            self.linkedCommunityImageView.image = UIImage(named: "FactStamp")
        }
    }
    
    
    //MARK:- Reuse
    func prepareForReuse() {
        profilePictureImageView.sd_cancelCurrentImageLoad()
        profilePictureImageView.image = nil
        
        linkedCommunityImageView.layer.borderColor = UIColor.clear.cgColor
        linkedCommunityImageView.image = nil
        linkedCommunityImageView.backgroundColor = .clear
        communityPostImageView.isHidden = true
    }
    
    //MARK:- IBActions
//    
//    @IBAction func reportPressed(_ sender: Any) {
//        if let post = post {
//            delegate?.reportTapped(post: post)
//        }
//    }
//    
//    
//    @IBAction func userButtonTapped(_ sender: Any) {
//        if let post = post {
//            if !post.anonym {
//                delegate?.userTapped(post: post)
//            }
//        }
//    }
//    
//    @IBAction func linkedFactTapped(_ sender: Any) {
//        if let fact = post?.fact {
//            delegate?.factTapped(fact: fact)
//        }
//    }
}
