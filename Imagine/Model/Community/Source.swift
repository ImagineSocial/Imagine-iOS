//
//  Source.swift
//  Imagine
//
//  Created by Malte Schoppe on 14.09.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class Source {
    var title = ""  // Title for understanding
    var description = ""
    var source = "" // Link to Source
    var addMoreCell: Bool
    var documentID = ""
    
    init(addMoreDataCell: Bool) {
        addMoreCell = addMoreDataCell
    }
}
