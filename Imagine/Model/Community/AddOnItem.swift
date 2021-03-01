//
//  AddOnItem.swift
//  Imagine
//
//  Created by Malte Schoppe on 28.02.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import Foundation

class AddOnItem {   // Otherwise it is a pain to compare Post and Community Objects for their documentID
    var documentID: String
    var item: Any
    
    init(documentID: String, item: Any) {
        self.documentID = documentID
        self.item = item
    }
}
