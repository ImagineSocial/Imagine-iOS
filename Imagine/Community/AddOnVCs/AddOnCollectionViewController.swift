//
//  AddOnCollectionViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 27.08.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseFirestore

class ProposalForOptionalInformation {
    var headerText: String
    var detailText: String
    var isFirstCell: Bool
    
    init(isFirstCell: Bool, headerText: String, detailText: String) {
        
        self.headerText = headerText
        self.isFirstCell = isFirstCell
        self.detailText = detailText
    }
}

class AddOnCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    //MARK:- Variables
    private let db = FirestoreRequest.shared.db
    private let horizontalScrollCellIdentifier = "AddOnHorizontalScrollCell"
    private let singleCommunityCellIdentifier = "SingleCommunityCollectionViewCell"
    private let proposalCellIdentifier = "AddOnProposalCell"
    private let footerViewIdentifier = "AddOnCollectionViewFooter"
    private  let qAndACellIdentifier = "AddOnQAndACollectionViewCell"
    private let playlistCellIdentifier = "AddOnPlaylistCollectionViewCell"
    
    private var optionalInformations = [AddOn]()
    
    private var noOptionalInformation = false
    private var optionalInformationProposals = [ProposalForOptionalInformation(isFirstCell: true, headerText: NSLocalizedString("proposal_header_text", comment: "individualise your community"), detailText: NSLocalizedString("proposal_header_description", comment: "What are addOns")), ProposalForOptionalInformation(isFirstCell: false, headerText: NSLocalizedString("proposal_me_active_header", comment: "What can I do?"), detailText: NSLocalizedString("proposal_me_active_description", comment: "what ca i do to make it better")),  ProposalForOptionalInformation(isFirstCell: false, headerText: "Top-News", detailText: NSLocalizedString("proposal_top_news_description", comment: "top new for visibility")), ProposalForOptionalInformation(isFirstCell: false, headerText: "Beginners Guide", detailText: NSLocalizedString("proposal_beginners_guide_description", comment: "help younglings"))]
            
    weak var pageViewHeaderDelegate: PageViewHeaderDelegate?
    
    private let collectionViewInsetsLeftAndRight: CGFloat = Constants.padding.standard * 2
    
    var community: Community? {
        didSet {
            guard let community = community else { return }

            getAddOn(community: community)
        }
    }
    
    //MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

       setupCollectionView()
    }
    
    //MARK: - Get Data
    
    private func setupCollectionView() {
        self.collectionView!.register(UINib(nibName: "AddOnHorizontalScrollCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: horizontalScrollCellIdentifier)
        self.collectionView.register(UINib(nibName: "AddOnSingleCommunityCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: singleCommunityCellIdentifier)
        self.collectionView.register(UINib(nibName: "AddOnCollectionViewFooter", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: footerViewIdentifier)
        self.collectionView.register(UINib(nibName: "AddOnProposalCell", bundle: nil), forCellWithReuseIdentifier: proposalCellIdentifier)
        self.collectionView.register(UINib(nibName: "AddOnQAndACollectionViewCell", bundle: nil), forCellWithReuseIdentifier: qAndACellIdentifier)
        self.collectionView.register(UINib(nibName: "AddOnPlaylistCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: playlistCellIdentifier)

        let newHeight: CGFloat = Constants.Numbers.communityHeaderHeight
        collectionView.contentInset = UIEdgeInsets(top: newHeight, left: 0, bottom: 0, right: 0)
        collectionView.contentOffset = CGPoint(x: 0, y: -newHeight)
        collectionView.delaysContentTouches = false
        
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            // If you are looking for the reason, the layout is wrong, it is because of the auto resizing option in storyboard collectionview
            flowLayout.scrollDirection = .vertical
            flowLayout.sectionInset = .init(top: 10, left: Constants.padding.standard, bottom: 20, right: Constants.padding.standard)
        }
    }
    
    func getAddOn(community: Community) {
        
        guard let communityID = community.id else {
            return
        }
        
        let addOnReference = FirestoreCollectionReference(document: communityID, collection: "addOns")
        let reference = FirestoreReference.collectionRef(.communities, collectionReferences: addOnReference, queries: FirestoreQuery(field: "popularity"))
        
        reference.getDocuments { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap {
                    
                    if snap.documents.count == 0 {  // No AddOn yet
                        self.noOptionalInformation = true
                        self.collectionView.reloadData()
                        
                        return
                    } else {
                        self.noOptionalInformation = false  // Need to add this here so it can update the view after the creation of a new addOn
                    }
                    
                    let snapCount = snap.documents.count
                    var index = 0
                    
                    for document in snap.documents {
                        let data = document.data()
                        
                        if let type = data["type"] as? String {
                            if type == "playlist" {
                                
                                if let title = data["title"] as? String,
                                   let description = data["description"] as? String,
                                   let OP = data["OP"] as? String {
                                    let addOn = AddOn(style: .playlist, OP: OP, documentID: document.documentID, fact: community, headerTitle: title, description: description, singleTopic: nil)
                                    
                                    if let thanksCount = data["thanksCount"] as? Int {
                                        addOn.thanksCount = thanksCount
                                    }
                                    
                                    if let itemOrder = data["itemOrder"] as? [String] {
                                        addOn.itemOrder = itemOrder
                                    }
                                    
                                    if let appleMusicURL = data["appleMusicPlaylistURL"] as? String {
                                        addOn.appleMusicPlaylistURL = appleMusicURL
                                    }
                                    if let spotifyURL = data["spotifyPlaylistURL"] as? String {
                                        addOn.spotifyPlaylistURL = spotifyURL
                                    }
                                    
                                    self.optionalInformations.append(addOn)
                                    index+=1
                                    
                                    if index == snapCount {
                                        self.collectionView.reloadData()
                                    }
                                    
                                    continue    //because it is fetched again below
                                }
                            }
                        }
                        
                        if let title = data["title"] as? String, let OP = data["OP"] as? String, let description = data["description"] as? String { //Normal collection
                            let addOn = AddOn(style: .collection, OP: OP, documentID: document.documentID, fact: community, headerTitle: title, description: description, singleTopic: nil)
                            
                            if let imageURL = data["imageURL"] as? String {
                                addOn.imageURL = imageURL
                            }
                            if let design = data["design"] as? String {
                                if design == "youTubePlaylist" {
                                    addOn.design = .youTubePlaylist
                                }
                                
                                if let playlistURL = data["externalLink"] as? String {
                                    addOn.externalLink = playlistURL
                                }
                            }
                            if let thanksCount = data["thanksCount"] as? Int {
                                addOn.thanksCount = thanksCount
                            }
                            
                            if let itemOrder = data["itemOrder"] as? [String] {
                                addOn.itemOrder = itemOrder
                            }
                            
                            self.optionalInformations.append(addOn)
                            index+=1
                            
                        } else if let documentID = data["linkedFactID"] as? String {    //SingleTopic
                            if let headerTitle = data["headerTitle"] as? String, let description = data["description"] as? String,  let OP = data["OP"] as? String {
                                
                                let singleTopic = Community()
                                singleTopic.id = documentID
                                
                                let addOn = AddOn(style: .singleTopic, OP: OP, documentID: document.documentID, fact: community, headerTitle: headerTitle, description: description, singleTopic: singleTopic)
                                
                                if let itemOrder = data["itemOrder"] as? [String] {
                                    addOn.itemOrder = itemOrder
                                }
                                if let thanksCount = data["thanksCount"] as? Int {
                                    addOn.thanksCount = thanksCount
                                }
                                
                                self.optionalInformations.append(addOn)
                                index+=1
                            }
                        } else if let type = data["type"] as? String, let OP = data["OP"] as? String {
                            if type == "QandA" {

                                let addOn = AddOn(style: .QandA, OP: OP, documentID: document.documentID, fact: community, description: "")
                                self.optionalInformations.append(addOn)
                                index+=1
                            } else {
                                print("Incorrect AddOn Found in document: \(document)")
                                index+=1
                            }
                        } else {
                            print("Incorrect AddOn Found in document: \(document)")
                            index+=1
                        }
                    
                        if index == snapCount {
                            self.collectionView.reloadData()
                        }
                    }
                }
            }
        }
    }
    
    func renewCollectionView() {
        self.optionalInformations.removeAll()
        self.collectionView.reloadData()
        self.getAddOn(community: self.community!)
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {
        case "toAddOnFeedVCSegue":
            if let navVC = segue.destination as? UINavigationController, let feedVC = navVC.topViewController as? AddOnFeedTableViewController, let addOn = sender as? AddOn {
                feedVC.addOn = addOn
            }
        case "toSettingSegue":
            if let vc = segue.destination as? SettingTableViewController, let addOn = sender as? AddOn {
                vc.addOn = addOn
                vc.settingFor = .addOn
            }
        case "toAddAPostItemSegue":
            if let vc = segue.destination as? AddPostTableViewController, let addOn = sender as? AddOn {
                vc.addItemDelegate = self
                vc.addOn = addOn
                if addOn.style == .playlist {
                    vc.playlistTracksOnly = true
                }
            }
        case "newPostSegue":
            if let navCon = segue.destination as? UINavigationController, let newPostVC = navCon.topViewController as? NewPostVC, let addOn = sender as? AddOn {
                newPostVC.comingFromAddOnVC = true
                newPostVC.selectedFact(community: addOn.community, isViewAlreadyLoaded: false)
                newPostVC.addItemDelegate = self
                newPostVC.addOn = addOn
            }
        case "toPostSegue":
            if let vc = segue.destination as? PostViewController, let post = sender as? Post {
                vc.post = post
            }
        case "toTopicsSegue":
            if let vc = segue.destination as? CommunityCollectionVC, let addOn = sender as? AddOn {
                vc.addOn = addOn
                vc.addFactToPost = .optInfo
                vc.navigationItem.hidesSearchBarWhenScrolling = false
                vc.addItemDelegate = self
            }
        case "toNewAddOnSegue":
            if let vc = segue.destination as? NewAddOnTableViewController, let community = sender as? Community {
                vc.community = community
                vc.delegate = self
            }
        case "toFactSegue":
            if let vc = segue.destination as? CommunityPageVC, let community = sender as? Community {
                vc.community = community
            }
        default:
            break
        }
    }
    
    //MARK:- ScrollView Delegate
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let offset = scrollView.contentOffset.y
        self.pageViewHeaderDelegate?.childScrollViewScrolled(offset: offset)
    }
    
    // MARK: - UICollectionView
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        if noOptionalInformation {
            return self.optionalInformationProposals.count
        } else {
            return self.optionalInformations.count
        }
    }
    
    
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if noOptionalInformation {
            let proposal = optionalInformationProposals[indexPath.item]
            
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: proposalCellIdentifier, for: indexPath) as? AddOnProposalCell {
                cell.proposal = proposal
                
                return cell
            }
        } else {
            
            let info = optionalInformations[indexPath.item]
            
            switch info.style {
            case .singleTopic:
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: singleCommunityCellIdentifier, for: indexPath) as? AddOnSingleCommunityCollectionViewCell {
                    
                    cell.info = info
                    
                    return cell
                }
            case .QandA:
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: qAndACellIdentifier, for: indexPath) as? AddOnQAndACollectionViewCell {
                    
                    cell.info = info
                    
                    return cell
                }
            case .playlist:
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: playlistCellIdentifier, for: indexPath) as? AddOnPlaylistCollectionViewCell {
                    
                    cell.delegate = self
                    cell.info = info
                    
                    return cell
                }
            default:
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: horizontalScrollCellIdentifier, for: indexPath) as? AddOnHorizontalScrollCollectionViewCell {
                    
                    cell.delegate = self
                    cell.addOn = info
                    cell.itemRow = indexPath.item
                    
                    return cell
                }
            }
        }
        
        return UICollectionViewCell()
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let info = optionalInformations[indexPath.item]
        
        if info.style == .collection {
            performSegue(withIdentifier: "toAddOnFeedVCSegue", sender: info)
        } else if info.style == .singleTopic {
            if let community = info.singleTopic {
                performSegue(withIdentifier: "toFactSegue", sender: community)
            }
        } else if info.style == .QandA {
            if let cell = collectionView.cellForItem(at: indexPath) as? AddOnQAndACollectionViewCell {
                cell.cancelTextFieldFirstResponder()
            }
        }
    }
    
    //MARK: - CollectionView Flow Layout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = self.collectionView.frame.width - collectionViewInsetsLeftAndRight
        
        if noOptionalInformation {
            let proposal = optionalInformationProposals[indexPath.row]
            
            if proposal.isFirstCell {
                return CGSize(width: width, height: 100)
            } else {
                return CGSize(width: width, height: 75)
            }
        } else {
            let addOn = optionalInformations[indexPath.item]
            let newSize: CGSize!
            
            if addOn.style == .singleTopic {
                return CGSize(width: width, height: 425)
            } else if addOn.style == .QandA {
                return CGSize(width: width, height: 500)
            } else if addOn.style == .playlist {
                return CGSize(width: width, height: 750)
            }
            
            //normal horizontalScrollAddOn
            if let _ = addOn.imageURL {
                newSize = CGSize(width: width, height: 500)
            } else {
                if addOn.design == .youTubePlaylist {
                    newSize = CGSize(width: width, height: 450)
                } else {
                    newSize = CGSize(width: width, height: 400)
                }
            }
            
            return newSize
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if noOptionalInformation {
            return 10
        } else {
            return 40
        }
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionView.elementKindSectionFooter {
            if let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: footerViewIdentifier, for: indexPath) as? AddOnCollectionViewFooter {
                view.delegate = self
                
                return view
            }
        }
        
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        
        return CGSize(width: collectionView.frame.width - collectionViewInsetsLeftAndRight, height: 50)
    }
}

