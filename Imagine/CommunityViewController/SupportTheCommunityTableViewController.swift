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
    let reuseIdentifier = "SupportTheCommunityCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.activityStartAnimating()
        
        getJobOffers()
        
        
        tableView.register(UINib(nibName: "JobOfferCell", bundle: nil), forCellReuseIdentifier: reuseIdentifier)
        
        self.extendedLayoutIncludesOpaqueBars = true
//        self.navigationController?.navigationBar.isTranslucent = false
//        self.navigationController?.view.backgroundColor = .white
        
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
            let jobOffer = JobOffer()   // Der erste Eintrag
            jobOffer.title = "Wir brauchen dich!"
            jobOffer.cellText = "Wenn du glaubst, mit deinem Wissen oder Erfahrung kannst du uns helfen, aber es gibt keine passende Ausschreibung, gib uns Bescheid! Wir sind auf klüge Köpfe angewiesen!"
            jobOffer.documentID = ""
            jobOffer.stringDate = "15.05.2019"
            jobOffer.interested = 0
            jobOffer.category = "Allgemein"
            
            self.jobOffers.append(jobOffer)
            
            self.jobOffers.append(contentsOf: jobOffers as! [JobOffer])
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
        if let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? JobOfferCell{
            
            let supportField = jobOffers[indexPath.row]
            
            cell.jobOffer = supportField
            
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
        return UITableView.automaticDimension
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


