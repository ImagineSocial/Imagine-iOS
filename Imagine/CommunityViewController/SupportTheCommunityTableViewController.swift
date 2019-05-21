//
//  SupportTheCommunityTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 19.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

protocol JobOfferCellDelegate {
    func MoreTapped(jobOffer: JobOffer)
}

class SupportTheCommunityTableViewController: UITableViewController, JobOfferCellDelegate {
    
    var jobOffers = [JobOffer]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getJobOffers()
    }
    
    
    func getJobOffers() {
        DataHelper().getData(get: "jobOffer") { (jobOffers) in
            self.jobOffers = jobOffers as! [JobOffer]
            self.tableView.reloadData()
        }
//        JobOfferHelper().getJobOffers { (jobOffers) in
//            self.jobOffers = jobOffers
//            self.tableView.reloadData()
//        }
        
    }
    
    // MARK: - Table view data source
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return jobOffers.count
    }
    
    
     override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "SupportTheCommunityCell", for: indexPath) as? SupportTheCommunityCell {
            
            let supportField = jobOffers[indexPath.row]
            
            cell.delegate = self
            cell.setJobOffer(jobOffer: supportField)
            
            cell.headerLabel.text = supportField.title
            cell.cellBodyLabel.text = supportField.cellText
            cell.createDateLabel.text = supportField.createDate
            cell.interestedCountLabel.text = "\(supportField.interested) Interessenten"
            
            
            return cell
        }
     return UITableViewCell()
     }
    
    func MoreTapped(jobOffer: JobOffer) {
        performSegue(withIdentifier: "toJobOfferSegue", sender: jobOffer)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toJobOfferSegue" {
            if let choosenJob = sender as? JobOffer {
                if let nextVC = segue.destination as? JobOfferingViewController {
                    nextVC.jobOffer = choosenJob
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
    }
    
}


