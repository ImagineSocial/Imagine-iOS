//
//  CommunityCollectionViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 09.03.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit

class CommunityItem {
    var item: Any
    var createDate: Date
    
    init(item: Any, createDate: Date) {
        self.item = item
        self.createDate = createDate
    }
}

class ImagineCommunityCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    

    //MARK:- Variables
    var campaigns = [Campaign]()
    var sortedCampaigns: [Campaign]?
    
    let insetTimesTwo:CGFloat = 20
    
    let blogPostIdentifier = "BlogCell"
    private let navigationCellIdentifier = "ImagineCommunityNavigationCell"
    private let proposalHeaderIdentifier = "ImagineCommunityProposalHeader"
    private let dataReportCellIdentifier = "DataReportCollectionViewCell"
    private let campaignCellIdentifier = "campaignCell"

    private struct Section {
        let navigationSection = 0
        let dataReportSection = 1
        let campaignSection = 2
    }
    
    private let section = Section()
        
    let dataHelper = DataRequest()
    
    //MARK:- View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        HandyHelper().deleteNotifications(type: .blogPost, id: "blogPost")//Maybe
        
        self.extendedLayoutIncludesOpaqueBars = true
        navigationController?.navigationBar.prefersLargeTitles = true
 
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(showSecretButton))
        gesture.allowableMovement = 500
        gesture.minimumPressDuration = 3
        self.view.addGestureRecognizer(gesture)
        
        // Register cell classes
        collectionView.register(UINib(nibName: "BlogPostCell", bundle: nil), forCellWithReuseIdentifier: blogPostIdentifier)
        collectionView.register(UINib(nibName: "ImagineCommunityNavigationCell", bundle: nil), forCellWithReuseIdentifier: navigationCellIdentifier)
        collectionView.register(UINib(nibName: "DataReportCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: dataReportCellIdentifier)
        collectionView.register(UINib(nibName: "CampaignCell", bundle: nil), forCellWithReuseIdentifier: campaignCellIdentifier)
        
        // Register header classes
        collectionView.register(UINib(nibName: "ImagineCommunityProposalHeader", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: proposalHeaderIdentifier)
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.headerReferenceSize = CGSize(width: self.collectionView.frame.size.width, height: 85)
        layout.minimumLineSpacing = 20
        collectionView.collectionViewLayout = layout
        
        getData()
    }
    
    func reloadViewForLayoutReason() {
       DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
           self.collectionView.reloadData()
       }
    }
    
    //MARK:- Get Data
    func getData() {
        
        dataHelper.getData(get: .campaign) { (campaigns) in
            if let campaigns = campaigns as? [Campaign] {
                self.campaigns = campaigns
            } else {
                return
            }
            
            self.collectionView.reloadData()
        }
    }

    // MARK:- UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
                
        if section == self.section.navigationSection {
            return 1
        } else if section == self.section.dataReportSection {
            return 1
        } else if section == self.section.campaignSection{
            if let sortCampaigns = sortedCampaigns {
                return sortCampaigns.count
            } else {
                return campaigns.count
            }
        } else {
            return 0
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.section == self.section.navigationSection {
            
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: navigationCellIdentifier, for: indexPath) as? ImagineCommunityNavigationCell {
                
                cell.delegate = self
                
                return cell
            }
        } else if indexPath.section == self.section.dataReportSection {
            
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: dataReportCellIdentifier, for: indexPath) as? DataReportCollectionViewCell {
                
                return cell
            }
        } else if indexPath.section == self.section.campaignSection {
            
            var campaign: Campaign!
            
            if let sortedCampaigns = sortedCampaigns {
                campaign = sortedCampaigns[indexPath.item]
            } else {
                campaign = campaigns[indexPath.item]
            }
            
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: campaignCellIdentifier, for: indexPath) as? CampaignCell {
                
                //The TableViewInCOllectionViewCell can show Vote, Campaign and JobOffer
                
                cell.campaign = campaign
                
                return cell
            }
        }
        
        return UICollectionViewCell()
    }
    
    
    //MARK:- UICollectionViewFlowLayoutDelegate
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    
        let width = collectionView.frame.width-insetTimesTwo
        
        if indexPath.section == self.section.navigationSection {
            return CGSize(width: width, height: 205)
        } else if indexPath.section == self.section.dataReportSection {
            return CGSize(width: width, height: 140)
        } else if indexPath.section == self.section.campaignSection {
            return CGSize(width: width, height: 150)
        } else {
            return CGSize.zero
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == self.section.navigationSection {
            return CGSize.zero
        } else if section == self.section.dataReportSection {
            return CGSize(width: collectionView.frame.width, height: 80)
        } else if section == self.section.campaignSection {
            return CGSize(width: collectionView.frame.width, height: 170)
        } else {
            return CGSize.zero
        }
    }
    
    
    //MARK:- UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        if indexPath.section == 1 {
            if let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "communityHeader", for: indexPath) as? CommunityHeader {

                
                    headerView.headerLabel.text = "\(getMonthString()) Report"

                return headerView
            }
        } else {
            if let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: proposalHeaderIdentifier, for: indexPath) as? ImagineCommunityProposalHeader {
                
                headerView.delegate = self
                
                return headerView
            }
        }
        

        return UICollectionReusableView()
    }
    
    
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == self.section.campaignSection {
            var campaign: Campaign!
            
            if let sortedCampaigns = sortedCampaigns {
                campaign = sortedCampaigns[indexPath.item]
            } else {
                campaign = campaigns[indexPath.item]
            }
            
            performSegue(withIdentifier: "toCampaignSegue", sender: campaign)
        }
    }
    
    
    //MARK:- Get Month
    func getMonthString() -> String {
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "LLLL"
        let nameOfMonth = dateFormatter.string(from: now)
        
        return nameOfMonth
    }
    
    //MARK:- Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toChatSegue" {
            if let chosenChat = sender as? Chat {
                if let chatVC = segue.destination as? ChatViewController {
                    chatVC.chat = chosenChat
                    chatVC.chatSetting = .community
                }
            }
        }
        
        if segue.identifier == "toVisionSegue" {
            if let visionVC = segue.destination as? SwipeCollectionViewController {
                visionVC.diashow = .vision
                visionVC.communityVC = self
            }
        }
        
        if segue.identifier == "toCampaignSegue" {
            if let campaignVC = segue.destination as? CampaignViewController, let campaign = sender as? Campaign {
                campaignVC.campaign = campaign
            }
        }
        
        if segue.identifier == "toBlogPost" {
            if let chosenPost = sender as? BlogPost {
                if let blogVC = segue.destination as? BlogPostViewController {
                    blogVC.blogPost = chosenPost
                }
            }
        }
        if segue.identifier == "linkTapped" {
            if let chosenLink = sender as? String {
                if let webVC = segue.destination as? WebViewController {
                    webVC.link = chosenLink
                }
            }
        }
        
        if segue.identifier == "toVoteDetailSegue" {
            if let vote = sender as? Vote {
                if let vc = segue.destination as? VoteViewController {
                    vc.vote = vote
                }
            }
        }
        
        if segue.identifier == "toJobOfferDetailSegue" {
            if let job = sender as? JobOffer {
                if let vc = segue.destination as? JobOfferingViewController {
                    vc.jobOffer = job
                }
            }
        }
        
        if segue.identifier == "toFeedbackSegue" {
            if let navVC = segue.destination as? UINavigationController {
                if let vc = navVC.topViewController as? ReportABugViewController {
                    vc.type = .feedback
                }
            }
        }
    }
    
    //MARK:- Actions
    
    func secretButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "toSecretSegue", sender: nil)
    }
    
    @objc func showSecretButton(sender: UILongPressGestureRecognizer) {
        if sender.state == .ended {
            performSegue(withIdentifier: "toSecretSegue", sender: nil)
        }
    }
}

