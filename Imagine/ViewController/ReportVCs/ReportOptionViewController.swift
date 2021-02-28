//
//  MeldeOptionViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 04.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class ReportOptionViewController: UIViewController {

    var reportCategory:reportCategory?
    var choosenReportOption: ReportOption?
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
        if let embededVC = segue.destination as? ReportTableViewController {
            if let reportCategory = self.reportCategory {
                embededVC.reportCategory = reportCategory
                embededVC.delegate = self
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        }
        if let nextVC = segue.destination as? ReportConfirmViewController {
            if let chosenPost = sender as? Post {
                nextVC.post = chosenPost
            } else if let chosenComment = sender as? Comment {
                nextVC.comment = chosenComment
            }
            if let reportCategory = self.reportCategory, let option = self.choosenReportOption {
                nextVC.reportCategory = reportCategory
                nextVC.choosenReportOption = option
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
}
extension ReportOptionViewController:tableViewToContainerParentProtocol {
    func passReportOption(option: ReportOption) {
        choosenReportOption = option
        nextButton.isEnabled = true
    }
}
