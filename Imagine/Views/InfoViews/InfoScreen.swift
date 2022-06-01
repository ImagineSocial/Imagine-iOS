//
//  InfoScreen.swift
//  Imagine
//
//  Created by Malte Schoppe on 22.07.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

enum infoType {
    case campaignVote
    case voteDetail
    case campaignDetail
    case buildUp
    case factsOverview
    case argumentsOverview
    case argumentDetail
    case sourceConterArgumentDetail
    case markPost
}

class InfoScreen: NSObject {
    
    let blackView = UIView()
    let imageView = UIImageView()
    var voteCampaignVC: CampaignVoteCollectionViewController?
    
    func showInfoScreen() {
        if let window = UIApplication.keyWindow() {
            
            blackView.backgroundColor = UIColor(white: 0, alpha: 0.5)
            
            blackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleDismiss)))
            
            window.addSubview(blackView)
            blackView.addSubview(imageView)
            imageView.image = UIImage(named: "suggestion")
            imageView.contentMode = .scaleAspectFill
            
            blackView.frame = window.frame
            blackView.alpha = 0
            imageView.frame = CGRect(x: 0, y: 0, width: blackView.frame.width, height: blackView.frame.width)
            
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.blackView.alpha = 1
                self.imageView.frame = CGRect(x:0, y: 150, width: self.imageView.frame.width, height: self.imageView.frame.height)
                
            }, completion: nil)
        }
    }
    
    @objc func handleDismiss() {
        UIView.animate(withDuration: 0.5, animations: {
            self.blackView.alpha = 0
            
            if let window = UIApplication.keyWindow() {
                self.imageView.frame = CGRect(x: 10, y: window.frame.height, width: self.imageView.frame.width, height: self.imageView.frame.height)
            }
        }, completion: { (_) in
            
            
        })
    }
    
}
