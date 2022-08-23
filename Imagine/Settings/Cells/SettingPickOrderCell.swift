//
//  SettingPickOrderCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 28.02.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

class SettingPickOrderCell: UITableViewCell {
    
    //MARK:- IBOutlets
    @IBOutlet weak var pickOrderLabel: UILabel!
    @IBOutlet weak var pickOrderImageView: UIImageView!
    
    //MARK:- Variables
    var post: Post? {
        didSet {
            guard let post = post else {
                return
            }
            self.pickOrderLabel.text = post.title
            
            if let imageURL = post.image?.url, let url = URL(string: imageURL) {
                self.pickOrderImageView.sd_setImage(with: url, completed: nil)
            }
        }
    }
    
    var community: Community? {
        didSet {
            if let community = community {
                self.pickOrderLabel.text = community.title
                
                if let imageURL = community.imageURL, let url = URL(string: imageURL) {
                    self.pickOrderImageView.sd_setImage(with: url, completed: nil)
                }
            }
        }
    }
    
    //MARK:- Cell Lifecycle
    override func awakeFromNib() {
        pickOrderLabel.font = UIFont(name: "IBMPlexSans", size: 14)
        
        pickOrderImageView.layer.cornerRadius = 6
        
    }
    
    
    override func prepareForReuse() {
        self.community = nil
        self.post = nil
        
        self.pickOrderImageView.image = nil
        self.pickOrderLabel.text = ""
    }
    
}
