//
//  voteCampaignTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 16.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import EasyTipView

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
    
//    @IBOutlet weak var spaceBetweenSubheaderAndDescriptionLabel: NSLayoutConstraint!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var subHeaderLabel: UILabel!
    @IBOutlet weak var shareIdeaButton: DesignableButton!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var infoButton: UIBarButtonItem!
    @IBOutlet weak var shareIdeaButtonIcon: UIImageView!
    
    var campaigns = [Campaign]()
    var votes = [Vote]()
    var mode: suggestionMode = .vote
    let dataHelper = DataHelper()
    
    var tipView: EasyTipView?
    
    let voteCellIdentifier = "VoteCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let user = Auth.auth().currentUser {
            if user.uid == "CZOcL3VIwMemWwEfutKXGAfdlLy1" {
                print("Nicht bei Malte loggen")
            } else {
                Analytics.logEvent("LookingForCampaigns", parameters: [:])
            }
        } else {
            Analytics.logEvent("LookingForCampaigns", parameters: [:])
        }
        
        self.view.activityStartAnimating()
        
        tableView.register(UINib(nibName: "VoteCell", bundle: nil), forCellReuseIdentifier: voteCellIdentifier)
        tableView.separatorStyle = .none
                
        
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(setCampaignUI))
        rightSwipe.direction = .right
        
        self.view.addGestureRecognizer(rightSwipe)
        
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(setVoteModeUI))
        leftSwipe.direction = .left
        self.view.addGestureRecognizer(leftSwipe)
        
        setCampaignUI()
        
        let font: [AnyHashable : Any] = [NSAttributedString.Key.font : UIFont(name: "IBMPlexSans", size: 15) as Any]
        segmentedControl.setTitleTextAttributes(font as? [NSAttributedString.Key : Any], for: .normal)
        segmentedControl.tintColor = .imagineColor
        
        let lay = shareIdeaButton.layer
        lay.borderColor = UIColor.imagineColor.cgColor
        lay.borderWidth = 1
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let tipView = tipView {
            tipView.dismiss()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let tipView = tipView {
            tipView.dismiss()
        }
    }
    
    lazy var infoScreen: InfoScreen = {
        let infoScreen = InfoScreen()
        infoScreen.voteCampaignVC = self
        return infoScreen
    }()
    
    
    override func viewWillAppear(_ animated: Bool) {
//        navigationController?.navigationBar.prefersLargeTitles = false
        getCampaigns()
    }
    
    func getCampaigns() {
        dataHelper.getData(get: .vote) { (votes) in
            if let votez = votes as? [Vote] {
                self.votes = votez
                self.tableView.reloadData()
                self.view.activityStopAnimating()
            } else {
                print("Couldnt get the votes: \(votes)")
                self.view.activityStopAnimating()
                self.descriptionLabel.text = "Hier ist etwas schief gelaufen"
            }
        }
        
        dataHelper.getData(get: .campaign) { (campaigns) in
            if let campaignz = campaigns as? [Campaign] {
                self.campaigns = campaignz
            }
        }
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        switch mode {
        case .campaign:
            return campaigns.count
        case .vote:
            return votes.count
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
            if let cell = tableView.dequeueReusableCell(withIdentifier: voteCellIdentifier, for: indexPath) as? VoteCell {
                
                let vote = votes[indexPath.row]
                
                
                
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
            return 165
        case .vote:
            return 185
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch mode {
        case .campaign:
            let campaign = campaigns[indexPath.row]
            
            performSegue(withIdentifier: "toCampaignSegue", sender: campaign)
        case .vote:
            let vote = votes[indexPath.row]
            
            performSegue(withIdentifier: "toVoteSegue", sender: vote)
        }
        
        
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
        if segue.identifier == "toVoteSegue" {
            if let choosenVote = sender as? Vote {
                if let nextVC = segue.destination as? VoteViewController {
                    nextVC.vote = choosenVote
                }
            }
        }
    }
    
    @objc func setCampaignUI() {
        switch mode {
        case .vote:
            mode = .campaign
            
            let option = UIView.AnimationOptions.transitionCrossDissolve
            
            UIView.transition(with: self.view, duration: 0.5, options: option, animations: {
//                self.tableView.tableHeaderView?.frame = CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 180)
                
                self.shareIdeaButton.alpha = 1
                self.shareIdeaButtonIcon.alpha = 1
                
//                self.spaceBetweenSubheaderAndDescriptionLabel.constant = 70
                
                self.segmentedControl.selectedSegmentIndex = 0
                self.headerLabel.fadeTransition(0.5)
                self.headerLabel.text = "Vorschläge"
                self.subHeaderLabel.fadeTransition(0.5)
//                self.subHeaderLabel.text = "Teile uns deine Ideen für ein besseres Erlebnis mit!"
                self.descriptionLabel.fadeTransition(0.5)
                self.descriptionLabel.text = "Aktuelle Kampagnen:"
                self.tableView.reloadData()
                
            }) { (_) in
                
            }
        default:
            print("Nothing will happen")
        }
    }
    
    @objc func setVoteModeUI() {
        
        switch mode {
        case .campaign:
            mode = .vote
            
            let option = UIView.AnimationOptions.transitionCrossDissolve
            
            UIView.transition(with: self.view, duration: 0.5, options: option, animations: {
                self.shareIdeaButton.alpha = 0
                self.shareIdeaButtonIcon.alpha = 0
//                self.tableView.tableHeaderView?.frame = CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 180)
                
                self.segmentedControl.selectedSegmentIndex = 1
//                self.spaceBetweenSubheaderAndDescriptionLabel.constant = 10
                self.headerLabel.fadeTransition(0.5)
                self.headerLabel.text = "Votes"
                self.subHeaderLabel.fadeTransition(0.5)
//                self.subHeaderLabel.text = "Du entscheidest mit, wie sich dein Netzwerk verändert!"
                self.descriptionLabel.fadeTransition(0.5)
                self.descriptionLabel.text = "Aktuelle Abstimmungen:"
                self.tableView.reloadData()
                
            }) { (_) in
                
            }
        default:
            print("Nothing will happen")
        }
    }
    
    @IBAction func segmentControlChannged(_ sender: Any) {
        if segmentedControl.selectedSegmentIndex == 0 {
            
            setCampaignUI()
        }
        if segmentedControl.selectedSegmentIndex == 1 {
            
            setVoteModeUI()
        }
    }
    
    @IBAction func shareIdeaTapped(_ sender: Any) {
        if let _ = Auth.auth().currentUser {
            performSegue(withIdentifier: "toNewCampaignSegue", sender: nil)
        } else {
            self.notLoggedInAlert()
        }
    }
    
    @IBAction func infoButtonTapped(_ sender: Any) {
        if let tipView = tipView {
            tipView.dismiss()
        } else {
            tipView = EasyTipView(text: Constants.texts.voteCampaignText)
            tipView!.show(forItem: infoButton)
        }
    }
}


