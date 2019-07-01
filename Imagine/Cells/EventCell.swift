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
    
    
    
    
    
    @IBAction func participateTapped(_ sender: Any) {
    }
    
}
