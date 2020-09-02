//
//  InfoHeaderAddOnCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 23.04.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit





class InfoHeaderAddOnCell: UITableViewCell {
    
    @IBOutlet weak var introSentenceLabel: UILabel!
    @IBOutlet weak var mainDescriptionLabel: UILabel!
    @IBOutlet weak var moreInformationButton: UIButton!
    @IBOutlet weak var moreInformationButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerImageView: UIImageView!
    
    var delegate: AddOnHeaderReusableViewDelegate?
//    var addOnInfo: AddOnHeader? {
//        didSet {
//            if let info = addOnInfo {
//                if let introSentence = info.introSentence {
//                    introSentenceLabel.text = introSentence
//                }
//
//                if let url = URL(string: info.imageURL) {
//                    headerImageView.sd_setImage(with: url, completed: nil)
//                }
//
//                mainDescriptionLabel.text = info.mainDescription
//                mainDescriptionLabel.layoutIfNeeded()
//
//                if info.moreInformationLink == nil {
//                    moreInformationButtonHeightConstraint.constant = 0
//                    moreInformationButton.isHidden = true
//                }
//
//            }
//        }
//    }
    
    override func awakeFromNib() {
//        selectionStyle = .none
//        contentView.layer.cornerRadius = 6
//        contentView.layer.borderWidth = 2
//        if #available(iOS 13.0, *) {
//            contentView.layer.borderColor = UIColor.secondarySystemBackground.cgColor
//        } else {
//            contentView.layer.borderColor = UIColor.ios12secondarySystemBackground.cgColor
//        }
//        
//        contentView.clipsToBounds = true
//        backgroundColor =  .clear
//    }
//    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        //set the values for top,left,bottom,right margins
////        let margins = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
////        contentView.frame = contentView.frame.inset(by: margins)
//        
//        mainDescriptionLabel.adjustsFontSizeToFitWidth = true
//    }
//    
//    
//    override func prepareForReuse() {
//        moreInformationButton.isHidden = false
//    }
//    
//    @IBAction func linkButtonTapped(_ sender: Any) {
//        if let info = addOnInfo {
//            if let link = info.moreInformationLink {
//                delegate?.linkTapped(link: link)
//            }
//        }
    }
    
}
