//
//  voteCampaignTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 16.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

enum suggestionMode {
    case vote
    case campaign
}

enum Impact {
    case light
    case medium
    case strong
}

class voteCampaignTableViewController: UITableViewController {
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var subHeaderLabel: UILabel!
    @IBOutlet weak var shareIdeaButton: DesignableButton!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var campaigns = [Campaign]()
    var mode: suggestionMode = .vote
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = .none
        
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.view.backgroundColor = .white
        
        setBarButtonItem()
        setVoteModeUI()
        let imageView = UIImageView(image: UIImage(named: "peace-sign"))
        imageView.contentMode = .scaleAspectFit
        imageView.alpha = 0.3

        self.tableView.backgroundView = imageView
        
    }
    
    lazy var infoScreen: InfoScreen = {
        let infoScreen = InfoScreen()
        infoScreen.voteCampaignVC = self
        return infoScreen
    }()
    
    func setBarButtonItem() {
        let infoButton = DesignableButton(type: .custom)
        infoButton.setImage(UIImage(named: "help"), for: .normal)
        infoButton.addTarget(self, action: #selector(self.infoBarButtonTapped), for: .touchUpInside)
        infoButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        infoButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        let infoBarButton = UIBarButtonItem(customView: infoButton)
        self.navigationItem.rightBarButtonItem = infoBarButton
    }
    
    
    @objc func infoBarButtonTapped() {
        infoScreen.showInfoScreen()
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

        switch mode {
        case .campaign:
            return campaigns.count
        case .vote:
            return 1
        }
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch mode {
        case .campaign:
            if let cell = tableView.dequeueReusableCell(withIdentifier: "campaignCell", for: indexPath) as? CampaignCell {

                let campaign = campaigns[indexPath.row]
                
                cell.campaign = campaign
                
                return cell
            }
        case .vote:
            if let cell = tableView.dequeueReusableCell(withIdentifier: "VoteCell", for: indexPath) as? VoteCell {
                
                cell.headerLabel.text = "Ein Privates Netzwerk"
                cell.bodyLabel.text = "Ein Netzwerk in Imagine-Optik, welches man nur mit seinen Freunden als Gruppenchat-Ersatz nutzen kann"
                cell.voteTillDateLabel.text = "Abstimmung bis: 30.09.2019 12:00"
                cell.costLabel.text = "15.000€"
                cell.timePeriodLabel.text = "6 Wochen"
                cell.commentCountLabel.text = "17"
                
                cell.voteTillDateLabel.layer.cornerRadius = 5
                cell.impactLabel.layer.cornerRadius = 3
                
                let impact = Impact.medium
                
                switch impact {
                case .light:
                    cell.impactLabel.text = "Auswirkung: Leicht"
                    cell.impactLabel.backgroundColor = .green
                case .medium:
                    cell.impactLabel.text = "Auswirkung: Medium"
                    cell.impactLabel.backgroundColor = .orange
                case .strong:
                    cell.impactLabel.text = "Auswirkung: Stark"
                    cell.impactLabel.backgroundColor = .red
                }
                
                return cell
            }
        }
        
        return UITableViewCell()
    }
    
    
    func MoreTapped(campaign: Campaign) {
        performSegue(withIdentifier: "toCampaignSegue", sender: campaign)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        switch mode {
        case .campaign:
            return 170
        case .vote:
            return 190
        }
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
    
    func setCampaignUI() {
        headerLabel.text = "Eure Vorschläge für Imagine"
        subHeaderLabel.text = "Teile uns deine Ideen für ein besseres Erlebnis mit!"
        descriptionLabel.text = "Aktuelle Kampagnen:"
        shareIdeaButton.isHidden = false
        
        
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
            self.tableView.tableHeaderView?.frame = CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 235)
            self.shareIdeaButton.alpha = 1
        }
    }
    
    func setVoteModeUI() {
        headerLabel.text = "Deine Stimme für Imagine"
        subHeaderLabel.text = "Du entscheidest mit, wie sich dein Netzwerk verändert!"
        descriptionLabel.text = "Aktuelle Abstimmungen:"
        shareIdeaButton.alpha = 0
        
        UIView.animate(withDuration: 0.5, animations: {
            self.view.layoutIfNeeded()
            self.tableView.tableHeaderView?.frame = CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 200)
        }, completion: { (_) in
            self.shareIdeaButton.isHidden = true
        })
        
    }
    
    @IBAction func segmentControlChannged(_ sender: Any) {
        if segmentedControl.selectedSegmentIndex == 0 {
            mode = .campaign
            setCampaignUI()
            tableView.reloadData()
        }
        if segmentedControl.selectedSegmentIndex == 1 {
            mode = .vote
            setVoteModeUI()
            tableView.reloadData()
        }
    }
    
    
}


