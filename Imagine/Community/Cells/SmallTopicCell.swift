//
//  SmallTopicCell.swift
//  Imagine
//
//  Created by Don Malte on 27.02.22.
//  Copyright © 2022 Malte Schoppe. All rights reserved.
//

import UIKit

class SmallTopicCell: UICollectionViewCell {
    
    // MARK: - Variables
    
    static let identifier = "SmallTopicCell"
    
    override var isHighlighted: Bool {
        didSet {
            toggleIsHighlighted()
        }
    }
    
    var community: Community? {
        didSet {
            guard let community = community else { return }
            
            if let imageURL = community.imageURL, let url = URL(string: imageURL) {
                cellImageView.sd_setImage(with: url, placeholderImage: Icons.defaultCommunity, options: [], completed: nil)
            } else {
                cellImageView.image = Icons.defaultCommunity
            }
        }
    }
    
    // MARK: - Elements
    
    let cellImageView = BaseImageView(image: Icons.defaultCommunity, contentMode: .scaleAspectFill)
    
    // MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
                
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        cellImageView.image = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        cellImageView.layer.cornerRadius = cellImageView.frame.width / 2
    }
    
    private func setupConstraints() {
        addSubview(cellImageView)
        
        cellImageView.fillSuperview(paddingTop: 5, paddingLeading: 5, paddingBottom: -5, paddingTrailing: -5)
    }
    
    // MARK: - Functions
    
    private func toggleIsHighlighted() {
        UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseOut]) {
            self.alpha = self.isHighlighted ? 0.9 : 1.0
            self.transform = self.isHighlighted ? CGAffineTransform.identity.scaledBy(x: 0.97, y: 0.97) : CGAffineTransform.identity
        }
    }
}
