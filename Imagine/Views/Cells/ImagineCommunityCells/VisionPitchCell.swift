//
//  VisionPitchCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 07.07.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

protocol VisionPitchDelegate {
    func nextTapped(indexPath:IndexPath)
    func backTapped(indexPath:IndexPath)
    func signUpTapped()
}

class VisionPitchCell: UICollectionViewCell {
    @IBOutlet weak var pitchImageView: UIImageView!
    @IBOutlet weak var backButton: DesignableButton!
    @IBOutlet weak var nextButton: DesignableButton!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var dismissButton: DesignableButton!
    @IBOutlet weak var signUpButton: DesignableButton!
    
    
    var delegate:VisionPitchDelegate?
    var indexPathToChangeSite = IndexPath(item: 0, section: 0)
    
    func setIndexPath(indexPath: IndexPath) {
        self.indexPathToChangeSite = indexPath
    }

    @IBAction func nextTapped(_ sender: Any) {
        let nextSite = IndexPath(item: indexPathToChangeSite.item+1, section: indexPathToChangeSite.section)
        delegate?.nextTapped(indexPath:nextSite)
    }
    @IBAction func backTapped(_ sender: Any) {
        let lastSite = IndexPath(item: indexPathToChangeSite.item-1, section: indexPathToChangeSite.section)
        delegate?.backTapped(indexPath:lastSite)
    }
    
    @IBAction func signUpButtonTapped(_ sender: Any) {
        delegate?.signUpTapped()
    }
    
}
