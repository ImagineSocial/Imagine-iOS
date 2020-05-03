//
//  DIYCollectionViewCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 06.03.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase
import AVFoundation
import SwiftLinkPreview

class SmallPostCell: UICollectionViewCell {
    
    @IBOutlet weak var cellImageView: UIImageView!
    @IBOutlet weak var smallCellImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var postTitleLabel: UILabel!
    @IBOutlet weak var postImageViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var titleHeightConstraint: NSLayoutConstraint!
    
    
    let db = Firestore.firestore()
    let postHelper = PostHelper()
    
    let slp = SwiftLinkPreview(session: URLSession.shared, workQueue: SwiftLinkPreview.defaultWorkQueue, responseQueue: DispatchQueue.main, cache: DisabledCache.instance)
    
    var postTitle: String? {
        didSet {
            if postTitle! == "gotcha" {
                postImageViewHeightConstraint.constant = 170
                titleHeightConstraint.constant = 0
            } else {
                titleLabel.text = postTitle!
            }
        }
    }
    
    func loadPost(postID: String, isTopicPost: Bool) {
        let ref: DocumentReference?
        
        if postID == "" {   // NewAddOnTableVC
            return
        }
        
        if isTopicPost {
            ref = db.collection("TopicPosts").document(postID)
        } else {
            ref = db.collection("Posts").document(postID)
        }
        
        if let ref = ref {
            ref.getDocument { (snap, err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    if let snap = snap {
                        if let post = self.postHelper.addThePost(document: snap, isTopicPost: isTopicPost, forFeed: false){
                            
                            if isTopicPost {
                                post.isTopicPost = true
                            }
                            self.post = post
                        }
                    }
                }
            }
        }
    }
    
    var post: Post? {
        didSet {
            guard let post = post else { return }
            
            if let _ = postTitle {
                // andere Höhe
            } else {
                if post.title.count < 50 {
                    postImageViewHeightConstraint.constant = 200
                }
            }
            
            if post.type == .picture {
                smallCellImageView.isHidden = true
                
                if let url = URL(string: post.imageURL) {
                    cellImageView.sd_setImage(with: url, completed: nil)
                } else {
                    cellImageView.image = UIImage(named: "default")
                }
            } else if post.type == .multiPicture {
                smallCellImageView.isHidden = true
                
                if let images = post.imageURLs {
                    if let url = URL(string: images[0]) {
                        cellImageView.sd_setImage(with: url, completed: nil)
                    } else {
                        cellImageView.image = UIImage(named: "default")
                    }
                }
            } else if post.type == .GIF {
                smallCellImageView.image = UIImage(named: "GIFIcon")
                
                if let url = URL(string: post.linkURL) {
                    DispatchQueue.global().async {  // Quite some work to do apparently
                        let image = self.generateThumbnail(url: url)
                        DispatchQueue.main.sync {
                            if let image = image {    // Not on this thread
                                self.cellImageView.image = image
                            } else {
                                self.postImageViewHeightConstraint.constant = 0
                            }
                        }
                    }
                }
            } else if post.type == .link {
                smallCellImageView.image = UIImage(named: "translate")
                cellImageView.image = UIImage(named: "link-default")
                
                self.linkView.addSubview(linkLabel)
                linkLabel.leadingAnchor.constraint(equalTo: linkView.leadingAnchor, constant: 2).isActive = true
                linkLabel.trailingAnchor.constraint(equalTo: linkView.trailingAnchor, constant: -2).isActive = true
                linkLabel.centerXAnchor.constraint(equalTo: linkView.centerXAnchor).isActive = true
                
                self.cellImageView.addSubview(linkView)
                linkView.leadingAnchor.constraint(equalTo: cellImageView.leadingAnchor).isActive = true
                linkView.trailingAnchor.constraint(equalTo: cellImageView.trailingAnchor).isActive = true
                linkView.bottomAnchor.constraint(equalTo: cellImageView.bottomAnchor).isActive = true
                linkView.heightAnchor.constraint(equalToConstant: 20).isActive = true
                
                
                slp.preview(post.linkURL, onSuccess: { (response) in
                    if let imageURL = response.image {
                        if imageURL.isValidURL {
                            self.cellImageView.sd_setImage(with: URL(string: imageURL), placeholderImage: UIImage(named: "link-default"), options: [], completed: nil)
                        } else {
                            //Try
                            self.cellImageView.image = UIImage(named: "link-default")
                        }
                        
                    }
                    if let urlString = response.canonicalUrl {
                        self.linkLabel.text = urlString
                    }
                    
                }) { (error) in
                    print("We have an error showing the link: \(error.localizedDescription)")
                }
            } else if post.type == .youTubeVideo {
                
                postImageViewHeightConstraint.constant = cellImageView.frame.width*(9/16)   // Frame is 16/9 Format
                
                if let youtubeID = post.linkURL.youtubeID {
                    let thumbnailURL = "https://img.youtube.com/vi/\(youtubeID)/sddefault.jpg"
                    
                    if let url = URL(string: thumbnailURL) {
                        cellImageView.sd_setImage(with: url, completed: nil)
                    } else {
                        cellImageView.image = UIImage(named: "link-default")
                    }
                }
                
                smallCellImageView.image = UIImage(named: "youtubeIcon")
            } else {
                // THought
                postImageViewHeightConstraint.constant = 0
            }
            
            postTitleLabel.text = post.title
//            descriptionLabel.text = post.description
        }
    }
    
    func generateThumbnail(url: URL) -> UIImage? {
        do {
            let asset = AVURLAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            // Select the right one based on which version you are using
            // Swift 4.2
            let cgImage = try imageGenerator.copyCGImage(at: .zero,
                                                         actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            print(error.localizedDescription)

            return nil
        }
    }
    
    let linkView: UIView = {
       let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.ios12secondarySystemBackground.withAlphaComponent(0.7)
        
        return view
    }()
    
    let linkLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans", size: 12)
        label.textColor = .darkGray
        
        return label
    }()
    
    override func awakeFromNib() {
        if #available(iOS 13.0, *) {
            contentView.backgroundColor = .secondarySystemBackground
        } else {
            contentView.backgroundColor = .ios12secondarySystemBackground
        }
        
        contentView.layer.cornerRadius = 6
        cellImageView.layer.cornerRadius = 4
        backgroundColor = .clear
    }
    
    override func prepareForReuse() {
        smallCellImageView.isHidden = false
        
        postImageViewHeightConstraint.constant = 120
        titleHeightConstraint.constant = 50
        
        self.linkView.removeFromSuperview()
    }
    
}
