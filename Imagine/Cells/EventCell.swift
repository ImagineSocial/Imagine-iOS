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
    
    override func awakeFromNib() {
        descriptionLabel.layer.cornerRadius = 5
        
        // add corner radius on `contentView`
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 8
        backgroundColor =  Constants.backgroundColorForTableViews
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        //set the values for top,left,bottom,right margins
        let margins = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        contentView.frame = contentView.frame.inset(by: margins)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        eventImageView.sd_cancelCurrentImageLoad()
        eventImageView.image = nil
        
        headerLabel.text = nil        
    }
    
    var post:Post? {
        didSet {
            
            if let post = post {
                headerLabel.text = post.event.title
                
                let newLineString = "\n"    // Need to hardcode this and replace the \n of the fetched text
                let descriptionText = post.event.description.replacingOccurrences(of: "\\n", with: newLineString)
                descriptionLabel.text = descriptionText
                
                locationLabel.text = post.event.location
                timeLabel.text = post.event.time
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
