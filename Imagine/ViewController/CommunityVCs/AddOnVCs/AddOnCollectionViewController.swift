//
//  AddOnCollectionViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 27.08.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase
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

    let db = Firestore.firestore()
    let horizontalScrollCellIdentifier = "AddOnHorizontalScrollCell"
    let singleCommunityCellIdentifier = "SingleCommunityCollectionViewCell"
    let proposalCellIdentifier = "AddOnProposalCell"
    let footerViewIdentifier = "AddOnCollectionViewFooter"
    let qAndACellIdentifier = "AddOnQAndACollectionViewCell"
    let playlistCellIdentifier = "AddOnPlaylistCollectionViewCell"
    
    var optionalInformations = [OptionalInformation]()
    
    var noOptionalInformation = false
    var optionalInformationProposals = [ProposalForOptionalInformation(isFirstCell: true, headerText: NSLocalizedString("proposal_header_text", comment: "individualise your community"), detailText: NSLocalizedString("proposal_header_description", comment: "What are addOns")), ProposalForOptionalInformation(isFirstCell: false, headerText: NSLocalizedString("proposal_me_active_header", comment: "What can I do?"), detailText: NSLocalizedString("proposal_me_active_description", comment: "what ca i do to make it better")),  ProposalForOptionalInformation(isFirstCell: false, headerText: "Top-News", detailText: NSLocalizedString("proposal_top_news_description", comment: "top new for visibility")), ProposalForOptionalInformation(isFirstCell: false, headerText: "Beginners Guide", detailText: NSLocalizedString("proposal_beginners_guide_description", comment: "help younglings"))]
        
    var addOnHeader: AddOnHeader?
    
    var pageViewHeaderDelegate: PageViewHeaderDelegate?
    
    let collectionViewInsetsLeftAndRight: CGFloat = 40
    
    var fact: Community? {
        didSet {
            getData(fact: fact!)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Register cell classes
        self.collectionView!.register(UINib(nibName: "AddOnHorizontalScrollCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: horizontalScrollCellIdentifier)
        self.collectionView.register(UINib(nibName: "AddOnSingleCommunityCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: singleCommunityCellIdentifier)
        self.collectionView.register(UINib(nibName: "AddOnCollectionViewFooter", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: footerViewIdentifier)
        self.collectionView.register(UINib(nibName: "AddOnProposalCell", bundle: nil), forCellWithReuseIdentifier: proposalCellIdentifier)
        self.collectionView.register(UINib(nibName: "AddOnQAndACollectionViewCell", bundle: nil), forCellWithReuseIdentifier: qAndACellIdentifier)
        self.collectionView.register(UINib(nibName: "AddOnPlaylistCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: playlistCellIdentifier)

        let newHeight: CGFloat = 260
        collectionView.contentInset = UIEdgeInsets(top: newHeight, left: 0, bottom: 0, right: 0)
        collectionView.contentOffset = CGPoint(x: 0, y: -newHeight)
        collectionView.delaysContentTouches = false
        
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            //If you are looking for the reason, the layout is wrong, it is because of the auto resizing option in storyboard collectionview
            flowLayout.scrollDirection = .vertical
        }
    }
    
    //MARK:- Get Data
    func getData(fact: Community) {
        
        var collectionRef: CollectionReference!
        if fact.language == .english {
            collectionRef = db.collection("Data").document("en").collection("topics")
        } else {
            collectionRef = db.collection("Facts")
        }
        
        let ref = collectionRef.document(fact.documentID).collection("addOns").order(by: "popularity", descending: true)
        
        ref.getDocuments { (snap, err) in
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
                                    let addOn = OptionalInformation(style: .playlist, OP: OP, documentID: document.documentID, fact: fact, headerTitle: title, description: description, singleTopic: nil)
                                    
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
                            let addOn = OptionalInformation(style: .collection, OP: OP, documentID: document.documentID, fact: fact, headerTitle: title, description: description, singleTopic: nil)
                            
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
                                singleTopic.documentID = documentID
                                
                                let addOn = OptionalInformation(style: .singleTopic, OP: OP, documentID: document.documentID, fact: fact, headerTitle: headerTitle, description: description, singleTopic: singleTopic)
                                
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
                                print("Adde QANDA")
                                let addOn = OptionalInformation(style: .QandA, OP: OP, documentID: document.documentID, fact: fact, description: "")
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
        self.getData(fact: self.fact!)
    }
    
    //MARK:- PrepareForSegue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toAddOnFeedVCSegue" {
            if let navVC = segue.destination as? UINavigationController {
                if let feedVC = navVC.topViewController as? AddOnFeedTableViewController {
                    if let addOn = sender as? OptionalInformation {
                        feedVC.addOn = addOn
                    }
                }
            }
        }
        if segue.identifier == "toSettingSegue" {
            if let vc = segue.destination as? SettingTableViewController {
                if let addOn = sender as? OptionalInformation {
                    vc.addOn = addOn
                    vc.settingFor = .addOn
                }
            }
        }
        if segue.identifier == "toAddAPostItemSegue" {
            if let vc = segue.destination as? AddPostTableViewController {
                if let addOn = sender as? OptionalInformation {
                    vc.addItemDelegate = self
                    vc.addOn = addOn
                    if addOn.style == .playlist {
                        vc.playlistTracksOnly = true
                    }
                }
            }
        }
        
        if segue.identifier == "newPostSegue" {
            if let navCon = segue.destination as? UINavigationController {
                if let newPostVC = navCon.topViewController as? NewPostViewController {
                    if let addOn = sender as? OptionalInformation {
                        newPostVC.comingFromAddOnVC = true
                        newPostVC.selectedFact(fact: addOn.fact, isViewAlreadyLoaded: false)
                        newPostVC.addItemDelegate = self
                        newPostVC.addOn = addOn
                    }
                }
            }
        }
        if segue.identifier == "toPostSegue" {
            if let vc = segue.destination as? PostViewController {
                if let post = sender as? Post {
                    vc.post = post
                }
            }
        }
        if segue.identifier == "toTopicsSegue" {
            if let vc = segue.destination as? CommunityCollectionViewController {
                if let addOn = sender as? OptionalInformation {
                    vc.addOn = addOn
                    vc.addFactToPost = .optInfo
                    vc.navigationItem.hidesSearchBarWhenScrolling = false
                    vc.addItemDelegate = self
                }
            }
        }
        if segue.identifier == "toNewAddOnSegue" {
            if let vc = segue.destination as? NewAddOnTableViewController {
                if let fact = sender as? Community {
                    vc.fact = fact
                    vc.delegate = self
                }
            }
        }
        if segue.identifier == "toFactSegue" {
            if let vc = segue.destination as? ArgumentPageViewController {
                if let fact = sender as? Community {
                    vc.fact = fact
                }
            }
        }
    }
    
    //MARK:- ScrollView
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let offset = scrollView.contentOffset.y
        self.pageViewHeaderDelegate?.childScrollViewScrolled(offset: offset)
    }
    
    // MARK:- UICollectionView
    
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
                    cell.info = info
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = self.collectionView.frame.width-collectionViewInsetsLeftAndRight
        
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
        
        return CGSize(width: collectionView.frame.width, height: 50)
    }
}

extension AddOnCollectionViewController: AddOnCellDelegate, AddOnHeaderReusableViewDelegate, AddOnFooterViewDelegate {
    
    func goToAddOnStore() {
        if let community = fact {
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
    
    func thanksTapped(info: OptionalInformation) {
        if let _ = Auth.auth().currentUser {
            if let fact = fact, info.documentID != "" {
                var collectionRef: CollectionReference!
                if fact.language == .english {
                    collectionRef = db.collection("Data").document("en").collection("topics")
                } else {
                    collectionRef = db.collection("Facts")
                }
                let ref = collectionRef.document(fact.documentID).collection("addOns").document(info.documentID)
                
                var thanksCount = 1
                if let count = info.thanksCount {
                    thanksCount = count
                }
                ref.updateData(["thanksCount": thanksCount]) { (err) in
                    if let error = err {
                        print("We have an error liking this addOn: \(error.localizedDescription)")
                    } else {
                        print("Successfully liked this addOn")
                    }
                }
            }
        } else {
            self.notLoggedInAlert()
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
    
    func newPostTapped(addOn: OptionalInformation) {   //New Item tapped inside an addOn
        if let _ = Auth.auth().currentUser {
            
            
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
            
        } else {
            self.notLoggedInAlert()
        }
    }
}

extension AddOnCollectionViewController: AddItemDelegate, NewFactDelegate {
    func itemAdded() {
        self.renewCollectionView()
    }
    
    func finishedCreatingNewInstance(item: Any?) {
        renewCollectionView()
    }
}
