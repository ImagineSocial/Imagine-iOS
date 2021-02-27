//
//  LinkCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 21.04.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import SwiftLinkPreview
import Firebase

extension String {
    var isValidURL: Bool {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        if let match = detector.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) {
            // it is a link, if the match covers the whole string
            return match.range.length == self.utf16.count
        } else {
            return false
        }
    }
}

class LinkCell : BaseFeedCell {
    
    @IBOutlet weak var linkThumbNailImageView: UIImageView!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var linkPreviewTitleLabel: UILabel!
    @IBOutlet weak var linkPreviewDescriptionLabel: UILabel!
    
    let slp = SwiftLinkPreview(session: URLSession.shared, workQueue: SwiftLinkPreview.defaultWorkQueue, responseQueue: DispatchQueue.main, cache: InMemoryCache())
    
    var preview: Cancellable?
    
    var delegate: PostCellDelegate?
    
    override func awakeFromNib() {
        selectionStyle = .none
        
        self.addSubview(buttonLabel)
        buttonLabel.textColor = .black
        
        self.initiateCell(thanksButton: thanksButton, wowButton: wowButton, haButton: haButton, niceButton: niceButton, factImageView: factImageView, profilePictureImageView: profilePictureImageView)
                
//        linkThumbNailImageView.layer.cornerRadius = 4

        
        titleLabel.layoutIfNeeded()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        descriptionPreviewLabel.text = ""
        
        self.linkThumbNailImageView.image = UIImage(named: "link-default")
        
        urlLabel.text = nil
        linkPreviewDescriptionLabel.text = nil
        linkPreviewTitleLabel.text = nil
        
        linkThumbNailImageView.sd_cancelCurrentImageLoad()
        linkThumbNailImageView.image = nil
        
        profilePictureImageView.sd_cancelCurrentImageLoad()
        profilePictureImageView.image = nil
        
        factImageView.layer.borderColor = UIColor.clear.cgColor
        factImageView.image = nil
        factImageView.backgroundColor = .clear
        followTopicImageView.isHidden = true
        
        if let preview = preview {
            preview.cancel()
        }
        
        thanksButton.isEnabled = true
        wowButton.isEnabled = true
        haButton.isEnabled = true
        niceButton.isEnabled = true
    }
    
    var post :Post? {
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
            
            descriptionPreviewLabel.text = post.description
            commentCountLabel.text = String(post.commentCount)
            
            // Profile Picture
            if let url = URL(string: post.user.imageURL) {
                profilePictureImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default-user"), options: [], completed: nil)
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
                self.factImageView.layer.borderColor = UIColor.lightText.cgColor
                                
                if fact.title == "" {
                    if fact.beingFollowed {
                        self.getFact(beingFollowed: true)
                    } else {
                        self.getFact(beingFollowed: false)
                    }
                } else {
                    self.loadFact()
                }
            }
            
            createDateLabel.text = post.createTime
            titleLabel.text = post.title
            
            // Show Preview of Link
            if let link = post.link {
                linkPreviewTitleLabel.text = link.linkTitle
                linkPreviewDescriptionLabel.text = link.linkDescription
                urlLabel.text = link.shortURL
                
                if let imageURL = link.imageURL {
                    if imageURL.isValidURL {
                        self.linkThumbNailImageView.sd_setImage(with: URL(string: imageURL), placeholderImage: UIImage(named: "link-default"), options: [], completed: nil)
                    }
                }
            } else {
                slp.preview(post.linkURL) { (response) in
                    self.showLinkPreview(result: response)
                } onError: { (err) in
                    print("We have an error: \(err.localizedDescription)")
                }

                print("#Error: got no link in link cell")
            }
            
            
            setReportView(post: post, reportView: reportView, reportLabel: reportViewLabel, reportButton: reportViewButtonInTop, reportViewHeightConstraint: reportViewHeightConstraint)
        }
    }
    
    func showLinkPreview(result: Response) {
        //https://github.com/LeonardoCardoso/SwiftLinkPreview
        
        var previewImageURL: String?
        var shortURL = ""
        var title = ""
        var description = ""
        
        if let imageURL = result.image {
            if imageURL.isValidURL {
                previewImageURL = imageURL
                self.linkThumbNailImageView.sd_setImage(with: URL(string: imageURL), placeholderImage: UIImage(named: "link-default"), options: [], completed: nil)
//                { (image, _, _, _) in
//                    if let image = image {
//                        if let size = image.jpegData(compressionQuality: 100) {
//                            print("##Das ist die size: \(size.count)")
//                        }
//                    }
//                }
            } 
        }
        
        if let linkPreviewText = result.title {
            linkPreviewTitleLabel.text = linkPreviewText
            title = linkPreviewText
        }
        
        if let linkPreviewDescription = result.description {
            linkPreviewDescriptionLabel.text = linkPreviewDescription
            description = linkPreviewDescription
        }
        
        if let linkSource = result.canonicalUrl {
            self.urlLabel.text = linkSource
            shortURL = linkSource
        }
        
        var data: [String: Any] = ["linkShortURL": shortURL, "linkTitle": title, "linkDescription": description]
        if let url = previewImageURL {
            data["linkImageURL"] = url
        }
        setLinkStuffInFirebase(data: data)
    }
    
    func setLinkStuffInFirebase(data: [String: Any]) {
        if let post = post {
            if post.language == .english {
                return 
            }
            let db = Firestore.firestore()
            var string = "Posts"
            if post.isTopicPost {
                string = "TopicPosts"
            }
            let ref = db.collection(string).document(post.documentID)

            ref.updateData(data) { (err) in
                if let error = err {
                    print("###Wir haben einene Erororo: \(error.localizedDescription)")
                } else {
                    print("###Link DIngs erfolgreich")
                }
            }
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
                    
                    self.loadFact()
                }
            }
        }
    }
    
    func loadFact() {
        if post!.isTopicPost {
            followTopicImageView.isHidden = false
        }
        
        if let url = URL(string: post!.fact!.imageURL) {
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
    
    @IBAction func linkTapped(_ sender: Any) {
        if let post = post {
            delegate?.linkTapped(post: post)
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
            showButtonText(post: post, button: niceButton)
        }
    }
    
    @IBAction func reportTapped(_ sender: Any) {
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
