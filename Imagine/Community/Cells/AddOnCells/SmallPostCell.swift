//
//  DIYCollectionViewCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 06.03.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import AVFoundation
import SwiftLinkPreview

protocol SmallPostCellDelegate {
    func sendItem(item: Any)
}

class SmallPostCell: UICollectionViewCell {
    
    @IBOutlet weak var cellImageView: UIImageView!
    @IBOutlet weak var smallCellImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var postTitleLabel: UILabel!
    @IBOutlet weak var postImageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerView: DesignablePopUp!
    
    @IBOutlet weak var optionalTitleGradientViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var showOptionalTitleButton: DesignableButton!
    @IBOutlet weak var optionalTitleGradientView: UIView!
    
    var delegate: SmallPostCellDelegate?
    
    let postHelper = FirestoreRequest.shared
    
    var gradient: CAGradientLayer?
    
    // MARK: - Cell Lifecycle
    
    override func awakeFromNib() {
        
        cellImageView.layer.cornerRadius = 4
        backgroundColor = .clear
    }
    
    override func prepareForReuse() {
        smallCellImageView.isHidden = false
        
        postImageViewHeightConstraint.constant = 170
        optionalTitleGradientViewHeightConstraint.constant = 0
        
        postTitle = nil
        cellImageView.image = nil
        
        showOptionalTitleButton.setImage(UIImage(named: "up"), for: .normal)
        
        self.linkView.removeFromSuperview()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
                
        contentView.clipsToBounds = false
        clipsToBounds = false
        
        let layer = containerView.layer
        layer.createStandardShadow(with: CGSize(width: contentView.frame.width - 10, height: contentView.frame.height - 10), cornerRadius: 5, small: true)
    }
    
    
    // MARK: - Show Content
    
    var postTitle: String? {
        didSet {
            if let postTitle = postTitle {
                if postTitle == "gotcha" {
                    //                postImageViewHeightConstraint.constant = 170
                    //                titleHeightConstraint.constant = 0
                    optionalTitleGradientViewHeightConstraint.constant = 0
                } else {
                    titleLabel.text = postTitle
                    showOptionalTitleButton.isHidden = false
                    optionalTitleGradientViewHeightConstraint.constant = 0
                }
            } else {
                showOptionalTitleButton.isHidden = true
                optionalTitleGradientViewHeightConstraint.constant = 0
            }
        }
    }
    
    func loadPost(post: Post) {
        DispatchQueue.global(qos: .default).async {
            
            //needs documentID, isTopicPost and language
            FirestoreManager.getSinglePostFromID(post: post) { post in
                guard let post = post else {
                    return
                }
                
                DispatchQueue.main.async {
                    self.post = post
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
            
            switch post.type {
            case .picture:
                smallCellImageView.isHidden = true
                
                if let thumbnailURL = post.image?.thumbnailUrl, let url = URL(string: thumbnailURL) {
                    cellImageView.sd_setImage(with: url, completed: nil)
                } else if let imageURL = post.image?.url, let url = URL(string: imageURL) {
                    cellImageView.sd_setImage(with: url, completed: nil)
                } else {
                    cellImageView.image = Constants.defaultImage
                }
            case .multiPicture:
                smallCellImageView.isHidden = true
                
                if let image = post.images?.first {
                    if let url = URL(string: image.url) {
                        cellImageView.sd_setImage(with: url, completed: nil)
                    } else {
                        cellImageView.image = UIImage(named: "default")
                    }
                }
            case .GIF:
                smallCellImageView.image = UIImage(named: "GIFIcon")
                smallCellImageView.contentMode = .center
                
                if let linkURL = post.link?.url, let url = URL(string: linkURL) {
                    DispatchQueue.global(qos: .default).async {  // Quite some work to do apparently
                        let image = self.generateThumbnail(url: url)
                        DispatchQueue.main.async {
                            if let image = image {
                                self.cellImageView.image = image
                            } else { // Not in this cell
                                self.postImageViewHeightConstraint.constant = 0
                            }
                        }
                    }
                }
            case .link:
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
                
                // Show Preview of Link
                if let link = post.link {
                    if let imageURL = link.imageURL {
                        if imageURL.isValidURL {
                            self.cellImageView.sd_setImage(with: URL(string: imageURL), placeholderImage: UIImage(named: "link-default"), options: [], completed: nil)
                        } else {
                            self.cellImageView.image = UIImage(named: "link-default")
                        }
                    }
                    
                    self.linkLabel.text = link.shortURL
                    
                } else {
                    print("#Error: got no link in link cell")
                }
            case .youTubeVideo:
                postImageViewHeightConstraint.constant = cellImageView.frame.width*(9/16)   // Frame is 16/9 Format
                
                if let linkURL = post.link?.url, let youtubeID = linkURL.youtubeID {
                    let thumbnailURL = "https://img.youtube.com/vi/\(youtubeID)/sddefault.jpg"
                    
                    if let url = URL(string: thumbnailURL) {
                        cellImageView.sd_setImage(with: url, completed: nil)
                    } else {
                        cellImageView.image = UIImage(named: "link-default")
                    }
                }
                
                smallCellImageView.image = UIImage(named: "youtubeIcon")
            default:
                // THought
                postImageViewHeightConstraint.constant = 0
                smallCellImageView.isHidden = true
            }
            
            postTitleLabel.text = post.title
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
    
    func setGradientView() {
        //Gradient
        
        if let gradient = self.gradient {
            optionalTitleGradientView.layer.mask = gradient
        } else {
            self.gradient = CAGradientLayer()
            gradient!.startPoint = CGPoint(x: 0.5, y: 0.0)
            gradient!.endPoint = CGPoint(x: 0.5, y: 0.6)
            let whiteColor = UIColor.white
            gradient!.colors = [whiteColor.withAlphaComponent(0.3).cgColor, whiteColor.withAlphaComponent(0.6).cgColor, whiteColor.withAlphaComponent(0.8).cgColor]
            gradient!.locations = [0.0, 0.7, 1]
            gradient!.frame = optionalTitleGradientView.bounds
            
            optionalTitleGradientView.layer.mask = gradient
            optionalTitleGradientView.layer.cornerRadius = 4
        }
    }
    
    @IBAction func showOptionalTitleButtonTapped(_ sender: Any) {
        
        if optionalTitleGradientViewHeightConstraint.constant == 0 {
            self.optionalTitleGradientViewHeightConstraint.constant = 50
            
            UIView.animate(withDuration: 0.3, animations: {
                self.smallCellImageView.alpha = 0
                self.layoutIfNeeded()
                self.setGradientView()
            }) { (_) in
                self.showOptionalTitleButton.setImage(UIImage(named: "down"), for: .normal)
                self.optionalTitleGradientView.layoutIfNeeded()
                self.titleLabel.layoutIfNeeded()
                
            }
        } else {
            self.optionalTitleGradientViewHeightConstraint.constant = 0
            
            UIView.animate(withDuration: 0.3, animations: {
                self.smallCellImageView.alpha = 0.75
                self.layoutIfNeeded()
            }) { (_) in
                self.showOptionalTitleButton.setImage(UIImage(named: "up"), for: .normal)
                self.optionalTitleGradientView.layoutIfNeeded()
                self.titleLabel.layoutIfNeeded()
            }
        }
    }
    
    //MARK:-UI
    
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
    
}
