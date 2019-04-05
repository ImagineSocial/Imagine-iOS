//
//  voteCampaignTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 16.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

protocol CampaignCellDelegate {
    func MoreTapped(campaign: Campaign)
}

class voteCampaignTableViewController: UITableViewController, CampaignCellDelegate {
    
    
    var campaigns = [Campaign]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        getCampaigns()
    }
    
    @objc func getCampaigns() {
        
        CampaignHelper().getCampaigns { (campaigns) in
            self.campaigns = campaigns
            self.tableView.reloadData()
        }
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return campaigns.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "campaignCell", for: indexPath) as? VoteCampaignCell {
            let campaign = campaigns[indexPath.row]
            
            cell.delegate = self
            cell.setCampaign(campaign: campaign)
            
            cell.CellHeaderLabel.text = campaign.title
            cell.cellBodyLabel.text = campaign.cellText
            cell.cellCreateCampaignLabel.text = campaign.createDate
            let progress: Float = Float(campaign.supporter) / (Float(campaign.opposition) + Float(campaign.supporter))
            cell.progressView.setProgress(progress, animated: true)
            cell.supporterLabel.text = "\(campaign.supporter) Supporter"
            cell.vetoLabel.text = "\(campaign.opposition) Vetos"
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    
    func MoreTapped(campaign: Campaign) {
        performSegue(withIdentifier: "toCampaignSegue", sender: campaign)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toCampaignSegue" {
            if let choosenCampaign = sender as? Campaign {
                if let nextVC = segue.destination as? CampaignViewController {
                    nextVC.campaign = choosenCampaign
                }
            }
        }
    }
    
}


