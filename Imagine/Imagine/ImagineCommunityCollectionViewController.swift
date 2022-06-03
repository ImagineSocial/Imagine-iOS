//
//  CommunityCollectionViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 09.03.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit

struct CommunityItem {
    var item: Any
    var createDate: Date
    
    init(item: Any, createDate: Date) {
        self.item = item
        self.createDate = createDate
    }
}

//It can get a bit confusing otherwise
enum NavigationSection: Int, CaseIterable {
    case navigation, dataReport, finished, campaign
}

class ImagineCommunityCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    
    //MARK:- Variables
    var campaigns = [Campaign]()
    var sortedCampaigns: [Campaign]?
    
    let insetTimesTwo: CGFloat = Constants.padding.standard * 2
        
    //FinishWorkCell Boolean
    private var isOpen = false
    private var finishedWorkItems = [FinishedWorkItem]()
    
    let imagineDataRequest = ImagineDataRequest()
    
    //MARK:- View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        HandyHelper.shared.deleteNotifications(type: .blogPost, id: "blogPost")//Maybe
        
        self.extendedLayoutIncludesOpaqueBars = true
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(showSecretButton))
        gesture.allowableMovement = 500
        gesture.minimumPressDuration = 3
        self.view.addGestureRecognizer(gesture)
        
        setupCollectionView()
        getData()
    }
    
    func reloadViewForLayoutReason() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.collectionView.reloadData()
        }
    }
    
    private func setupCollectionView() {
        // Register cell classes
        collectionView.register(ImagineCommunityNavigationCell.self, forCellWithReuseIdentifier: ImagineCommunityNavigationCell.identifier)
        collectionView.register(UINib(nibName: "DataReportCell", bundle: nil), forCellWithReuseIdentifier: DataReportCell.identifier)
        collectionView.register(CampaignCell.self, forCellWithReuseIdentifier: CampaignCell.identifier)
        collectionView.register(UINib(nibName: "FinishedWorkCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: FinishedWorkCollectionViewCell.identifier)
        
        // Register header classes
        collectionView.register(UINib(nibName: "ImagineCommunityProposalHeader", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ImagineCommunityProposalHeader.identifier)
        collectionView.register(ImagineCommunityHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ImagineCommunityHeader.identifier)
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.headerReferenceSize = CGSize(width: self.collectionView.frame.size.width, height: 85)
        layout.minimumLineSpacing = 20
        collectionView.collectionViewLayout = layout
    }
    
    //MARK: - Get Data
    
    func getData() {
        
        //Show placeholder cells to avoid a big UI jump when they are fetched
        let workItem = FinishedWorkItem(title: "", description: "", createDate: Date())
        finishedWorkItems.append(contentsOf: [workItem, workItem, workItem, workItem])
        
        imagineDataRequest.getCampaigns(onlyFinishedCampaigns: false) { (campaigns) in
            if let campaigns = campaigns {
                self.campaigns = campaigns
                self.collectionView.reloadData()
            } else {
                //TODO: Error handling
            }
        }
        
        let request = ImagineDataRequest()
        request.getFinishedWorkload { (data) in
            if let workItems = data {
                self.finishedWorkItems.removeAll()
                self.finishedWorkItems = workItems
                self.collectionView.reloadData()
            } else {
                return
            }
        }
    }
    
    // MARK:- UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        NavigationSection.allCases.count
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        let section = NavigationSection.allCases[section]
        
        switch section {
        case .navigation, .dataReport:
            return 1
        case .campaign:
            if let sortCampaigns = sortedCampaigns {
                return sortCampaigns.count
            } else {
                return campaigns.count
            }
        case .finished:
            if isOpen {
                return finishedWorkItems.count
            } else {
                return 4
            }
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let section = NavigationSection.allCases[indexPath.section]
        
        switch section {
        case .navigation:
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImagineCommunityNavigationCell.identifier, for: indexPath) as? ImagineCommunityNavigationCell {
                
                cell.delegate = self
                
                return cell
            }
        case .dataReport:
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DataReportCell.identifier, for: indexPath) as? DataReportCell {
                
                return cell
            }
        case .finished:
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FinishedWorkCollectionViewCell.identifier, for: indexPath) as? FinishedWorkCollectionViewCell {
                
                let workItem = finishedWorkItems[indexPath.item]
                
                cell.finishedWorkItem = workItem
                cell.delegate = self
                
                return cell
            }
        case .campaign:
            var campaign: Campaign!
            
            if let sortedCampaigns = sortedCampaigns {
                campaign = sortedCampaigns[indexPath.item]
            } else {
                campaign = campaigns[indexPath.item]
            }
            
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CampaignCell.identifier, for: indexPath) as? CampaignCell {
                
                cell.campaign = campaign
                
                return cell
            }
        }
        
        return UICollectionViewCell()
    }
    
    
    //MARK: - UICollectionViewFlowLayoutDelegate
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = collectionView.frame.width - insetTimesTwo
        
        let section = NavigationSection.allCases[indexPath.section]
        
        switch section {
        case .navigation:
            return CGSize(width: width, height: 110)
        case .campaign:
            return CGSize(width: width, height: 150)
        case .finished:
            let item = finishedWorkItems[indexPath.item]
            
            if item.showDescription {
                
                let attributedString = NSAttributedString(string: item.description, attributes: [NSAttributedString.Key.font : UIFont(name: "IBMPlexSans", size: 15)!])
                let boundingRect = attributedString.boundingRect(with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
                
                return CGSize(width: width, height: 40+boundingRect.height)
            } else {
                return CGSize(width: width, height: 35)
            }
        case .dataReport:
            return CGSize(width: width, height: 140)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        let section = NavigationSection.allCases[section]
        
        switch section {
        case .campaign:
            return CGSize(width: collectionView.frame.width, height: 200)
        case .finished, .dataReport:
            return CGSize(width: collectionView.frame.width, height: 100)
        default:
            return CGSize.zero
        }
    }
    
    //MARK: - UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let section = NavigationSection.allCases[indexPath.section]
        
        if section == .campaign {
            if let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ImagineCommunityProposalHeader.identifier, for: indexPath) as? ImagineCommunityProposalHeader {
                
                headerView.delegate = self
                
                return headerView
            }
        } else {
            if let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ImagineCommunityHeader.identifier, for: indexPath) as? ImagineCommunityHeader {
                                
                if section == .dataReport {
                    headerView.headerLabel.text = "\(getMonthString()) Report"
                } else if section == .finished {
                    headerView.headerLabel.text = Strings.justFinishedHeader
                    headerView.expandButton.isHidden = false
                    headerView.expandView = {
                        if self.isOpen {
                            self.isOpen = false
                        } else {
                            self.isOpen = true
                        }
                        
                        collectionView.reloadData()
                    }
                    headerView.isOpen = self.isOpen
                }
                
                return headerView
            }
        }
        
        return UICollectionReusableView()
    }
    
    
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let section = NavigationSection.allCases[indexPath.section]
        
        switch section {
        case .campaign:
            var campaign: Campaign
            
            if let sortedCampaigns = sortedCampaigns {
                campaign = sortedCampaigns[indexPath.item]
            } else {
                campaign = campaigns[indexPath.item]
            }
            
            let vc = CampaignViewController()
            vc.hidesBottomBarWhenPushed = true
            vc.navigationItem.largeTitleDisplayMode = .never
            vc.campaign = campaign
            
            navigationController?.pushViewController(vc, animated: true)
        case .finished:
            let item = finishedWorkItems[indexPath.item]
            
            if let cell = self.collectionView.cellForItem(at: indexPath) as? FinishedWorkCollectionViewCell {
                if item.showDescription {
                    item.showDescription = false
                    cell.hideDescription()
                } else {
                    item.showDescription = true
                    cell.showDescription()
                }
            }
            
            //Animate the changes
            collectionView.performBatchUpdates {
                collectionView.reloadData()
            }
        default:
            break
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        let section = NavigationSection.allCases[section]
        
        return section == .finished ? 10 : 20
    }
    
    
    //MARK: - Get Month
    
    func getMonthString() -> String {
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "LLLL"
        let nameOfMonth = dateFormatter.string(from: now)
        
        return nameOfMonth
    }
    
    //MARK: - Navigation
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
        
        if segue.identifier == "toBlogPost" {
            if let chosenPost = sender as? BlogPost {
                if let blogVC = segue.destination as? BlogPostViewController {
                    blogVC.blogPost = chosenPost
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
    
    //MARK: - Actions
    
    func secretButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "toSecretSegue", sender: nil)
    }
    
    @objc func showSecretButton(sender: UILongPressGestureRecognizer) {
        if sender.state == .ended {
            performSegue(withIdentifier: "toSecretSegue", sender: nil)
        }
    }
}

