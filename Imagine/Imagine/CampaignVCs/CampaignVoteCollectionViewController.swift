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

enum SuggestionMode {
    case doneCampaigns
    case campaign
}

enum Impact {
    case light
    case medium
    case strong
}

class CampaignVoteCollectionViewController: UIViewController {
    
    //MARK: - Elements
        
    let layout = UICollectionViewFlowLayout()
    lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    
    lazy var infoScreen: InfoScreen = {
        let infoScreen = InfoScreen()
        infoScreen.voteCampaignVC = self
        return infoScreen
    }()
    
    //MARK: - Variables
    
    var campaigns = [Campaign]()
    var doneCampaigns = [Campaign]()
    var mode: SuggestionMode = .campaign
    let imagineDataRequest = ImagineDataRequest()
    let insetsTimesTwo: CGFloat = 30
        
    //MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getCampaigns()
        
        self.view.activityStartAnimating()
        
        setupCollectionView()
        setupUI(mode: mode)
        setupNavigationBar()
    }
    
    private func setupCollectionView() {
        collectionView.register(CampaignCell.self, forCellWithReuseIdentifier: CampaignCell.identifier)
        collectionView.register(CampaignCollectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: CampaignCollectionHeaderView.identifier)
        
        view.addSubview(collectionView)
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.fillSuperview()
    }
    
    private func setupNavigationBar() {
        navigationItem.title = Strings.proposal
    }
    
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
        let campaignVC = CampaignViewController()
        campaignVC.campaign = campaign
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "campaignVC") as? CampaignViewController {
            vc.campaign = campaign
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    
    //MARK: - Load UI Changes
    
    func setupUI(mode: SuggestionMode) {
        self.mode = mode
        
        collectionView.reloadData()
    }
    
    func shareIdea() {
        if let _ = Auth.auth().currentUser {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "newCampaignVC")
            self.present(vc, animated: true)
        } else {
            self.notLoggedInAlert()
        }
    }
}


extension CampaignVoteCollectionViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    //MARK: - CollectionView Layout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width-insetsTimesTwo
        
        return CGSize(width: width, height: 160)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        let width = collectionView.frame.width
        
        return CGSize(width: width, height: 250)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        20
    }
    
    //MARK: - CollectionView Data Source
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch mode {
        case .campaign:
            return campaigns.count
        case .doneCampaigns:
            return doneCampaigns.count
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CampaignCell.identifier, for: indexPath) as? CampaignCell {
            
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
    
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CampaignCollectionHeaderView.identifier, for: indexPath) as? CampaignCollectionHeaderView {
            
            view.delegate = self
            
            return view
        }
        
        return UICollectionReusableView()
    }
    
    
    //MARK: - CollectionView Delegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let campaign = (mode == .campaign) ? campaigns[indexPath.item] : doneCampaigns[indexPath.item]
                
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "campaignVC") as? CampaignViewController {
            vc.campaign = campaign
            navigationController?.pushViewController(vc, animated: true)
        }
        
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

//MARK: - CampaignCollectionHeaderDelegate

extension CampaignVoteCollectionViewController: CampaignCollectionHeaderDelegate {
    
    func segmentControlChanged(segmentControl: UISegmentedControl) {
        setupUI(mode: segmentControl.selectedSegmentIndex == 0 ? .campaign : .doneCampaigns)
    }
    
    func newCampaignTapped() {
        shareIdea()
    }
}

