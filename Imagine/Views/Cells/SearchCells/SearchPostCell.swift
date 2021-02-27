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
                    postImageView.image = UIImage(named: "youtubeIcon")
                case .link:
                    postImageView.contentMode = .scaleAspectFit
                    
                    if let music = post.music {
                        if let url = URL(string: music.musicImageURL) {
                            postImageView.sd_setImage(with: url, completed: nil)
                        }
                    } else {
                        if #available(iOS 13.0, *) {
                            postImageView.tintColor = .label
                        } else {
                            postImageView.tintColor = .black
                        }
                        postImageView.image = UIImage(named: "translate")
                    }
                case .thought:
                    postImageView.image = UIImage(named: "savePostImage")
                    postImageView.contentMode = .scaleAspectFit
                case .picture:
                    if let url = URL(string: post.imageURL) {
                        postImageView.sd_setImage(with: url, completed: nil)
                    } else {
                        postImageView.image = UIImage(named: "default")
                    }
                case .multiPicture:
                    if let imageURLs = post.imageURLs {
                        if let url = URL(string: imageURLs[0]) {
                            postImageView.sd_setImage(with: url, completed: nil)
                        } else {
                            postImageView.image = UIImage(named: "default")
                        }
                    }
                case .GIF:
                    postImageView.image = UIImage(named: "GIFIcon")                    
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
        postImageView.isHidden = false
    }
    
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        addSubview(titleLabel)
        addSubview(postImageView)
        addSubview(nameLabel)
    
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let post = post {
            if post.type == .thought {
                nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
                nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
                nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
                nameLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
                
                titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
                titleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor).isActive = true
                titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
                titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5).isActive = true
                
                postImageView.isHidden = true
            } else {
                setStandardLayout()
            }
        } else {
            setStandardLayout()
        }
    }
    
    func setStandardLayout() {
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
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
