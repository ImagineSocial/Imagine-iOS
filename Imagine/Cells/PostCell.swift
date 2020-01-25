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
    @IBOutlet weak var reportViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var reportViewLabel: UILabel!
    @IBOutlet weak var reportView: DesignablePopUp!
    @IBOutlet weak var reportViewButtonInTop: DesignableButton!
    
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
        contentView.layer.cornerRadius = 8
        cellImageView.layer.cornerRadius = 8
        backgroundColor = .clear
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        cellImageView.sd_cancelCurrentImageLoad()
        cellImageView.image = nil
        
        profilePictureImageView.sd_cancelCurrentImageLoad()
        profilePictureImageView.image = nil
        
        factImageView.layer.borderColor = UIColor.clear.cgColor
        factImageView.image = nil
        factImageView.backgroundColor = .clear
    }
    

    var post:Post? {
        didSet {
            setCell()
        }
    }
    
    func setCell() {
        if let post = post {
            
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
                thanksButton.setImage(UIImage(named: "thanksButton"), for: .normal)
                wowButton.setImage(UIImage(named: "wowButton"), for: .normal)
                haButton.setImage(UIImage(named: "haButton"), for: .normal)
                niceButton.setImage(UIImage(named: "niceButton"), for: .normal)
            }
            
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
                    self.getFact()
                } else {
                    if let url = URL(string: fact.imageURL) {
                        self.factImageView.sd_setImage(with: url, completed: nil)
                    } else {
                        if #available(iOS 13.0, *) {
                            self.factImageView.backgroundColor = .systemBackground
                        } else {
                            self.factImageView.backgroundColor = .white
                        }
                        self.factImageView.image = UIImage(named: "FactStamp")
                    }
                }
            }
            
            createDateLabel.text = post.createTime
            titleLabel.text = post.title
            commentCountLabel.text = String(post.commentCount)
            
            // LabelHeight calculated by the number of letters
            // Maybe call this when I fetch the Posts and put it into the object? ReportView also
            let labelHeight = handyHelper.setLabelHeight(titleCount: post.title.count)
            titleLabelHeightConstraint.constant = labelHeight
            
            
            if let url = URL(string: post.imageURL) {
                if let cellImageView = cellImageView {
                    cellImageView.sd_imageIndicator = SDWebImageActivityIndicator.grayLarge
                    cellImageView.sd_setImage(with: url, placeholderImage: nil, options: [], completed: nil)
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
    
    func getFact() {
        if let post = post {
            self.loadFact(post: post) {
                (fact) in
                post.fact = fact
                
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