//MARK: - AddOnCell Delegate, AddOnFooterDelegate

extension AddOnCollectionViewController: AddOnCellDelegate, AddOnFooterViewDelegate {
    
    func goToAddOnStore() {
        if let community = community {
            performSegue(withIdentifier: "toNewAddOnSegue", sender: community)
        }
    }
    
    
    func linkTapped(link: String) {
        if let url = URL(string: link) {
            UIApplication.shared.open(url)
        }
    }
    
    func showDescription() {
        collectionView.performBatchUpdates({
            print("Update collection to show new Height of descriptionLabel")
        }) { (_) in
            print("Updated")
        }
    }
    
    func settingsTapped(itemRow: Int) {
        let info = optionalInformations[itemRow]
        performSegue(withIdentifier: "toSettingSegue", sender: info)
    }
    
    func thanksTapped(info: AddOn) {
        guard AuthenticationManager.shared.isLoggedIn, let community = community, let communityID = community.id, info.documentID != "" else {
            if AuthenticationManager.shared.isLoggedIn {
                self.notLoggedInAlert()
            }
            
            return
        }
        
        let addOnReference = FirestoreCollectionReference(document: communityID, collection: "addOns")
        let reference = FirestoreReference.documentRef(.communities, documentID: info.documentID, collectionReferences: addOnReference)
        
        
        let thanksCount = info.thanksCount ?? 1
        
        reference.updateData(["thanksCount": thanksCount]) { (err) in
            if let error = err {
                print("We have an error liking this addOn: \(error.localizedDescription)")
            } else {
                print("Successfully liked this addOn")
            }
        }
    }
    
