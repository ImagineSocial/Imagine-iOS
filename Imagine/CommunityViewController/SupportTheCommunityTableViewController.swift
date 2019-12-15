//
//  SupportTheCommunityTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 19.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class SupportTheCommunityTableViewController: UITableViewController {
    
    @IBOutlet weak var infoButton: UIBarButtonItem!
    
    var jobOffers = [JobOffer]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.activityStartAnimating()
        
        getJobOffers()
        
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.view.backgroundColor = .white
        
        if let user = Auth.auth().currentUser {
            if user.uid == "CZOcL3VIwMemWwEfutKXGAfdlLy1" {
                print("Nicht bei Malte loggen")
            } else {
                Analytics.logEvent("LookingForJobs", parameters: [:])
            }
        } else {
            Analytics.logEvent("LookingForJobs", parameters: [:])
        }
    }
    
    
    func getJobOffers() {
        DataHelper().getData(get: .jobOffer) { (jobOffers) in
            self.jobOffers = jobOffers as! [JobOffer]
            self.tableView.reloadData()
            self.view.activityStopAnimating()
        }
        
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return jobOffers.count
    }
    
    
     override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "SupportTheCommunityCell", for: indexPath) as? SupportTheCommunityCell {
            
            let supportField = jobOffers[indexPath.row]
            
            cell.headerLabel.text = supportField.title
            cell.cellBodyLabel.text = supportField.cellText
            cell.createDateLabel.text = supportField.createDate
            cell.interestedCountLabel.text = "\(supportField.interested) Interessenten"
            cell.categoryLabel.text = supportField.category
            
            return cell
        }
     return UITableViewCell()
     }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let jobOffer = jobOffers[indexPath.row]
        performSegue(withIdentifier: "toJobOfferSegue", sender: jobOffer)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toJobOfferSegue" {
            if let choosenJob = sender as? JobOffer {
                if let nextVC = segue.destination as? JobOfferingViewController {
                    nextVC.jobOffer = choosenJob
                }
            }
        }
        if segue.identifier == "toBugReportSegue" {
            if let bug = sender as? BugType {
                if let nextVC = segue.destination as? ReportABugViewController {
                    nextVC.type = bug
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 195
    }
    
    @IBAction func bugReportTapped(_ sender: Any) {
        if let _ = Auth.auth().currentUser {
            performSegue(withIdentifier: "toBugReportSegue", sender: BugType.bug)
        } else {
            self.notLoggedInAlert()
        }
    }
    
    @IBAction func languageReportTapped(_ sender: Any) {
        if let _ = Auth.auth().currentUser {
            performSegue(withIdentifier: "toBugReportSegue", sender: BugType.language)
        } else {
            self.notLoggedInAlert()
        }
    }
    
    @IBAction func infoButtonTapped(_ sender: Any) {
        infoButton.showEasyTipView(text: Constants.texts.jobOfferText)
    }
}


