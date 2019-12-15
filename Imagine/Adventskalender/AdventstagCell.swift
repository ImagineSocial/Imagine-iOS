//
//  AdventstagCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 20.11.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

protocol AdventsDelegate {
    func pictureTapped(image:UIImage)
}

class AdventstagCell: UITableViewCell {
    
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var solvedImageView: UIImageView!
    @IBOutlet weak var pictureImageView: UIImageView!
    
    @IBOutlet weak var imageButton: UIButton!
    var delegate: AdventsDelegate?
    
    override func awakeFromNib() {
        
        solvedImageView.image = nil
        descriptionLabel.text = "Noch ein bisschen Geduld"
        imageButton.isEnabled = true
        adventstag = nil
        pictureImageView.image = UIImage(named: "xmasBeerBush")
        
        // add corner radius on `contentView`
        contentView.layer.cornerRadius = 8
        pictureImageView.layer.cornerRadius = 8
        backgroundColor = .clear
        if #available(iOS 13.0, *) {
            contentView.backgroundColor = .systemBackground
        } else {
            contentView.backgroundColor = .white
        }
    }
    
    var adventstag: Adventstag? {
        didSet {
            if let advent = adventstag {
                if let imageURL = advent.imageURL, let description = advent.description {
                    
                    if let url =  URL(string: imageURL) {
                        pictureImageView.sd_setImage(with: url, completed: nil)
                    }
                    descriptionLabel.text = description
                    
                    if advent.solved {
                        solvedImageView.image = UIImage(named: "xmasGolden")
                    } else {
                        
                    }
                } else {
                    imageButton.isEnabled = false
                    pictureImageView.image = UIImage(named: "xmasBeerBush")
                    pictureImageView.alpha = 0.8
                }
            }
        }
    }
    
    override func prepareForReuse() {
        solvedImageView.image = nil
        descriptionLabel.text = "Geduld, ein bisschen ist es noch hin..."
        imageButton.isEnabled = true
        adventstag = nil
        pictureImageView.image = UIImage(named: "xmasBeerBush")
        pictureImageView.alpha = 1
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        //set the values for top,left,bottom,right margins
        let margins = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        contentView.frame = contentView.frame.inset(by: margins)
    }
    
    @IBAction func imageTapped(_ sender: Any) {
        if let image = pictureImageView.image {
            delegate?.pictureTapped(image: image)
        }
    }
}
