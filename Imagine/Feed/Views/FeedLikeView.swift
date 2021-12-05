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
        commentCountLabel.text = String(post.commentCount)
    }
    
    private func setupConstraints() {
        let buttons = [thanksButton!, wowButton!, haButton!, niceButton!]
        
        for button in buttons {
            button.imageView?.contentMode = .scaleAspectFit
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
        thanksButton.isEnabled = true
        wowButton.isEnabled = true
        haButton.isEnabled = true
        niceButton.isEnabled = true
    }
    
    //MARK:- Layout
    
    /// If you look at your own Feed at UserFeedTableView
    func setOwnCell(post: Post) {
        
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
    
    func showLikeCount(for button: VoteButton, post: Post) {
        
        switch button {
        case .thanks:
            thanksButton.setImage(nil, for: .normal)
            thanksButton.setTitle(String(post.votes.thanks), for: .normal)
        case .wow:
            wowButton.setImage(nil, for: .normal)
            wowButton.setTitle(String(post.votes.wow), for: .normal)
        case .ha:
            haButton.setImage(nil, for: .normal)
            haButton.setTitle(String(post.votes.ha), for: .normal)
        case .nice:
            niceButton.setImage(nil, for: .normal)
            niceButton.setTitle(String(post.votes.nice), for: .normal)
        }
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
