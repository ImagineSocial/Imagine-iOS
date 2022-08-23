//
//  Argument.swift
//  Imagine
//
//  Created by Malte Schoppe on 14.09.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit


class Argument: Codable {
    var source:[String] = []
    var proOrContra = ""    // should be enum
    var title = ""
    var description = ""
    var documentID = ""
    var contraArguments: [Argument] = []
    var addMoreData: Bool   // Is this object used to display a cell to add more Data like a fact or an argument
    var upvotes = 0
    var downvotes = 0
    
    init(addMoreDataCell: Bool) {
        addMoreData = addMoreDataCell
        
    }
}
