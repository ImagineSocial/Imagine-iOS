//
//  PostCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 29.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import SDWebImage

protocol PostCellDelegate {
    func userTapped(post: Post)
    func reportTapped(post: Post)
    func thanksTapped(post: Post)
    func wowTapped(post: Post)
    func haTapped(post: Post)
    func niceTapped(post: Post)
    func linkTapped(post: Post)
    func factTapped(fact: Fact)
    func collectionViewTapped(post: Post)
}

class PostCell : BaseFeedCell {
    
    @IBOutlet weak var cellImageView: UIImageView!
    //    @IBOutlet weak var titleLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var cellImageViewHeightConstraint: NSLayoutConstraint!
    
    var delegate: PostCellDelegate?
    
    override func awakeFromNib() {
        selectionStyle = .none
        
        self.initiateCell(thanksButton: thanksButton, wowButton: wowButton, haButton: haButton, niceButton: niceButton, factImageView: factImageView, profilePictureImageView: profilePictureImageView)
                
        titleLabel.adjustsFontSizeToFitWidth = true
        
        cellImageView.layer.cornerRadius = 1
        cellImageView.isUserInteractionEnabled = true
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(self.pinch(sender:)))
        self.cellImageView.addGestureRecognizer(pinch)
    
        self.addSubview(buttonLabel)
        
        // add corner radius on `contentView`
        cellImageView.layer.cornerRadius = 8
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        descriptionPreviewLabel.text = ""
        
        cellImageView.sd_cancelCurrentImageLoad()
        cellImageView.image = nil
        
        profilePictureImageView.sd_cancelCurrentImageLoad()
        profilePictureImageView.image = nil
        
        factImageView.layer.borderColor = UIColor.clear.cgColor
        factImageView.image = nil
        factImageView.backgroundColor = .clear
        
        followTopicImageView.isHidden = true
        
