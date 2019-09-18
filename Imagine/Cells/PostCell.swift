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
}

class PostCell : BaseFeedCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var cellImageView: UIImageView!
    @IBOutlet weak var reportViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var reportViewLabel: UILabel!
    @IBOutlet weak var reportView: DesignablePopUp!
    @IBOutlet weak var reportViewButtonInTop: DesignableButton!
    @IBOutlet weak var cellCreateDateLabel: UILabel!
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var ogPosterLabel: UILabel!
    @IBOutlet weak var commentCountLabel: UILabel!
    
    var delegate: PostCellDelegate?
    
    
    override func awakeFromNib() {
        let layer = profilePictureImageView.layer
        layer.cornerRadius = profilePictureImageView.frame.width/2
        
        thanksButton.setImage(nil, for: .normal)
        wowButton.setImage(nil, for: .normal)
        haButton.setImage(nil, for: .normal)
        niceButton.setImage(nil, for: .normal)
                
        titleLabel.adjustsFontSizeToFitWidth = true
        
        cellImageView.layer.cornerRadius = 1
        cellImageView.isUserInteractionEnabled = true
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(self.pinch(sender:)))
        self.cellImageView.addGestureRecognizer(pinch)
        
        thanksButton.layer.borderWidth = 1.5
        thanksButton.layer.borderColor = thanksColor.cgColor
        wowButton.layer.borderWidth = 1.5
        wowButton.layer.borderColor = wowColor.cgColor
        haButton.layer.borderWidth = 1.5
        haButton.layer.borderColor = haColor.cgColor
        niceButton.layer.borderWidth = 1.5
        niceButton.layer.borderColor = niceColor.cgColor
        self.addSubview(buttonLabel)
        
//        // add shadow on cell
//        backgroundColor = .clear // very important
//
//        let lay = self.layer
//        lay.masksToBounds = false
//        lay.shadowOpacity = 0.2
//        lay.shadowRadius = 2
//        lay.shadowOffset = CGSize(width: 0, height: 0)
//        lay.shadowColor = UIColor.black.cgColor
        
        // add corner radius on `contentView`
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 8
        backgroundColor =  Constants.backgroundColorForTableViews
        
        
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
    
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        cellImageView.sd_cancelCurrentImageLoad()
        cellImageView.image = nil
        
        profilePictureImageView.sd_cancelCurrentImageLoad()
        profilePictureImageView.image = nil
        
    }
    
//    var user:User? {
//        didSet {
//            if let user = user {
//                ogPosterLabel.text = "\(user.name) \(user.surname)"
//
//                // Profile Picture
//                if let url = URL(string: user.imageURL) {
//                    profilePictureImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default-user"), options: [], completed: nil)
//                }
//            }
//        }
//    }
    
    var post:Post? {
        didSet {
            
            
            // Erneut nach post.user gucken und wenn er geladen ist, ist stop und das Profil wird geladen
            setCell()
            
        }
    }
    
    func setCell() {
        if let post = post {
            print("Set 'Image' Post")
            
            if ownProfile {
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
                thanksButton.setImage(UIImage(named: "thanks"), for: .normal)
                wowButton.setImage(UIImage(named: "wow"), for: .normal)
                haButton.setImage(UIImage(named: "ha"), for: .normal)
                niceButton.setImage(UIImage(named: "nice"), for: .normal)
            }
            
            if post.user.name == "" {
                self.getName()
            }
            
            ogPosterLabel.text = "\(post.user.name) \(post.user.surname)"
            cellCreateDateLabel.text = post.createTime
            
            titleLabel.text = post.title
            commentCountLabel.text = String(post.commentCount)
            
            
            // Profile Picture
            
            if let url = URL(string: post.user.imageURL) {
                profilePictureImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default-user"), options: [], completed: nil)
            }
            
            // LabelHeight calculated by the number of letters
            
            // Maybe call this when I fetch the Posts and put it into the object? ReportView also
            let labelHeight = handyHelper.setLabelHeight(titleCount: post.title.count)
            titleLabelHeightConstraint.constant = labelHeight
            
            
            
            if let url = URL(string: post.imageURL) {
                if let cellImageView = cellImageView {
                    cellImageView.sd_imageIndicator = SDWebImageActivityIndicator.whiteLarge
                    cellImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default"), options: [], completed: nil)
                }
            }
            
            // Set ReportView
            let reportViewOptions = handyHelper.setReportView(post: post)
            
            reportViewHeightConstraint.constant = reportViewOptions.heightConstant
            reportViewButtonInTop.isHidden = reportViewOptions.buttonHidden
            reportViewLabel.text = reportViewOptions.labelText
            reportView.backgroundColor = reportViewOptions.backgroundColor
        }
    }
    
    
    var index = 0
    func getName() {
        if index < 20 {
            if let post = self.post {
                if post.user.name == "" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.getName()
                        self.index+=1
                    }
                } else {
                    setCell()
                }
            }
        }
    }
    
    
    
    @IBAction func thanksButtonTapped(_ sender: Any) {
        if let post = post {
            delegate?.thanksTapped(post: post)
            post.votes.thanks = post.votes.thanks+1
            showButtonText(post: post, button: thanksButton)
            
        }
    }
    @IBAction func wowButtonTapped(_ sender: Any) {
        if let post = post {
            delegate?.wowTapped(post: post)
            post.votes.wow = post.votes.wow+1
            showButtonText(post: post, button: wowButton)
        }
    }
    @IBAction func haButtonTapped(_ sender: Any) {
        if let post = post {
            delegate?.haTapped(post: post)
            post.votes.ha = post.votes.ha+1
            showButtonText(post: post, button: haButton)
        }
    }
    @IBAction func niceButtonTapped(_ sender: Any) {
        if let post = post {
            delegate?.niceTapped(post: post)
            post.votes.nice = post.votes.nice+1
            showButtonText(post: post, button: niceButton)
        }
    }
    
    @IBAction func reportPressed(_ sender: Any) {
        if let post = post {
            delegate?.reportTapped(post: post)
        }
    }
    
    
    @IBAction func userButtonTapped(_ sender: Any) {
        if let post = post {
            delegate?.userTapped(post: post)
        }
    }
    
}
