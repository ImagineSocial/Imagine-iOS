//
//  FactDetailViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 23.05.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class FactDetailViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var argument = Argument()
    var fact = Fact()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = argument.title
        descriptionLabel.text = argument.description
        
        self.navigationItem.title = fact.title
        
    }
    

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? SourceTableViewController {
            if segue.identifier == "toSourceTableView" {
                vc.argument = self.argument
                vc.fact = self.fact
            }
        }
        if let argumentVC = segue.destination as? ArgumentTableViewController {
            if segue.identifier == "toArgumentTableView" {
                argumentVC.argument = self.argument
                argumentVC.fact = self.fact
            }
        }
    }
    
}
