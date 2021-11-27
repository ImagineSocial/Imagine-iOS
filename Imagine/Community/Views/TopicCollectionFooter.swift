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
            guard let view = view else { return }
            
            let layer = view.layer
            layer.shadowColor = UIColor.label.cgColor
            layer.shadowOffset = CGSize(width: 0, height: 3)
            layer.shadowRadius = 4
            layer.shadowOpacity = 0.3
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
