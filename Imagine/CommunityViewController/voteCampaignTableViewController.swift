//
//  voteCampaignTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 16.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit


class voteCampaignTableViewController: UITableViewController {
    
    
    var campaigns = [Campaign]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = .none
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        getCampaigns()
    }
    
    @objc func getCampaigns() {
        
        DataHelper().getData(get: "campaign") { (campaigns) in
            self.campaigns = campaigns as! [Campaign]
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
            
            
            cell.CellHeaderLabel.text = campaign.title
            cell.cellBodyLabel.text = campaign.cellText
            cell.cellCreateCampaignLabel.text = campaign.createDate
            let progress: Float = Float(campaign.supporter) / (Float(campaign.opposition) + Float(campaign.supporter))
            cell.progressView.setProgress(progress, animated: true)
            cell.supporterLabel.text = "\(campaign.supporter) Supporter"
            cell.vetoLabel.text = "\(campaign.opposition) Vetos"
            cell.categoryLabel.text = campaign.category
            
            let category = campaign.category
            var labelColor: UIColor?
            
            switch category {
            case "Management":
                labelColor = .red
            case "Finanzen":
                labelColor = .green
            case "Kommunikation":
                labelColor = .blue
            case "Inhalt":
                labelColor = .purple
            default:
                labelColor = .yellow
            }
            
            cell.categoryLabel.textColor = labelColor
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    
    func MoreTapped(campaign: Campaign) {
        performSegue(withIdentifier: "toCampaignSegue", sender: campaign)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 160
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let campaign = campaigns[indexPath.row]
        
        performSegue(withIdentifier: "toCampaignSegue", sender: campaign)
        
        tableView.deselectRow(at: indexPath, animated: true)
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


