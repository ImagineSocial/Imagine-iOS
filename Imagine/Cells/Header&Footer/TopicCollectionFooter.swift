//
//  TopicCollectionFooter.swift
//  Imagine
//
//  Created by Malte Schoppe on 13.05.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit

protocol TopicCollectionFooterDelegate {
    func addTopicTapped(type: DisplayOption)
    func showAllTapped(type: DisplayOption)
}

class TopicCollectionFooter: UICollectionReusableView {
    
    @IBOutlet weak var addTopicView: DesignablePopUp!
    @IBOutlet weak var showAllView: DesignablePopUp!
    
    var delegate: TopicCollectionFooterDelegate?
    
    var type: DisplayOption?
    
    override func awakeFromNib() {
        for view in [addTopicView, showAllView] {
            let layer = view!.layer
            
            layer.cornerRadius = 4
            layer.masksToBounds = true
            if #available(iOS 13.0, *) {
                layer.borderColor = UIColor.secondaryLabel.cgColor
            } else {
                layer.borderColor = UIColor.black.cgColor
            }
            layer.borderWidth = 0.5
        }
    }
    
    @IBAction func addTopicTapped(_ sender: Any) {
        if let type = type {
            delegate?.addTopicTapped(type: type)
        }

    }
    @IBAction func showAllTapped(_ sender: Any) {
        if let type = type {
            delegate?.showAllTapped(type: type)
        }
    }
    
}
