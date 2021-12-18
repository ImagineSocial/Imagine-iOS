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
    
    @IBOutlet weak var createButton: DesignableButton!
    @IBOutlet weak var showAllButton: DesignableButton!
    
    
    var delegate: TopicCollectionFooterDelegate?
    
    var type: DisplayOption?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        for view in [createButton, showAllButton] {
            guard let view = view else { return }
         
            view.layer.cornerRadius = Constants.communityCornerRadius
            view.layer.createStandardShadow(with: view.bounds.size, cornerRadius: Constants.communityCornerRadius, small: true)
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
