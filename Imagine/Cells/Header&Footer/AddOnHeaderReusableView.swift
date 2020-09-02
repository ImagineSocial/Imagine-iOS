//
//  AddOnHeaderReusableView.swift
//  Imagine
//
//  Created by Malte Schoppe on 27.08.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit

protocol AddOnHeaderReusableViewDelegate {
    func linkTapped(link: String)
}

class AddOnHeader {
    var title: String?
    var description:String
    var imageURL: String
    var informationLink: String?
    
    init(OP: String, description: String, imageURL: String, title: String?, informationLink: String?) {
        self.description = description
        self.imageURL = imageURL
        self.title = title
        self.informationLink = informationLink
    }
}

class AddOnHeaderReusableView: UICollectionReusableView {
    
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var headerTitleLabel: UILabel!
    @IBOutlet weak var headerDescriptionLabel: UILabel!
    @IBOutlet weak var headerInfoButton: DesignableButton!
    @IBOutlet weak var headerInfoButtonHeight: NSLayoutConstraint!
    
    var delegate: AddOnHeaderReusableViewDelegate?
    var header: AddOnHeader? {
        didSet {
            if let header = header {
                if let title = header.title {
                    headerTitleLabel.text = title
                }
                
                if let url = URL(string: header.imageURL) {
                    headerImageView.sd_setImage(with: url, completed: nil)
                }
                
                headerDescriptionLabel.text = header.description
                headerDescriptionLabel.layoutIfNeeded()
                
                if header.informationLink == nil {
                    headerInfoButtonHeight.constant = 0
                    headerInfoButton.isHidden = true
                }
                
            }
        }
    }
    
    override func awakeFromNib() {
        self.layer.cornerRadius = 8
//        self.layer.borderWidth = 0.5
//        if #available(iOS 13.0, *) {
//            self.layer.borderColor = UIColor.separator.cgColor
//        } else {
//            self.layer.borderColor = UIColor.lightGray.cgColor
//        }
    }
    
    @IBAction func headerInfoButtonTapped(_ sender: Any) {
        if let header = header, let link = header.informationLink {
            delegate?.linkTapped(link: link)
        }
    }
}
