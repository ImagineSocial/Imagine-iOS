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
            if let post = post {
                self.pickOrderLabel.text = post.title

                if post.imageURL != "" {
                    if let url = URL(string: post.imageURL) {
                        self.pickOrderImageView.sd_setImage(with: url, completed: nil)
                    }
                }
            }
        }
    }
    
    var fact: Community? {
        didSet {
            if let fact = fact {
                self.pickOrderLabel.text = fact.title
                
                if fact.imageURL != "" {
                    if let url = URL(string: fact.imageURL) {
                        self.pickOrderImageView.sd_setImage(with: url, completed: nil)
                    }
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
        self.fact = nil
        self.post = nil
        
        self.pickOrderImageView.image = nil
        self.pickOrderLabel.text = ""
    }
    
}
