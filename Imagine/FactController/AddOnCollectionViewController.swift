//
//  AddOnCollectionViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 27.08.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

class AddOnCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    let db = Firestore.firestore()
    let horizontalScrollCellIdentifier = "AddOnHorizontalScrollCell"
    let singleCommunityCellIdentifier = "SingleCommunityCollectionViewCell"
    let proposalCellIdentifier = "AddOnProposalCell"
    let footerViewIdentifier = "AddOnCollectionViewFooter"
    
    var optionalInformations = [OptionalInformation]()
    
    var noOptionalInformation = false
    var optionalInformationProposals = [ProposalForOptionalInformation(isFirstCell: true, headerText: "Erweitere die Community", detailText: "Hier findest du verschiedene Erweiterungen, um eine Community besser zu repräsentieren und zusätzliche Informationen übersichtlich darzustellen."), ProposalForOptionalInformation(isFirstCell: false, headerText: "Was kann ich tun?", detailText: "Wie kann ein Jeder das Problem der Community bekämpfen oder verbessern?"),  ProposalForOptionalInformation(isFirstCell: false, headerText: "Top-News", detailText: "Übersichtlich die neuesten Nachrichten zu der Community an einem Ort finden."), ProposalForOptionalInformation(isFirstCell: false, headerText: "Beginners Guide", detailText: "Erste Schritte für interessierte Neulinge die tiefer in dieses Thema eintauchen möchten.")]
    
    var addOnDocumentID: String?
    
    var addOnHeader: AddOnHeader?
    
    var pageViewHeaderDelegate: PageViewHeaderDelegate?
    
    let collectionViewInsetsLeftAndRight: CGFloat = 40
    
    var fact: Fact? {
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

        let newHeight: CGFloat = 260
        collectionView.contentInset = UIEdgeInsets(top: newHeight, left: 0, bottom: 0, right: 0)
        collectionView.contentOffset = CGPoint(x: 0, y: -newHeight)
        
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            //If you are looking for the reason, the layout is wrong, it is because of the auto resizing option in storyboard collectionview
            flowLayout.scrollDirection = .vertical
        }
    }
    
    //MARK:- Get Data
    func getData(fact: Fact) {
        let ref = db.collection("Facts").document(fact.documentID).collection("addOns").order(by: "popularity", descending: true)
        
        
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
                    
                    for document in snap.documents {
                        let data = document.data()
                        
                        if let title = data["title"] as? String, let OP = data["OP"] as? String, let description = data["description"] as? String { //Normal collection
                            let addOn = OptionalInformation(style: .collection, OP: OP, documentID: document.documentID, fact: fact, headerTitle: title, description: description, singleTopic: nil)
                            
                            if let imageURL = data["imageURL"] as? String {
                                addOn.imageURL = imageURL
                            }
                            if let thanksCount = data["thanksCount"] as? Int {
                                addOn.thanksCount = thanksCount
                            }
                            
                            if let itemOrder = data["itemOrder"] as? [String] {
                                addOn.itemOrder = itemOrder
                            }
                            
                            self.optionalInformations.append(addOn)
                            
                        } else if let documentID = data["linkedFactID"] as? String {    //SingleTopic
                            if let headerTitle = data["headerTitle"] as? String, let description = data["description"] as? String,  let OP = data["OP"] as? String {
                                
                                let singleTopic = Fact()
                                singleTopic.documentID = documentID
                                
                                let addOn = OptionalInformation(style: .singleTopic, OP: OP, documentID: document.documentID, fact: fact, headerTitle: headerTitle, description: description, singleTopic: singleTopic)
                                
                                if let itemOrder = data["itemOrder"] as? [String] {
                                    addOn.itemOrder = itemOrder
                                }
                                if let thanksCount = data["thanksCount"] as? Int {
                                    addOn.thanksCount = thanksCount
                                }
                                
                                self.optionalInformations.append(addOn)
                            }
                        }
                    
                        
                        self.collectionView.reloadData()
                    }
                }
            }
        }
    }
    
    //MARK: - Save Data (Item)
    
    func saveItemInAddOn(item: Any) {
        
        guard let addOnRef = addOnDocumentID else {
            print("Error: No addOnDocumentID in AddOnVC")
            return
        }
        
        var itemTypeString = "post"
        var addOnTitle: String?
        var displayOption: String?
        var itemID = ""
        
        if let fact = item as? Fact {
            itemTypeString = "fact"
            itemID = fact.documentID
            let newFactVC = NewCommunityItemTableViewController()
            displayOption = newFactVC.getNewFactDisplayString(displayOption: fact.displayOption).displayOption
        } else if let post = item as? Post {
            itemID = post.documentID
            if let title = post.addOnTitle {    // Description of the added post
                addOnTitle = title
            }
            if post.isTopicPost {
                itemTypeString = "topicPost"    // So the getData method looks in a different ref
                self.updateTopicPostInFact(addOnID: addOnRef, postDocumentID: itemID)
            }
        } else {
            print("Dont got an item ID")
            return
        }
        
        
        
        let ref = db.collection("Facts").document(fact!.documentID).collection("addOns").document(addOnRef).collection("items").document(itemID)
        let user = Auth.auth().currentUser!
        
        var data: [String: Any] = ["type": itemTypeString, "OP": user.uid, "createDate": Timestamp(date: Date())]
        if let title = addOnTitle {
            data["title"] = title
        }
        if let mode = displayOption {
            data["displayOption"] = mode
        }
        ref.setData(data) { (err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                let alert = UIAlertController(title: "Fertig", message: "Das AddOn wurde erweitert. Vielen Dank für deinen Beitrag!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                    
                    let docRef = self.db.collection("Facts").document(self.fact!.documentID).collection("addOns").document(addOnRef)
                    self.checkIfOrderArrayExists(documentReference: docRef, documentIDOfItem: itemID)
                    
                    alert.dismiss(animated: true, completion: nil)
                }))
                
                self.present(alert, animated: true)
            }
        }
    }
    
    func checkIfOrderArrayExists(documentReference: DocumentReference, documentIDOfItem: String) {
        documentReference.getDocument { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap {
                    if let data = snap.data() {
                        if let array = data["itemOrder"] as? [String] {
                            self.updateOrderArray(documentReference: documentReference, documentIDOfItem: documentIDOfItem, array: array)
                        } else {
                            self.renewCollectionView()
                            print("No itemOrder yet")
                            return
                        }
                    }
                }
            }
        }
    }
    
    func updateOrderArray(documentReference: DocumentReference, documentIDOfItem: String, array: [String]) {
        var newArray = array
        newArray.insert(documentIDOfItem, at: 0)
        documentReference.updateData([
            "itemOrder": newArray
        ]) { (err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                self.renewCollectionView()
            }
        }
    }
    
    func renewCollectionView() {
        self.optionalInformations.removeAll()
        self.collectionView.reloadData()
        self.getData(fact: self.fact!)
    }
    
    func updateTopicPostInFact(addOnID: String, postDocumentID: String) {       //Add the AddOnDocumentIDs to the fact, so we can delete every trace of the post if you choose to delete it later. Otherwise there would be empty post in an AddOn
        let ref = db.collection("Facts").document(fact!.documentID).collection("posts").document(postDocumentID)
        
        ref.updateData([
            "addOnDocumentIDs": FieldValue.arrayUnion([addOnID])
        ])
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
                    vc.addItemDelegate = self
                    
                    if let fact = self.fact {
                        vc.fact = fact
                }
            }
        }
        if segue.identifier == "newPostSegue" {
            if let navCon = segue.destination as? UINavigationController {
                if let newPostVC = navCon.topViewController as? NewPostViewController {
                    newPostVC.comingFromAddOnVC = true
                    newPostVC.selectedFact(fact: self.fact!, isViewAlreadyLoaded: false)
                    newPostVC.addItemDelegate = self
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
            if let vc = segue.destination as? FactCollectionViewController {
                vc.addFactToPost = .optInfo
                vc.navigationItem.hidesSearchBarWhenScrolling = false
                vc.addItemDelegate = self
            }
        }
        if segue.identifier == "toNewAddOnSegue" {
            if let vc = segue.destination as? NewAddOnTableViewController {
                if let fact = sender as? Fact {
                    vc.fact = fact
                    vc.delegate = self
                }
            }
        }
        if segue.identifier == "toFactSegue" {
            if let vc = segue.destination as? ArgumentPageViewController {
                if let fact = sender as? Fact {
                    vc.fact = fact
                }
            }
        }
    }
    
    //MARK: ScrollView
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
            case .collection:
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
            let item = optionalInformations[indexPath.item]
            let newSize: CGSize!
            
            if item.style == .singleTopic {
                return CGSize(width: width, height: 425)
            }
            if let _ = item.imageURL {
                newSize = CGSize(width: width, height: 500)
            } else {
                newSize = CGSize(width: width, height: 400)
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
    
    func openAfterLongTap(itemRow: Int) {
        let info = optionalInformations[itemRow]
        performSegue(withIdentifier: "toAddOnFeedVCSegue", sender: info)
    }
    
    func thanksTapped(info: OptionalInformation) {
        if let _ = Auth.auth().currentUser {
            if let fact = fact, info.documentID != "" {
                let ref = db.collection("Facts").document(fact.documentID).collection("addOns").document(info.documentID)
                
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
        } else if let fact = item as? Fact {
            performSegue(withIdentifier: "toFactSegue", sender: fact)
        } else {
            print("Unknown item")
        }
    }
    
    func newPostTapped(addOnDocumentID: String) {
        if let _ = Auth.auth().currentUser {
                    
                    self.addOnDocumentID = addOnDocumentID  // Set the documentID for the addOn where "new Post" was tapped, later to be used when the item is saved in the addOn- New or old iteme
                    
                    let alert = UIAlertController(title: "Füge ein Item hinzu", message: "Möchtest du einen Beitrag oder ein Thema zu diesem AddOn hinzufügen?", preferredStyle: .actionSheet)
                    
                    alert.addAction(UIAlertAction(title: "Vorhandener Beitrag", style: .default, handler: { (_) in
                        self.performSegue(withIdentifier: "toAddAPostItemSegue", sender: nil)
                    }))
                    alert.addAction(UIAlertAction(title: "Neuer Beitrag (Nur im Thema)", style: .default, handler: { (_) in
                        self.performSegue(withIdentifier: "newPostSegue", sender: nil)
        //                self.performSegue(withIdentifier: "test", sender: addOnDocumentID)
                    }))
                    alert.addAction(UIAlertAction(title: "Thema/Diskussion", style: .default, handler: { (_) in
                        
                        self.performSegue(withIdentifier: "toTopicsSegue", sender: nil)
                        
                    }))
                    alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel, handler: { (_) in
                        self.addOnDocumentID = nil
                        alert.dismiss(animated: true, completion: nil)
                    }))
                    self.present(alert, animated: true, completion: nil)
                    
                } else {
                    self.notLoggedInAlert()
                }
    }
    
}

extension AddOnCollectionViewController: AddItemDelegate, NewFactDelegate {
    func finishedCreatingNewInstance(item: Any?) {
        renewCollectionView()
    }
    
    func itemSelected(item: Any) {
        saveItemInAddOn(item: item)// Should it be possible to add an title to your new topicPost?
    }
}
