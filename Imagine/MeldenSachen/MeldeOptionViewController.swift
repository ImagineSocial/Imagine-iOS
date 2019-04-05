//
//  MeldeOptionViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 04.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class MeldeOptionViewController: UIViewController {

    var reportCategory = ""
    var choosenReportOption = ""
    var post = Post()
    
    @IBOutlet weak var nextButton: DesignableButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        nextButton.isEnabled = false
    }
    
    @IBAction func backPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    

    @IBAction func nextPressed(_ sender: Any) {
        performSegue(withIdentifier: "reportConfirmSegue", sender: post)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let embededVC = segue.destination as? MeldeTableViewController {
            embededVC.reportCategory = self.reportCategory
            embededVC.delegate = self
        }
        if let nextVC = segue.destination as? MeldeAgreeViewController {
            if let choosenPost = sender as? Post {
                nextVC.post = choosenPost
                nextVC.reportCategory = reportCategory
                nextVC.choosenReportOption = choosenReportOption
            }
        }
    }
    
}
extension MeldeOptionViewController:tableViewToContainerParentProtocol {
    func passReportOption(option: String) {
        choosenReportOption = option
        nextButton.isEnabled = true
    }
}