//MARK: - Cell Delegates
extension ImagineCommunityCollectionViewController: CommunityNavigationItemDelegate {
    
    
    func itemTapped(item: CommunityNavigationItem) {
        switch item {
        case .moreInfo:
            performSegue(withIdentifier: "toMoreInfoSegue", sender: nil)
        case .proposals:
            let vc = CampaignVoteCollectionViewController()
            vc.hidesBottomBarWhenPushed = true
            
            navigationController?.pushViewController(vc, animated: true)
        case .feedback:
            performSegue(withIdentifier: "toFeedbackSegue", sender: nil)
        case .settings:
            performSegue(withIdentifier: "toSettingsSegue", sender: nil)
        case .website:
            let language = LanguageSelection().getLanguage()
            var url: URL?
            if language == .de {
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

//MARK: - ProposalHeaderDelegate

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

//MARK: - FinishedWorkCellDelegate
extension ImagineCommunityCollectionViewController: FinishedWorkCellDelegate {
    
    func showCampaignTapped(campaignID: String) {
        let vc = CampaignViewController()
        vc.campaignID = campaignID
        vc.hidesBottomBarWhenPushed = true
        vc.navigationItem.largeTitleDisplayMode = .never
        
        navigationController?.pushViewController(vc, animated: true)
    }
}
