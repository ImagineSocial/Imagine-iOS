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

class CampaignVoteCollectionViewController: UICollectionViewController {
    
    //MARK:- IBOutlets
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var infoButton: UIBarButtonItem!
    
    //MARK:- Variables
    var campaigns = [Campaign]()
    var votes = [Vote]()
    var mode: suggestionMode = .campaign
    let dataHelper = DataRequest()
    let insetsTimesTwo: CGFloat = 20
    
    var tipView: EasyTipView?
    
    private let voteCellIdentifier = "VoteCell"
    private let campaignCellIdentifier = "campaignCell"
    private let campaignHeaderIdentifier = "campaignCollectionHeaderView"
    
    //MARK:- View Lifecycle
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
        
        getCampaigns()
        
        self.view.activityStartAnimating()
        
        collectionView.register(UINib(nibName: "VoteCell", bundle: nil), forCellWithReuseIdentifier: voteCellIdentifier)
        collectionView.register(UINib(nibName: "CampaignCell", bundle: nil), forCellWithReuseIdentifier: campaignCellIdentifier)
        
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
    
    func getCampaigns() {
        dataHelper.getData(get: .vote) { (votes) in
            if let votez = votes as? [Vote] {
                self.votes = votez
                self.collectionView.reloadData()
                self.view.activityStopAnimating()
            } else {
                print("Couldnt get the votes: \(votes)")
                self.view.activityStopAnimating()
            }
        }
        
        dataHelper.getData(get: .campaign) { (campaigns) in
            if let campaignz = campaigns as? [Campaign] {
                self.campaigns = campaignz
            }
        }
    }
    
    func MoreTapped(campaign: Campaign) {
        performSegue(withIdentifier: "toCampaignSegue", sender: campaign)
    }
    
    //MARK:- CollectionView Data Source
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch mode {
        case .campaign:
            return campaigns.count
        case .vote:
            return votes.count
        }
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch mode {
        case .campaign:
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: campaignCellIdentifier, for: indexPath) as? CampaignCell {

                let campaign = campaigns[indexPath.row]
                
                cell.campaign = campaign
                
                return cell
            }
        case .vote:
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: voteCellIdentifier, for: indexPath) as? VoteCell {
                
                let vote = votes[indexPath.row]
                
                cell.vote = vote
                
                return cell
            }
        }
        
        return UICollectionViewCell()
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: campaignHeaderIdentifier, for: indexPath) as? CampaignCollectionHeaderView {
            
            view.delegate = self
            
            return view
        }
        
        return UICollectionReusableView()
    }
    
    
    //MARK:- CollectionView Delegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch mode {
        case .campaign:
            let campaign = campaigns[indexPath.row]
            
            performSegue(withIdentifier: "toCampaignSegue", sender: campaign)
        case .vote:
            let vote = votes[indexPath.row]
            
            performSegue(withIdentifier: "toVoteSegue", sender: vote)
        }
        
        
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    //MARK:- Navigation
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
    
    //MARK:- Load UI Changes
    @objc func setCampaignUI() {
        switch mode {
        case .vote:
            mode = .campaign
            
            let option = UIView.AnimationOptions.transitionCrossDissolve
            
            UIView.transition(with: self.view, duration: 0.5, options: option, animations: {
                self.segmentedControl.selectedSegmentIndex = 0

                self.collectionView.reloadData()
                
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
                self.segmentedControl.selectedSegmentIndex = 1
                self.collectionView.reloadData()
                
            }) { (_) in
                
            }
        default:
            print("Nothing will happen")
        }
    }
    
    func shareIdea() {
        if let _ = Auth.auth().currentUser {
            performSegue(withIdentifier: "toNewCampaignSegue", sender: nil)
        } else {
            self.notLoggedInAlert()
        }
    }
    
    //MARK:- IBActions
    
    @IBAction func segmentControlChannged(_ sender: Any) {
        if segmentedControl.selectedSegmentIndex == 0 {
            
            setCampaignUI()
        }
        if segmentedControl.selectedSegmentIndex == 1 {
            
            setVoteModeUI()
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


extension CampaignVoteCollectionViewController: UICollectionViewDelegateFlowLayout {

    //MARK:- CollectionView Layout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width-insetsTimesTwo
        
        switch mode {
        case .campaign:
            return CGSize(width: width, height: 165)
        case .vote:
            return CGSize(width: width, height: 185)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        let width = collectionView.frame.width
        
        return CGSize(width: width, height: 125)
    }
    
}

//MARK:- CampaignCollectionHeaderDelegate

extension CampaignVoteCollectionViewController: CampaignCollectionHeaderDelegate {
    
    func newCampaignTapped() {
        shareIdea()
    }
}

