//
//  MultiImageCollectionCell.swift
//  Imagine
//
//  Created by Don Malte on 13.02.22.
//  Copyright © 2022 Malte Schoppe. All rights reserved.
//

import UIKit

class MultiImageCollectionCell: UICollectionViewCell {
    
    static let identifier = "MultiImageCollectionCell"
    
    let imageView = BaseImageView(image: nil, contentMode: .scaleToFill)
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
    private func setupConstraints() {
        addSubview(imageView)
        
        imageView.fillSuperview()
    }
    
    var image: UIImage? {
        didSet {
            if let image = image {
                imageView.image = image
            }
        }
    }
    
    var imageURL: String? {
        didSet {
            guard let imageURL = imageURL, let url = URL(string: imageURL) else { return}
            
            imageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default"), options: [], completed: nil)
        }
    }
}