    func itemTapped(item: Any) {
        if let post = item as? Post {
            performSegue(withIdentifier: "toPostSegue", sender: post)
        } else if let fact = item as? Community {
            performSegue(withIdentifier: "toFactSegue", sender: fact)
        } else {
            print("Unknown item")
        }
    }
    
    func newPostTapped(addOn: AddOn) {   //New Item tapped inside an addOn
        guard AuthenticationManager.shared.isLoggedIn else {
            self.notLoggedInAlert()
            return
        }
        
        
        let alert = UIAlertController(title: NSLocalizedString("addOn_newItem_alert_title", comment: "add an item"), message: NSLocalizedString("addOn_newItem_alert_message", comment: "what do you want to add?"), preferredStyle: .actionSheet)
        
        let addExistingPostAction = UIAlertAction(title: NSLocalizedString("addOn_newItem_alert_oldPost", comment: "already existent"), style: .default, handler: { (_) in  //choose existing post
            self.performSegue(withIdentifier: "toAddAPostItemSegue", sender: addOn)
        })
        
        let addNewTopicPostAction = UIAlertAction(title: NSLocalizedString("addOn_newItem_alert_newPost", comment: "new Post (community)"), style: .default, handler: { (_) in //create a new topicPost
            self.performSegue(withIdentifier: "newPostSegue", sender: addOn)
        })
        
        let addTopicAction = UIAlertAction(title: NSLocalizedString("addOn_newItem_alert_topic", comment: "community/discussion"), style: .default, handler: { (_) in    //add community or discussion
            
            self.performSegue(withIdentifier: "toTopicsSegue", sender: addOn)
            
        })
        
        switch addOn.style {
        case .playlist:
            alert.addAction(addExistingPostAction)
        default:
            alert.addAction(addExistingPostAction)
            alert.addAction(addNewTopicPostAction)
            alert.addAction(addTopicAction)
        }
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: "cancel"), style: .cancel, handler: { (_) in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
}

//MARK:- AddItem Delegate
extension AddOnCollectionViewController: AddItemDelegate, NewFactDelegate {
    func itemAdded() {
        self.renewCollectionView()
    }
    
    func finishedCreatingNewInstance(item: Any?) {
        renewCollectionView()
    }
}