//MARK:- Cell Delegates
extension ImagineCommunityCollectionViewController: CommunityCollectionCellDelegate {
    
    
    func buttonTapped(button: CommunityCellButtonType) {
        switch button {
        case .moreInfo:
            performSegue(withIdentifier: "toMoreInfoSegue", sender: nil)
        case .help:
            performSegue(withIdentifier: "toSupportTheCommunitySegue", sender: nil)
        case .proposals:
            performSegue(withIdentifier: "toProposalsSegue", sender: nil)
        case .imagineFund:
            performSegue(withIdentifier: "toImagineFundSegue", sender: nil)
        case .feedback:
            performSegue(withIdentifier: "toFeedbackSegue", sender: nil)
        case .settings:
            performSegue(withIdentifier: "toSettingsSegue", sender: nil)
        case .website:
            let language = LanguageSelection().getLanguage()
            var url: URL?
            if language == .german {
                url = URL(string: "https://imagine.social")
            } else {
                url = URL(string: "https://en.imagine.social")
            }
            if let url = url {
                UIApplication.shared.open(url)
            }
        }
    }
}

//MARK:- ProposalHeaderDelegate

extension ImagineCommunityCollectionViewController: ImagineCommunityProposalHeaderDelegate {
    
    func selectionChanged(selection: CampaignType) {
        if selection == .all {
            self.sortedCampaigns = nil
            
            self.campaigns.sort {
                ($0.supporter) > ($1.supporter)
            }
            self.collectionView.reloadData()
            
            return
        } else {
            
            self.sortedCampaigns?.removeAll()
            var newSortCampaigns = [Campaign]()
            
            //Sort the fetched campaigns for the selected criteria
            for campaign in campaigns {
                if let category = campaign.category, category.type == selection {
                    newSortCampaigns.append(campaign)
                }
            }
            
            newSortCampaigns.sort {
                ($0.supporter) > ($1.supporter)
            }
            
            self.sortedCampaigns = newSortCampaigns
            self.collectionView.reloadData()
        }
    }
}

class CommunityHeader: UICollectionReusableView {
    
    @IBOutlet weak var headerLabel: UILabel!
    
}
