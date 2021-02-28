//
//  DismissSegue.swift
//  Imagine
//
//  Created by Malte Schoppe on 19.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class DismissSegue: UIStoryboardSegue {
        
    override func perform() {
        if let p = source.presentingViewController {
            p.dismiss(animated: true, completion: nil)
        }
    }
}
