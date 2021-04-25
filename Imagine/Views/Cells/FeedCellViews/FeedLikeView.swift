//
//  FeedLikeView.swift
//  Imagine
//
//  Created by Don Malte on 25.04.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

protocol FeedLikeViewDelegate: class {
    func registerVote(button: DesignableButton)
}

class FeedLikeView: UIView, NibLoadable {
    
    //MARK:- IBOutlets
    @IBOutlet weak var thanksButton: DesignableButton!
    @IBOutlet weak var wowButton: DesignableButton!
    @IBOutlet weak var haButton: DesignableButton!
    @IBOutlet weak var niceButton: DesignableButton!
    @IBOutlet weak var commentCountLabel: UILabel!
    @IBOutlet weak var descriptionPreviewLabel: UILabel!
    
    //MARK:- Variables
    weak var delegate: FeedLikeViewDelegate?
    
    //MARK:- Initialization
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupFromNib()
        
        setupConstraints()
    }
    
    func setUpView() {
        
    }
    
    func setPost(post: Post) {
        descriptionPreviewLabel.text = post.description
        commentCountLabel.text = String(post.commentCount)
    }
    
    private func setupConstraints() {
        let buttons = [thanksButton!, wowButton!, haButton!, niceButton!]
        
        for button in buttons {
            button.setImage(nil, for: .normal)
            button.imageView?.contentMode = .scaleAspectFit
            button.layer.borderWidth = 0.5
            button.layer.cornerRadius = 7
            
            if #available(iOS 13.0, *) {
                button.layer.borderColor = UIColor.secondaryLabel.cgColor
            } else {
                button.layer.borderColor = UIColor.black.cgColor
            }
        }
    }
    
    func prepareForReuse(ownProfile: Bool) {
        if ownProfile {
            thanksButton.setImage(nil, for: .normal)
            wowButton.setImage(nil, for: .normal)
            haButton.setImage(nil, for: .normal)
            niceButton.setImage(nil, for: .normal)
        } else {
            thanksButton.setImage(UIImage(named: "thanksButton"), for: .normal)
            wowButton.setImage(UIImage(named: "wowButton"), for: .normal)
            haButton.setImage(UIImage(named: "haButton"), for: .normal)
            niceButton.setImage(UIImage(named: "niceButton"), for: .normal)
        }
    }
    
    func resetValues() {
        descriptionPreviewLabel.text = nil
        
        thanksButton.isEnabled = true
        wowButton.isEnabled = true
        haButton.isEnabled = true
        niceButton.isEnabled = true
    }
    
    //MARK:- Layout
    
    /// If you look at your own Feed at UserFeedTableView
    func setOwnCell(post: Post) {
        
        let buttons = [thanksButton!, wowButton!, haButton!, niceButton!]
        
        for button in buttons {
            
            button.setTitleColor(.white, for: .normal)
            button.layer.borderWidth = 0
            
            if #available(iOS 13.0, *) {
                button.backgroundColor = .tertiaryLabel
            } else {
                button.backgroundColor = .darkGray
            }
        }
        
        //Set vote count
        thanksButton.setTitle(String(post.votes.thanks), for: .normal)
        wowButton.setTitle(String(post.votes.wow), for: .normal)
        haButton.setTitle(String(post.votes.ha), for: .normal)
        niceButton.setTitle(String(post.votes.nice), for: .normal)
    }
    
    func setDefaultButtonImages() {
        thanksButton.setImage(UIImage(named: "thanksButton"), for: .normal)
        wowButton.setImage(UIImage(named: "wowButton"), for: .normal)
        haButton.setImage(UIImage(named: "haButton"), for: .normal)
        niceButton.setImage(UIImage(named: "niceButton"), for: .normal)
    }
    
    
    //MARK:- IBActions
    
    @IBAction func thanksButtonTapped(_ sender: Any) {
        delegate?.registerVote(button: thanksButton)
    }
    @IBAction func wowButtonTapped(_ sender: Any) {
        delegate?.registerVote(button: wowButton)
    }
    @IBAction func haButtonTapped(_ sender: Any) {
        delegate?.registerVote(button: haButton)
    }
    @IBAction func niceButtonTapped(_ sender: Any) {
        delegate?.registerVote(button: niceButton)
    }
}