        thanksButton.isEnabled = true
        wowButton.isEnabled = true
        haButton.isEnabled = true
        niceButton.isEnabled = true
    }
    

    var post:Post? {
        didSet {
            setCell()
        }
    }
    
    func setCell() {
        if let post = post {
            
            if ownProfile { // Set in the UserFeedTableViewController DataSource
                thanksButton.setTitle(String(post.votes.thanks), for: .normal)
                wowButton.setTitle(String(post.votes.wow), for: .normal)
                haButton.setTitle(String(post.votes.ha), for: .normal)
                niceButton.setTitle(String(post.votes.nice), for: .normal)
                
                if let _ = cellStyle {
                    print("Already Set")
                } else {
                    cellStyle = .ownCell
                    setOwnCell()
                }
                
            } else {
                thanksButton.setImage(UIImage(named: "thanksButton"), for: .normal)
                wowButton.setImage(UIImage(named: "wowButton"), for: .normal)
                haButton.setImage(UIImage(named: "haButton"), for: .normal)
                niceButton.setImage(UIImage(named: "niceButton"), for: .normal)
            }
           /*
            let imageHeight = post.mediaHeight
            let imageWidth = post.mediaWidth
            
            let ratio = imageWidth / imageHeight
            let width = self.contentView.frame.width
            
            let newHeight = width / ratio
            
                    
            if newHeight <= 300 {
                let newWidth = 300*ratio
                pictureScrollView.contentSize = CGSize(width: newWidth, height: 300)
                print("Set ScrollViewContent Wide: \(newWidth), Height: \(newHeight), ratio: \(ratio), originalHeight: \(imageHeight), originalWidth: \(imageWidth), imageWidth: \(cellImageView.frame.width), scrollviewWidth: \(pictureScrollView.frame.width)")
            } else {
                print("Normal Picture")
            }
            */
            if post.user.displayName == "" {
                if post.anonym {
                    self.setUser()
                } else {
                    self.getName()
                }
            } else {
                setUser()
            }
            
            if let fact = post.fact {
                if #available(iOS 13.0, *) {
                    self.factImageView.layer.borderColor = UIColor.secondaryLabel.cgColor
                } else {
                    self.factImageView.layer.borderColor = UIColor.darkGray.cgColor
                }
                                
                if fact.title == "" {
                    self.getFact(beingFollowed: fact.beingFollowed)
                } else {
                    self.loadFact(post: post)
                }
            }
            
            createDateLabel.text = post.createTime
            titleLabel.text = post.title
            descriptionPreviewLabel.text = post.description
            commentCountLabel.text = String(post.commentCount)
            
            if let url = URL(string: post.imageURL) {
                if let cellImageView = cellImageView {
                    cellImageView.sd_imageIndicator = SDWebImageActivityIndicator.grayLarge
                    cellImageView.sd_setImage(with: url, placeholderImage: nil, options: [], completed: nil)
                }
            }
            
            setReportView(post: post, reportView: reportView, reportLabel: reportViewLabel, reportButton: reportViewButtonInTop, reportViewHeightConstraint: reportViewHeightConstraint)
        }
    }
    
    func setUser() {
        if let post = post {
            
            if post.anonym {
                if let anonymousName = post.anonymousName {
                    OPNameLabel.text = anonymousName
                } else {
                    OPNameLabel.text = Constants.strings.anonymPosterName
                }
                profilePictureImageView.image = UIImage(named: "anonym-user")
            } else {
                OPNameLabel.text = post.user.displayName
                
                // Profile Picture
                if let url = URL(string: post.user.imageURL) {
                    profilePictureImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default-user"), options: [], completed: nil)
                } else {
                    profilePictureImageView.image = UIImage(named: "default-user")
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
                    setUser()
                }
            }
        }
    }
    
    func getFact(beingFollowed: Bool) {
        if let post = post {
            if let fact = post.fact {
                self.loadFact(language: post.language, fact: fact, beingFollowed: beingFollowed) {
                    (fact) in
                    post.fact = fact
                    
                    self.loadFact(post: post)
                }
            }
        }
    }
    
    func loadFact(post: Post) {
        if post.isTopicPost {
            followTopicImageView.isHidden = false
        }
        
        if let url = URL(string: post.fact!.imageURL) {
            self.factImageView.sd_setImage(with: url, completed: nil)
        } else {
            print("Set default Picture")
            if #available(iOS 13.0, *) {
                self.factImageView.backgroundColor = .systemBackground
            } else {
                self.factImageView.backgroundColor = .white
            }
            self.factImageView.image = UIImage(named: "FactStamp")
        }
    }
    
    @objc func pinch(sender:UIPinchGestureRecognizer) {
        // From this nice tutorial: https://medium.com/@jeremysh/instagram-pinch-to-zoom-pan-gesture-tutorial-772681660dfe
        if sender.state == .changed {
            guard let view = sender.view else {return}
            let pinchCenter = CGPoint(x: sender.location(in: view).x - view.bounds.midX,
                                      y: sender.location(in: view).y - view.bounds.midY)
            let transform = view.transform.translatedBy(x: pinchCenter.x, y: pinchCenter.y)
                .scaledBy(x: sender.scale, y: sender.scale)
                .translatedBy(x: -pinchCenter.x, y: -pinchCenter.y)
            let currentScale = self.cellImageView.frame.size.width / self.cellImageView.bounds.size.width
            var newScale = currentScale*sender.scale
            if newScale < 1 {
                newScale = 1
                let transform = CGAffineTransform(scaleX: newScale, y: newScale)
                self.cellImageView.transform = transform
                sender.scale = 1
            }else {
                view.transform = transform
                sender.scale = 1
            }
        } else if sender.state == .ended {
            UIView.animate(withDuration: 0.3, animations: {
                self.cellImageView.transform = CGAffineTransform.identity
            })
        }
    }
    
    
    
    @IBAction func thanksButtonTapped(_ sender: Any) {
        if let post = post {
            thanksButton.isEnabled = false
            delegate?.thanksTapped(post: post)
            post.votes.thanks = post.votes.thanks+1
            showButtonText(post: post, button: thanksButton)
        }
    }
    @IBAction func wowButtonTapped(_ sender: Any) {
        if let post = post {
            wowButton.isEnabled = false
            delegate?.wowTapped(post: post)
            post.votes.wow = post.votes.wow+1
            showButtonText(post: post, button: wowButton)
        }
    }
    @IBAction func haButtonTapped(_ sender: Any) {
        if let post = post {
            haButton.isEnabled = false
            delegate?.haTapped(post: post)
            post.votes.ha = post.votes.ha+1
            showButtonText(post: post, button: haButton)
        }
    }
    @IBAction func niceButtonTapped(_ sender: Any) {
        if let post = post {
            niceButton.isEnabled = false
            delegate?.niceTapped(post: post)
            post.votes.nice = post.votes.nice+1
            self.showButtonText(post: post, button: self.niceButton)
        }
    }
    
    @IBAction func reportPressed(_ sender: Any) {
        if let post = post {
            delegate?.reportTapped(post: post)
        }
    }
    
    
    @IBAction func userButtonTapped(_ sender: Any) {
        if let post = post {
            if !post.anonym {
                delegate?.userTapped(post: post)
            }
        }
    }
    
    @IBAction func linkedFactTapped(_ sender: Any) {
        if let fact = post?.fact {
            delegate?.factTapped(fact: fact)
        }
    }
}
