//
//  FactCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 14.02.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseFirestore

class FactCell: BaseCollectionViewCell {
    
    @IBOutlet weak var factCellLabel: UILabel!
    @IBOutlet weak var factCellImageView: UIImageView!
    @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var factDescriptionLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    
    let db = FirestoreRequest.shared.db
    
    static let identifier = "FactCell"
    
    override var isHighlighted: Bool {
        didSet {
            toggleIsHighlighted()
        }
    }

    func toggleIsHighlighted() {
        UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseOut], animations: {
            self.alpha = self.isHighlighted ? 0.9 : 1.0
            self.transform = self.isHighlighted ?
                CGAffineTransform.identity.scaledBy(x: 0.97, y: 0.97) :
                CGAffineTransform.identity
        })
    }
    
    override func awakeFromNib() {
                
        contentView.clipsToBounds = false
    }
    
    override func prepareForReuse() {
        factCellImageView.image = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        containerView.layer.cornerRadius = Constants.communityCornerRadius
    }
    
    var community: Community? {
        didSet {
            if let community = community {
                factCellLabel.text = community.title
                factDescriptionLabel.text = community.description
                
                if let imageURL = community.imageURL, let url = URL(string: imageURL) {
                    factCellImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default-community"), options: [], completed: nil)
                } else {
                    factCellImageView.image = UIImage(named: "default-community")
                }
            }
        }
    }
    
    var communityID: String? {
        didSet {
            guard let communityID = communityID else {
                return
            }
            
            CommunityHelper.getCommunity(withID: communityID) { community in
                self.community = community
            }
        }
    }
}
