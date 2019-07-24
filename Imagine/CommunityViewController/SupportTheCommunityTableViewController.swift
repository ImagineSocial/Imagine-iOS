//
//  SupportTheCommunityTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 19.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit


class SupportTheCommunityTableViewController: UITableViewController {
    
    var jobOffers = [JobOffer]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getJobOffers()
        
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.view.backgroundColor = .white
        
        let imageView = UIImageView(image: UIImage(named: "peace-sign"))
        imageView.contentMode = .scaleAspectFit
        imageView.alpha = 0.3
        self.tableView.backgroundView = imageView
        
    }
    
    
    func getJobOffers() {
        DataHelper().getData(get: "jobOffer") { (jobOffers) in
            self.jobOffers = jobOffers as! [JobOffer]
            self.tableView.reloadData()
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
            
            let category = supportField.category
            switch category {
            case "IT":
                cell.categoryLabel.textColor = .blue
            case "Management":
                cell.categoryLabel.textColor = .red
            case "Sprache":
                cell.categoryLabel.textColor = .green
            case "Allgemein":
                cell.categoryLabel.textColor = .purple
            default:
                cell.categoryLabel.textColor = .black
                
            }
            
            
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
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 225
    }
    
}


