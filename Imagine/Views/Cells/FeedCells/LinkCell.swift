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

class LinkCell : BaseFeedCell {
    
    //MARK:- IBOutlets
    @IBOutlet weak var linkThumbNailImageView: UIImageView!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var linkPreviewTitleLabel: UILabel!
    @IBOutlet weak var linkPreviewDescriptionLabel: UILabel!
    
    //MARK:- Variables
    private let slp = SwiftLinkPreview(session: URLSession.shared, workQueue: SwiftLinkPreview.defaultWorkQueue, responseQueue: DispatchQueue.main, cache: InMemoryCache())
    
    private var preview: Cancellable?
    
    //MARK:- Cell Lifecycle
    override func awakeFromNib() {
        selectionStyle = .none
        
        self.initiateCell()
        
        titleLabel.layoutIfNeeded()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.linkThumbNailImageView.image = UIImage(named: "link-default")
        
        urlLabel.text = nil
        linkPreviewDescriptionLabel.text = nil
        linkPreviewTitleLabel.text = nil
        
        linkThumbNailImageView.sd_cancelCurrentImageLoad()
        linkThumbNailImageView.image = nil
        
        if let preview = preview {
            preview.cancel()
        }
        
        resetValues()
    }
    
    //MARK:- Set Cell
    override func setCell() {
        if let post = post {
            feedUserView.delegate = self
            
            if ownProfile { // Set in the UserFeedTableViewController DataSource
                
                if let _ = cellStyle {
                    print("Already Set")
                } else {
                    cellStyle = .ownCell
                    setOwnCell(post: post)
                }
            } else {
                setDefaultButtonImages()
            }
            
            descriptionPreviewLabel.text = post.description
            commentCountLabel.text = String(post.commentCount)
            
            if post.user.displayName == "" {
                if post.anonym {
                    self.setUser()
                } else {
                    self.getUser()
                }
            } else {
                setUser()
            }
            
            if let fact = post.fact {
                                
                if fact.title == "" {
                    if fact.beingFollowed {
                        self.getCommunity(beingFollowed: true)
                    } else {
                        self.getCommunity(beingFollowed: false)
                    }
                } else {
                    self.setCommunity(post: post)
                }
            }
            
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
    
    //MARK:- Link Preview
    // To fetch the link properties for the older links without them
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
    
    //MARK:- IBActions
    @IBAction func linkTapped(_ sender: Any) {
        if let post = post {
            delegate?.linkTapped(post: post)
        }
    }
    @IBAction func thanksButtonTapped(_ sender: Any) {
        if let post = post {
            registerVote(post: post, button: thanksButton)
        }
    }
    @IBAction func wowButtonTapped(_ sender: Any) {
        if let post = post {
            registerVote(post: post, button: wowButton)
        }
    }
    @IBAction func haButtonTapped(_ sender: Any) {
        if let post = post {
            registerVote(post: post, button: haButton)
        }
    }
    @IBAction func niceButtonTapped(_ sender: Any) {
        if let post = post {
            registerVote(post: post, button: niceButton)
        }
    }
}
