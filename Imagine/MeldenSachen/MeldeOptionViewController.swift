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
    var post: Post?
    var comment: Comment?
    
    @IBOutlet weak var nextButton: DesignableButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        nextButton.isEnabled = false
    }
    
    @IBAction func backPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    

    @IBAction func nextPressed(_ sender: Any) {
        if let post = post {
            performSegue(withIdentifier: "reportConfirmSegue", sender: post)
        } else if let comment = comment {
            performSegue(withIdentifier: "reportConfirmSegue", sender: comment)
        }
    }
    
        
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let embededVC = segue.destination as? MeldeTableViewController {
            embededVC.reportCategory = self.reportCategory
            embededVC.delegate = self
        }
        if let nextVC = segue.destination as? MeldeAgreeViewController {
            if let chosenPost = sender as? Post {
                nextVC.post = chosenPost
            } else if let chosenComment = sender as? Comment {
                nextVC.comment = chosenComment
            }
            nextVC.reportCategory = reportCategory
            nextVC.choosenReportOption = choosenReportOption
        }
    }
    
}
extension MeldeOptionViewController:tableViewToContainerParentProtocol {
    func passReportOption(option: String) {
        choosenReportOption = option
        nextButton.isEnabled = true
    }
}
