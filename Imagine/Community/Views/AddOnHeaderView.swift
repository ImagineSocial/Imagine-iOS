//
//  AddOnHeaderView.swift
//  Imagine
//
//  Created by Malte Schoppe on 29.04.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit

protocol AddOnHeaderDelegate {
    func showDescription()
    func showAllPosts(documentID: String)
    func showPostsAsAFeed(section: Int)
    func thanksTapped(info: AddOn)
    func settingsTapped(section: Int)
}

class AddOnHeaderView: UITableViewHeaderFooterView {
    
    @IBOutlet weak var headerImageView: DesignableImage!
    @IBOutlet weak var headerTitleLabel: UILabel!
    @IBOutlet weak var headerDescriptionLabel: UILabel!
    @IBOutlet weak var headerGradientView: UIView!
    @IBOutlet weak var expandDescriptionButton: DesignableButton!
    @IBOutlet weak var thanksButton: DesignableButton!
    
    @IBOutlet weak var headerImageViewHeight: NSLayoutConstraint!
    @IBOutlet weak var settingButton: DesignableButton!
    @IBOutlet weak var backgroundBorderView: DesignablePopUp!
    
    
    var delegate: AddOnHeaderDelegate?
    
    var section: Int?
    
    var info: AddOn? {
        didSet {
            if let info = info {
                switch info.style {
                
                case .singleTopic:
                    headerImageViewHeight.constant = 0
                default:
                    if let imageURL = info.imageURL {
                        if let url = URL(string: imageURL) {
                            headerImageView.sd_setImage(with: url, completed: nil)
                        }
                    } else {
                        headerImageViewHeight.constant = 0
                    }
                }
                
                headerDescriptionLabel.text = info.description
                
                if let title = info.headerTitle {
                    headerTitleLabel.text = title
                } else if info.style == .QandA {
                    headerTitleLabel.text = NSLocalizedString("new_addOn_QandA_header", comment: "adde a qanda addon")
                }
                
                if let user = AuthenticationManager.shared.user {
                    if user.uid == info.OP {
                        self.settingButton.isHidden = false
                    }
                }
            }
        }
    }
    
    override func layoutSubviews() {
        setGradientView()
    }
    
    func setGradientView() {
        //Gradient
        if let view = headerGradientView {
            
            let gradient = CAGradientLayer()
            gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
            gradient.endPoint = CGPoint(x: 0.5, y: 0.6)
            let whiteColor = UIColor.white
            gradient.colors = [whiteColor.withAlphaComponent(0.0).cgColor, whiteColor.withAlphaComponent(0.5).cgColor, whiteColor.withAlphaComponent(0.7).cgColor]
            gradient.locations = [0.0, 0.7, 1]
            gradient.frame = view.bounds
            
            view.layer.mask = gradient
        }
    }
    
    override func awakeFromNib() {
        
        contentView.clipsToBounds = true
        backgroundBorderView.clipsToBounds = true
        
        let layer = thanksButton.layer
        layer.cornerRadius = 4
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.label.cgColor
        thanksButton.backgroundColor = .systemBackground
    }
    
    override func prepareForReuse() {
        self.settingButton.isHidden = true
        
        headerImageViewHeight.constant = 75
        
        expandDescriptionButton.setImage(UIImage(named: "down"), for: .normal)
        thanksButton.setTitle(nil, for: .normal)
        thanksButton.setImage(UIImage(named: "thanksButton"), for: .normal)
    }
    
    @IBAction func showAllTapped(_ sender: Any) {
        if headerDescriptionLabel.numberOfLines == 2 {
            headerDescriptionLabel.numberOfLines = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.expandDescriptionButton.setImage(UIImage(named: "up"), for: .normal)
            }
        } else {
            headerDescriptionLabel.numberOfLines = 2
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.expandDescriptionButton.setImage(UIImage(named: "down"), for: .normal)
            }
        }
        
        delegate?.showDescription()
    }
    
    @IBAction func thanksButtonTapped(_ sender: Any) {
        if let info = info {
            self.thanksButton.setImage(nil, for: .normal)
            
            if let thanksCount = info.thanksCount {
                self.thanksButton.setTitle(String(thanksCount), for: .normal)
                info.thanksCount = thanksCount+1
            } else {
                self.thanksButton.setTitle(String(1), for: .normal)
                info.thanksCount = 1
            }
            self.thanksButton.isEnabled = false
            delegate?.thanksTapped(info: info)
            
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
    
    @IBAction func settingButtonTapped(_ sender: Any) {
        if let section = section {
            delegate?.settingsTapped(section: section)
        }
    }
    
    
//    @IBAction func showPostsInFeedStyleTapped(_ sender: Any) {
//        showAsFeedButton.isHidden = false
//        if let section = section {
//            delegate?.showPostsAsAFeed(section: section)
//        }
//    }
}
