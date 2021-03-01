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
    

    var items = [CommunityItem]()
    let insetTimesTwo:CGFloat = 20
    
    let blogPostIdentifier = "BlogCell"
    let currentProjectsIdentifier = "CurrentProjectsCollectionCell"
    let tableViewIdentifier = "TableViewInCollectionViewCell"
    let optionsCellIdentifier = "ImagineCommunityOptionsCell"
        
    let dataHelper = DataRequest()
    
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
        self.collectionView.register(UINib(nibName: "ImagineCommunityOptionsCell", bundle: nil), forCellWithReuseIdentifier: optionsCellIdentifier)
        self.collectionView.register(UINib(nibName: "BlogPostCell", bundle: nil), forCellWithReuseIdentifier: blogPostIdentifier)
        self.collectionView.register(UINib(nibName: "CurrentProjectsCollectionCell", bundle: nil), forCellWithReuseIdentifier: currentProjectsIdentifier)
        collectionView.register(UINib(nibName: tableViewIdentifier, bundle: nil), forCellWithReuseIdentifier: tableViewIdentifier)
        
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
    
    func getData() {

        dataHelper.getData(get: .blogPosts) { (posts) in
            
            for post in posts {
                if let post = post as? BlogPost {
                    let item = CommunityItem(item: post, createDate: post.createDate)
                    self.items.append(item)
                }
            }
            
            self.dataHelper.getData(get: .jobOffer) { (jobOffer) in
                for offer in jobOffer {
                    if let offer = offer as? JobOffer {
                        let item = CommunityItem(item: offer, createDate: offer.createDate)
                        self.items.append(item)
                    }
                }
                
                self.items.sort {
                    ($0.createDate) > ($1.createDate)
                }
                
                let first = BlogPost()
                first.isCurrentProjectsCell = true
                let item = CommunityItem(item: first, createDate: Date())
                self.items.insert(item, at: 0)
                
                self.collectionView.reloadData()
                
            }
        }
    }
   
    @objc func showSecretButton(sender: UILongPressGestureRecognizer) {
        if sender.state == .ended {
            performSegue(withIdentifier: "toSecretSegue", sender: nil)
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return items.count
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.section == 0 {
            
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: optionsCellIdentifier, for: indexPath) as? ImagineCommunityOptionsCell {
                
                cell.delegate = self
                
                return cell
            }
            
        } else {
            let communityItem = items[indexPath.item]
            
            var isEverySecondCell = false
            if indexPath.item % 2 == 0 {
                isEverySecondCell = true
            }

            if let blogPost = communityItem.item as? BlogPost {
                
                if blogPost.isCurrentProjectsCell {
                    if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: currentProjectsIdentifier, for: indexPath) as? CurrentProjectsCollectionCell {
                        
                        return cell
                    }
                } else {
                    
                    if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: blogPostIdentifier, for: indexPath) as? BlogCell {
                        
                        cell.post = blogPost
                        if isEverySecondCell {
                            
                            if #available(iOS 13.0, *) {
                                cell.contentView.backgroundColor = .secondarySystemBackground
                            } else {
                                cell.contentView.backgroundColor = .ios12secondarySystemBackground
                            }
                        } else {
                            if #available(iOS 13.0, *) {
                                cell.contentView.backgroundColor = .systemBackground
                            } else {
                                cell.contentView.backgroundColor = .white
                            }
                            
                        }
                        
                        return cell
                    }
                }
            } else if let jobOffer = communityItem.item as? JobOffer {
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: tableViewIdentifier, for: indexPath) as? TableViewInCollectionViewCell {
                    cell.delegate = self
                    cell.isEverySecondCell = isEverySecondCell
                    cell.items = [jobOffer]
                    
                    return cell
                }
            } else if let vote = communityItem.item as? Vote {
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: tableViewIdentifier, for: indexPath) as? TableViewInCollectionViewCell {
                    cell.delegate = self
                    
                    cell.isEverySecondCell = isEverySecondCell
                    cell.items = [vote]
                   
                    return cell
                }
            }
        }
        
        return UICollectionViewCell()
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    
        let width = collectionView.frame.width-insetTimesTwo
        
        if indexPath.section == 0{
            return CGSize(width: width, height: 265)
        } else {
            let communityItem = items[indexPath.item]
            
            if let blogPost = communityItem.item as? BlogPost {
                if blogPost.isCurrentProjectsCell {
                    return CGSize(width: width, height: 170)    // For CurrentProfectsCollectionCell
                } else {
                    return CGSize(width: width, height: 220)   // For BlogCell
                }
            } else if let _ = communityItem.item as? JobOffer {
                return CGSize(width: width, height: 125)   // For JobOffer
            }  else {
                return CGSize(width: width, height: 225)
            }
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        
        if let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "communityHeader", for: indexPath) as? CommunityHeader {

                headerView.headerLabel.text = NSLocalizedString("latest_news_header", comment: "latest news")

            return headerView
        
        }

        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 0 {
            return CGSize.zero
        } else {
            return CGSize(width: collectionView.frame.width, height: 80)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section != 0 {
            
            if let item = items[indexPath.item].item as? BlogPost {
                if !item.isCurrentProjectsCell {
                    performSegue(withIdentifier: "toBlogPost", sender: item)
                }
            }
        }
    }
    
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
    
    func secretButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "toSecretSegue", sender: nil)
    }
    
}

extension ImagineCommunityCollectionViewController: CommunityCollectionCellDelegate, TableViewInCollectionViewCellDelegate {
    
    func itemTapped(item: Any) {
        if let jobOffer = item as? JobOffer {
            performSegue(withIdentifier: "toJobOfferDetailSegue", sender: jobOffer)
        } else if let vote = item as? Vote {
            performSegue(withIdentifier: "toVoteDetailSegue", sender: vote)
        }
    }
    
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
        }
    }
}


class CommunityHeader: UICollectionReusableView {
    
    @IBOutlet weak var headerLabel: UILabel!
    
}