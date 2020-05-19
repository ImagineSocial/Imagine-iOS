//
//  CommunityCollectionViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 09.03.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit

private let reuseIdentifier = "communityCell"

class CommunityItem {
    var item: Any
    var createDate: Date
    
    init(item: Any, createDate: Date) {
        self.item = item
        self.createDate = createDate
    }
}

class CommunityCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    

    var items = [CommunityItem]()
    let insetTimesTwo:CGFloat = 20
    
    let blogPostIdentifier = "BlogCell"
    let currentProjectsIdentifier = "CurrentProjectsCollectionCell"
    let tableViewIdentifier = "TableViewInCollectionViewCell"
    
    let extraItems = 2
    
    let dataHelper = DataHelper()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        HandyHelper().deleteNotifications(type: .blogPost, id: "blogPost")//Maybe
        
//        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
//        self.navigationController?.navigationBar.shadowImage = UIImage()
//        self.navigationController?.navigationBar.isTranslucent = false
//        self.navigationController?.view.backgroundColor = .white
        
        self.extendedLayoutIncludesOpaqueBars = true
        navigationController?.navigationBar.prefersLargeTitles = true
        
        
        
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(showSecretButton))
        gesture.allowableMovement = 500
        gesture.minimumPressDuration = 3
        self.view.addGestureRecognizer(gesture)
        
        // Register cell classes
        self.collectionView!.register(CommunityCollectionCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        self.collectionView!.register(UINib(nibName: "BlogPostCell", bundle: nil), forCellWithReuseIdentifier: blogPostIdentifier)
        self.collectionView!.register(UINib(nibName: "CurrentProjectsCollectionCell", bundle: nil), forCellWithReuseIdentifier: currentProjectsIdentifier)
        collectionView.register(UINib(nibName: tableViewIdentifier, bundle: nil), forCellWithReuseIdentifier: tableViewIdentifier)
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        let value:CGFloat = (UIScreen.main.bounds.width)-insetTimesTwo
        layout.itemSize = CGSize(width: value, height: 125)
        layout.headerReferenceSize = CGSize(width: self.collectionView.frame.size.width, height: 85)
        collectionView!.collectionViewLayout = layout
        
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
                
                self.dataHelper.getData(get: .vote) { (votes) in
                    for vote in votes {
                        if let vote = vote as? Vote {
                            let item = CommunityItem(item: vote, createDate: vote.createDate)
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
    }
   
    @objc func showSecretButton() {
        performSegue(withIdentifier: "toSecretSegue", sender: nil)
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return extraItems
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return extraItems
        } else {
            return items.count
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.section == 0 {
            
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? CommunityCollectionCell {
                
                cell.delegate = self
                
                switch indexPath.item {
                case 0:
                    cell.cellType = .first
                case 1:
                    cell.cellType = .second
                default:
                    print("Doesnt matter")
                }
                
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
                        
                        cell.delegate = self
                        
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
                            cell.contentView.layer.cornerRadius = 5
                        } else {
                            let layer = cell.contentView.layer
                            
                            if #available(iOS 13.0, *) {
                                layer.borderColor = UIColor.secondarySystemBackground.cgColor
                            } else {
                                layer.borderColor = UIColor.ios12secondarySystemBackground.cgColor
                            }
                            layer.borderWidth = 1
                            layer.cornerRadius = 5
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
    
        
        if indexPath.section == 0{
            if indexPath.item == 0 {
                return CGSize(width: collectionView.frame.width-insetTimesTwo, height: 175)     // First OptionCell
            } else {
                return CGSize(width: collectionView.frame.width-insetTimesTwo, height: 120)     // SecondOptionCell
            }
        } else {
            let communityItem = items[indexPath.item]
            
            if let blogPost = communityItem.item as? BlogPost {
                if blogPost.isCurrentProjectsCell {
                    return CGSize(width: collectionView.frame.width-insetTimesTwo, height: 225)    // For CurrentProfectsCollectionCell
                } else {
                    return CGSize(width: collectionView.frame.width-insetTimesTwo, height: 220)   // For BlogCell
                }
            } else if let _ = communityItem.item as? JobOffer {
                return CGSize(width: collectionView.frame.width-insetTimesTwo, height: 165)   // For JobOffer
            } else if let _ = communityItem.item as? Vote {
                return CGSize(width: collectionView.frame.width-insetTimesTwo, height: 180)   // For Vote
            } else {
                return CGSize(width: collectionView.frame.width-insetTimesTwo, height: 225)
            }
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        
        if let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "communityHeader", for: indexPath) as? CommunityHeader {

                headerView.headerLabel.text = "Aktuell"

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
        
    }
    
    func secretButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "toSecretSegue", sender: nil)
    }
    
}

extension CommunityCollectionViewController: CommunityCollectionCellDelegate, CurrentProjectDelegate, TableViewInCollectionViewCellDelegate {
    
    func itemTapped(item: Any) {
        if let jobOffer = item as? JobOffer {
            performSegue(withIdentifier: "toJobOfferDetailSegue", sender: jobOffer)
        } else if let vote = item as? Vote {
            performSegue(withIdentifier: "toVoteDetailSegue", sender: vote)
        }
    }
    
    func sourceTapped(link: String) {
        performSegue(withIdentifier: "linkTapped", sender: link)
    }
    
    func buttonTapped(button: CommunityCellButtonType) {
        switch button {
        case .moreInfo:
            performSegue(withIdentifier: "toMoreInfoSegue", sender: nil)
        case .help:
            performSegue(withIdentifier: "toSupportTheCommunitySegue", sender: nil)
        case .proposals:
            performSegue(withIdentifier: "toProposalsSegue", sender: nil)
        case .communityChat:
            let chat = Chat()
            chat.documentID = "CommunityChat"
            
            performSegue(withIdentifier: "toChatSegue", sender: chat)
        case .vision:
            performSegue(withIdentifier: "toVisionSegue", sender: nil)
        case .settings:
            performSegue(withIdentifier: "toSettingsSegue", sender: nil)
        }
    }
}


class CommunityHeader: UICollectionReusableView {
    
    @IBOutlet weak var headerLabel: UILabel!
    
}
