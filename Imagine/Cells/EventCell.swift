//
//  EventCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 14.06.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import Foundation
import UIKit

class EventCell :UITableViewCell {
    
    @IBOutlet weak var headerLabel:UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UITextView!
    @IBOutlet weak var eventImageView: UIImageView!
    @IBOutlet weak var participantCountLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    
    var post:Post? {
        didSet {
            
            if let post = post {
                eventImageView.image = nil
                headerLabel.text = nil
                
                headerLabel.text = post.event.title
                
                descriptionLabel.layer.cornerRadius = 5
                descriptionLabel.text = post.event.description
                
                locationLabel.text = post.event.location
                timeLabel.text = "29.06.2019, 19:00 Uhr"
                participantCountLabel.text = "15 Teilnehmer"
                
                switch post.event.type {
                case "project":
                    typeLabel.text = "Ein interessantes Projekt für dich"
                case "event":
                    typeLabel.text = "Ein interessantes Event für dich"
                case "activity":
                    typeLabel.text = "Eine interessante Veranstaltung für dich"
                default:
                    typeLabel.text = "Eine interessante Veranstaltung für dich"
                }
                
                
                
                if let url = URL(string: post.event.imageURL) {
                    if let cellImageView = eventImageView {
                        
                        cellImageView.isHidden = false      // Check ich nicht, aber geht!
                        cellImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default"), options: [], completed: nil)
                        cellImageView.layer.cornerRadius = 1
                    }
                }
            }
            
        }
    }
    
    
    @IBAction func participateTapped(_ sender: Any) {
    }
    
}
