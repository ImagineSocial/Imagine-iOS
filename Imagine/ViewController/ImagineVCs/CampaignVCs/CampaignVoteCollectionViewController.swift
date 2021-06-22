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
import FirebaseAnalytics
import EasyTipView

enum suggestionMode {
    case doneCampaigns
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
    var doneCampaigns = [Campaign]()
    var mode: suggestionMode = .campaign
    let imagineDataRequest = ImagineDataRequest()
    let insetsTimesTwo: CGFloat = 20
    
    var tipView: EasyTipView?
    
    private let campaignCellIdentifier = "campaignCell"
    private let campaignHeaderIdentifier = "campaignCollectionHeaderView"
    
    //MARK:- View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getCampaigns()
        
        self.view.activityStartAnimating()
        
        collectionView.register(UINib(nibName: "CampaignCell", bundle: nil), forCellWithReuseIdentifier: campaignCellIdentifier)
        
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(setCampaignUI))
        rightSwipe.direction = .right
        
        self.view.addGestureRecognizer(rightSwipe)
        
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(setDoneCampaignsUI))
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

        imagineDataRequest.getCampaigns(onlyFinishedCampaigns: false) { (campaigns) in
            if let campaigns = campaigns {
                self.campaigns = campaigns
                self.collectionView.reloadData()
                self.view.activityStopAnimating()
            } else {
                print("COuld not fetch the campaigns")
                self.view.activityStopAnimating()
            }
        }
        
        imagineDataRequest.getCampaigns(onlyFinishedCampaigns: true) { (campaigns) in
            if let campaigns = campaigns {
                self.doneCampaigns = campaigns
                self.collectionView.reloadData()
            } else {
                print("COuld not fetch the done campaigns")
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
        case .doneCampaigns:
            return doneCampaigns.count
        }
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: campaignCellIdentifier, for: indexPath) as? CampaignCell {
            
            var campaign: Campaign!
                
            switch mode {
            case .campaign:
                campaign = campaigns[indexPath.item]
            case .doneCampaigns:
                campaign = doneCampaigns[indexPath.item]
            }
            
            cell.campaign = campaign
            
            return cell
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
        var campaign: Campaign!
        
        switch mode {
        case .campaign:
            campaign = campaigns[indexPath.item]
        case .doneCampaigns:
            campaign = doneCampaigns[indexPath.item]
        }
        
        performSegue(withIdentifier: "toCampaignSegue", sender: campaign)
        
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
        case .doneCampaigns:
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
    
    @objc func setDoneCampaignsUI() {
        
        switch mode {
        case .campaign:
            mode = .doneCampaigns
            
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
            
            setDoneCampaignsUI()
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
        
        return CGSize(width: width, height: 160)
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

