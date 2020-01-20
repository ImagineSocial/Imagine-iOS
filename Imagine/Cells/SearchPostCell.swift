//
//  SearchPostCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 26.10.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class SearchPostCell: UITableViewCell {
    
    var post:Post? {
        didSet {
            if let post = post {
                titleLabel.text = post.title
                if post.user.displayName != "" {
                    nameLabel.text = "\(post.user.displayName)  -  \(post.createTime)"
                } else {
                    if post.anonym {
                        nameLabel.text = "Anonym  -  \(post.createTime)"
                    } else {
                        nameLabel.text = "        -  \(post.createTime)"
                        self.getName()
                    }
                }
                
                switch post.type {
                case .youTubeVideo:
                    print("YouTubeVideo")
                    postImageView.image = UIImage(named: "youtubeIcon")
                case .link:
                    if #available(iOS 13.0, *) {
                        postImageView.tintColor = .label
                    } else {
                        postImageView.tintColor = .black
                    }
                    postImageView.image = UIImage(named: "globe")
                    postImageView.contentMode = .scaleAspectFit
                case .thought:
                    postImageView.image = UIImage(named: "savePostImage")
                    postImageView.contentMode = .scaleAspectFit
                case .picture:
                    if let url = URL(string: post.imageURL) {
                        postImageView.sd_setImage(with: url, completed: nil)
                    } else {
                        postImageView.image = UIImage(named: "default")
                    }
                default:
                    postImageView.image = UIImage(named: "default")
                }
            }
        }
    }
    
    var index = 0
    func getName() {
        if index < 20 {
            if let post = self.post {
                if post.user.displayName == "" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.getName()
                        self.index+=1
                    }
                } else {
                    self.nameLabel.text = "\(post.user.displayName)  -  \(post.createTime)"
                }
            }
        }
    }
    
    override func prepareForReuse() {
        postImageView.image = nil
        postImageView.contentMode = .scaleAspectFill
    }
    
    private let titleLabel : UILabel = {
        let lbl = UILabel()
        
        if #available(iOS 13.0, *) {
            lbl.textColor = .label
        } else {
            lbl.textColor = .black
        }
        lbl.font = UIFont(name: "IBMPlexSans-Medium", size: 16)
        lbl.textAlignment = .left
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.numberOfLines = 0
        lbl.minimumScaleFactor = 0.7
        return lbl
    }()
    
    private let postImageView : UIImageView = {
        let imgView = UIImageView(image: UIImage(named: "default"))
        imgView.contentMode = .scaleAspectFill
        imgView.layer.cornerRadius = 5
        imgView.clipsToBounds = true
        imgView.translatesAutoresizingMaskIntoConstraints = false
        return imgView
    }()
    
    private let nameLabel: UILabel = {
       let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            label.textColor = .secondaryLabel
        } else {
            label.textColor = .lightGray
        }
        label.font = UIFont(name: "IBMPlexSans", size: 8)
        
        return label
    }()
    
    private let view: UIView = {
        let view = UIView()
        if #available(iOS 13.0, *) {
            view.backgroundColor = .secondarySystemBackground
        } else {
            view.backgroundColor = .lightGray
        }
        view.backgroundColor = .red
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        addSubview(titleLabel)
        addSubview(postImageView)
        addSubview(nameLabel)
        addSubview(view)
//        backgroundColor = .clear
        
//        addSubview(titleLabel)
//        addSubview(postImageView)
//
//        postImageView.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
//        postImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
//        let height = self.contentView.frame.height-10
//        postImageView.heightAnchor.constraint(equalToConstant: height).isActive = true
//        postImageView.widthAnchor.constraint(equalToConstant: height).isActive = true
//
//        titleLabel.leadingAnchor.constraint(equalTo: postImageView.trailingAnchor, constant: 10).isActive = true
//        titleLabel.topAnchor.constraint(equalTo: postImageView.topAnchor).isActive = true
//        titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
//        titleLabel.bottomAnchor.constraint(equalTo: postImageView.bottomAnchor).isActive = true
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        postImageView.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
        postImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
        let height = self.contentView.frame.height-10
        postImageView.heightAnchor.constraint(equalToConstant: height).isActive = true
        postImageView.widthAnchor.constraint(equalToConstant: height).isActive = true
        
        nameLabel.leadingAnchor.constraint(equalTo: postImageView.trailingAnchor, constant: 10).isActive = true
        nameLabel.topAnchor.constraint(equalTo: postImageView.topAnchor).isActive = true
        nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
        nameLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        titleLabel.leadingAnchor.constraint(equalTo: postImageView.trailingAnchor, constant: 10).isActive = true
        titleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: postImageView.bottomAnchor).isActive = true
        
        view.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        view.heightAnchor.constraint(equalToConstant: 5).isActive = true
        view.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
