//
//  OptionalInformationForArgumentTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 05.03.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase
import EasyTipView

enum AddOnType {
    case normal
    case justPosts
    case justFacts
    case intro
    case steps
}

class FeedSection {
    var section: Int
    var posts: [Post]
    
    init(section: Int, posts: [Post]) {
        self.section = section
        self.posts = posts
    }
}

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

class OptionalInformationForArgumentTableViewController: UITableViewController {
    
    var optionalInformations = [OptionalInformation]()
    var addOnDocumentID: String?
    
    let db = Firestore.firestore()
    let handyHelper = HandyHelper()
    
    var feedSection: FeedSection?
    var feedSectionData = [FeedSection]()
    
    var fact: Fact? {
        didSet {
            getData(fact: fact!)
        }
    }
    
    var noOptionalInformation = false
    var optionalInformationProposals = [ProposalForOptionalInformation(isFirstCell: true, headerText: "", detailText: ""), ProposalForOptionalInformation(isFirstCell: false, headerText: NSLocalizedString("proposal_header_guilty", comment: "who is guilty?"), detailText: NSLocalizedString("proposal_detail_guilty", comment: "discuss about who is guilty for example")), ProposalForOptionalInformation(isFirstCell: false, headerText: "Was kann ich tun?", detailText: "Beschreibungen und Beiträge zu einfachen Mitteln für Jedermann, wie man das Problem des Themas bekämpfen/verbessern kann"),  ProposalForOptionalInformation(isFirstCell: false, headerText: "Top-News", detailText: "Übersichtlich die neuesten Nachrichten über das Thema an einem Ort finden."), ProposalForOptionalInformation(isFirstCell: false, headerText: "Beginners Guide", detailText: "Erste Schritte für interessierte Neulinge die tiefer in dieses Thema eintauchen möchten")]
    //ProposalForOptionalInformation(isFirstCell: false, headerText: "Wen sollte ich meiden?", detailText: "Eine übersichtliche Ansammlung von Firmen die du meiden könntest um das Problem des Themas zu entlasten"),
    let diyString = "Was kann ich tun?"
    let avoidString = "Wen sollte ich meiden?"
    let guiltyString = "Wer ist daran Schuld?"
    
    let reuseIdentifier = "CollectionViewInTableViewCell"
    let proposalCellIdentifier = "ProposalCell"
    let addSectionReuseIdentifier = "AddSectionCell"
    let infoHeaderReuseIdentifier = "InfoHeaderAddOnCell"
    let singleTopicReuseIdentifier = "SingleTopicAddOnCell"
    
    let addOnHeaderIdentifier = "AddOnHeaderView"
    let postCellIdentifier = "NibPostCell"
    
    let addPostVC = AddPostTableViewController()
    
    var tipView: EasyTipView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if noOptionalInformation {
            self.exampleButton.isHidden = true
        }
        
        Analytics.logEvent("AddOnVCOpened", parameters: [
            AnalyticsParameterTerm: ""
        ])
        
        tableView.register(UINib(nibName: "CollectionViewInTableViewCell", bundle: nil), forCellReuseIdentifier: reuseIdentifier)
        tableView.register(ProposalCell.self, forCellReuseIdentifier: proposalCellIdentifier)
        tableView.register(AddFactCell.self, forCellReuseIdentifier: addSectionReuseIdentifier)
        tableView.register(UINib(nibName: "InfoHeaderAddOnCell", bundle: nil), forCellReuseIdentifier: infoHeaderReuseIdentifier)
        tableView.register(UINib(nibName: "SingleTopicAddOnCell", bundle: nil), forCellReuseIdentifier: singleTopicReuseIdentifier)
        tableView.separatorColor = .clear
        tableView.register(UINib(nibName: "AddOnHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: addOnHeaderIdentifier)
        
        tableView.register(UINib(nibName: "PostTableViewCell", bundle: nil), forCellReuseIdentifier: postCellIdentifier)
        
        self.tableView.estimatedSectionHeaderHeight = 50
        
        let layer = addSectionButton.layer
        layer.cornerRadius = 6
        if #available(iOS 13.0, *) {
            layer.borderColor = UIColor.label.cgColor
        } else {
            layer.borderColor = UIColor.black.cgColor
        }
        layer.borderWidth = 0.75
        
        exampleButton.imageView?.contentMode = .scaleAspectFit
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let tipView = tipView {
            tipView.dismiss()
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
                        self.tableView.reloadData()
                        
                        return
                    } else {
                        self.noOptionalInformation = false  // Need to add this here so it can update the view after the creation of a new addOn
                    }
                    
                    for document in snap.documents {
                        let data = document.data()
                        
                        if let title = data["title"] as? String, let OP = data["OP"] as? String, let description = data["description"] as? String { //Normal collection
                            let addOn = OptionalInformation(style: .all, OP: OP, documentID: document.documentID, fact: fact, headerTitle: title, description: description, singleTopic: nil)
                            
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
                            
                        } else if let description = data["headerDescription"] as? String, let OP = data["OP"] as? String, let headerImage = data["imageURL"] as? String {  // Header
                            var intro: String?
                            var source: String?
                            
                            if let introSentence = data["headerIntro"] as? String {
                                intro = introSentence
                            }
                            if let moreInfo = data["moreInformationLink"] as? String {
                                source = moreInfo
                            }
                            
                            let addOn = OptionalInformation(style: .header, OP: OP, documentID: document.documentID, fact: fact, imageURL: headerImage ,introSentence: intro, description: description, moreInformationLink: source)
                            
                            self.optionalInformations.insert(addOn, at: 0)  // Should be on top of the vc
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
                    
                        
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        if noOptionalInformation {
            return 1
        } else {
            return optionalInformations.count
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
        if let feedSection = feedSection {
            if section == feedSection.section {
                return feedSection.posts.count
            }
        }
        if noOptionalInformation {
            return optionalInformationProposals.count
        } else {
            return 1
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if noOptionalInformation {
            let proposal = optionalInformationProposals[indexPath.row]
            
            if proposal.isFirstCell {
                let cell = UITableViewCell(style: .default, reuseIdentifier: "FirstCell")
                cell.textLabel!.text = "Füge einen passenden Bereich für dieses Thema hinzu, um es besser zu repräsentieren, für andere schnell Verständlich zu machen oder lass deiner Fantasie einfach freien lauf.\nEin paar Vorschläge:"
                cell.textLabel?.font = UIFont(name: "IBMPlexSans", size: 15)
                cell.contentView.backgroundColor = .clear
                cell.backgroundColor = .clear
                cell.textLabel?.numberOfLines = 0
                
                return cell
            } else {
                if let cell = tableView.dequeueReusableCell(withIdentifier: proposalCellIdentifier, for: indexPath) as? ProposalCell {
                    cell.textLabel!.text = proposal.headerText
                    cell.detailTextLabel!.text = proposal.detailText
                    cell.imageView?.image = UIImage(named: "about")
                    
                    return cell
                }
            }
        } else {
            
            if let feedSection = feedSection {
                if feedSection.section == indexPath.section {
                    
                    let post = feedSection.posts[indexPath.row]
                                        
                    if let cell = tableView.dequeueReusableCell(withIdentifier: postCellIdentifier, for: indexPath) as? PostCell {
                        
                        cell.post = post
                        
                        return cell
                    }
                }
            }
            
            let info = optionalInformations[indexPath.section]
            
            
            switch info.style {
                case .header:
                    if let addOnHeader = info.addOnInfoHeader {
                        if let cell = tableView.dequeueReusableCell(withIdentifier: infoHeaderReuseIdentifier, for: indexPath) as? InfoHeaderAddOnCell {
                            cell.addOnInfo = addOnHeader
                            cell.delegate = self
                            
                            return cell
                        }
                    }
                    
                case .singleTopic:
                    if let cell = tableView.dequeueReusableCell(withIdentifier: singleTopicReuseIdentifier, for: indexPath) as? SingleTopicAddOnCell {
                        
                        cell.info = info
                        
                        return cell
                    }
                default:
                    if let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? CollectionViewInTableViewCell {
                        
                        // if whatever { cell.isPagingEnabled = true
                        cell.section = indexPath.section
                        cell.info = info
                        cell.delegate = self
                        
                        return cell
                    }
                }
        }
        
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !noOptionalInformation {
            let optInfo = optionalInformations[indexPath.section]
            
            if optInfo.style == .singleTopic {
                performSegue(withIdentifier: "toFactSegue", sender: optInfo.fact)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if !noOptionalInformation {
            let optInfo = optionalInformations[section]
            
            if let _ = optInfo.addOnInfoHeader {
                return nil
            } else {
                if let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: addOnHeaderIdentifier) as? AddOnHeaderView {
                    
                    headerView.info = optInfo
                    headerView.section = section
                    
                    headerView.delegate = self
                    
                    return headerView
                }
            }
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        let footerIdentifier = "FooterView"
        
        if let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: footerIdentifier) as? OptionalInfoFooterView {
                        
            return view
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if !noOptionalInformation {
            let optInfo = optionalInformations[section]
            
            if let _ = optInfo.addOnInfoHeader {
                return 0
            } else {
                return UITableView.automaticDimension
            }
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if let feedSection = feedSection {
            if feedSection.section == indexPath.section {
                
                let post = feedSection.posts[indexPath.item]
                if post.type == .picture {
                    
                    let labelHeight = handyHelper.setLabelHeight(titleCount: post.title.count)
                    
                    let imageHeight = post.mediaHeight
                    let imageWidth = post.mediaWidth
                    
                    let ratio = imageWidth / imageHeight
                    let width = self.view.frame.width-20  // 5+5 from contentView and 5+5 from inset
                    var newHeight = width / ratio
                    
                    if newHeight >= 500 {
                        newHeight = 500
                    }
                    
                    return newHeight+100+labelHeight // 105 weil Höhe von StackView & Rest
                    
                
                } else {
                    return UITableView.automaticDimension
                }
            }
        }
        
        if noOptionalInformation {
            return UITableView.automaticDimension
        } else {
            let info = optionalInformations[indexPath.section]
            switch info.style {
            case .header:
                return UITableView.automaticDimension
            case .singleTopic:
                return UITableView.automaticDimension
            default:
                return 300
            }
        }
        
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if noOptionalInformation {
            
            return 50
        } else {
            if section == optionalInformations.count {
                return 50
            } else {
                return 0
            }
        }
    }
    
    //MARK: - Save Item
    
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
                            self.renewTableView()
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
                self.renewTableView()
            }
        }
    }
    
    func renewTableView() {
        self.optionalInformations.removeAll()
        self.tableView.reloadData()
        self.getData(fact: self.fact!)
    }
    
    func updateTopicPostInFact(addOnID: String, postDocumentID: String) {       //Add the AddOnDocumentIDs to the fact, so we can delete every trace of the post if you choose to delete it later. Otherwise there would be empty post in an AddOn
        let ref = db.collection("Facts").document(fact!.documentID).collection("posts").document(postDocumentID)
        
        ref.updateData([
            "addOnDocumentIDs": FieldValue.arrayUnion([addOnID])
        ])
    }
    
    //MARK:-PrepareForSegue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toTopicsSegue" {
            if let vc = segue.destination as? FactCollectionViewController {
                vc.addFactToPost = .optInfo
                vc.navigationItem.hidesSearchBarWhenScrolling = false
                vc.addItemDelegate = self
            }
        }
        
        if segue.identifier == "toPostSegue" {
            if let vc = segue.destination as? PostViewController {
                if let post = sender as? Post {
                    vc.post = post
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
        
        if segue.identifier == "newPostSegue" {
            if let navCon = segue.destination as? UINavigationController {
                if let newPostVC = navCon.topViewController as? NewPostViewController {
                    print("Going to newPostSegue")
                    newPostVC.comingFromAddOnVC = true
                    newPostVC.selectedFact(fact: self.fact!, isViewAlreadyLoaded: false)
                    newPostVC.addItemDelegate = self
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
        if segue.identifier == "toNewAddOnSegue" {
            if let vc = segue.destination as? NewAddOnTableViewController {
                if let fact = sender as? Fact {
                    vc.fact = fact
                    vc.delegate = self
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
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let tipView = tipView {
            tipView.dismiss()
        }
    }
    
    //MARK:-FooterView
    
    @IBAction func exampleButtonInFooterTapped(_ sender: Any) {
        if noOptionalInformation {
            self.exampleButton.setImage(UIImage(named: "about"), for: .normal)
            self.noOptionalInformation = false
            self.tableView.reloadData()
        } else {
            self.exampleButton.setImage(UIImage(named: "greenTik"), for: .normal)
            self.noOptionalInformation = true
            self.tableView.reloadData()
        }
    }
        
    @IBAction func addSectionTapped(_ sender: Any) {
        if let fact = fact {
            performSegue(withIdentifier: "toNewAddOnSegue", sender: fact)
        }
    }
    
    @IBOutlet weak var footerViewPickerView: UIPickerView!
    @IBOutlet weak var exampleButton: DesignableButton!
    @IBOutlet weak var addSectionButton: DesignableButton!
    
}

extension OptionalInformationForArgumentTableViewController: AddOnHeaderDelegate, InfoHeaderAddOnCellDelegate {
    
    func settingsTapped(section: Int) {
        let info = optionalInformations[section]
        performSegue(withIdentifier: "toSettingSegue", sender: info)
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
    
    func linkTapped(link: String) {
        if let url = URL(string: link) {
            UIApplication.shared.open(url)
        }
    }
    
    func showDescription() {
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    func showAllPosts(documentID: String) {
        self.alert(message: "Diese funktion muss noch programmiert werden, schreib Imagine ruhig ne Nachricht, dass die sich gefälligst mal beeilen sollen^^")
    }
    
    func showPostsAsAFeed(section: Int) {
        
        if let feedSection = feedSection {
            if feedSection.section == section {
                self.feedSection = nil  //Hide the feedSection
                self.tableView.reloadData()
                
            } else {
                self.showFeedSection(section: section)
            }
        } else {
            //no feed section
            self.showFeedSection(section: section)
        }
    }

        
    
    func showFeedSection(section: Int) {
        if let feedSection = self.feedSectionData.first(where: {$0.section == section}) {
            self.feedSection = feedSection
            let range = NSMakeRange(0, self.tableView.numberOfSections)
            let sections = NSIndexSet(indexesIn: range)
            self.tableView.reloadSections(sections as IndexSet, with: .automatic)
        } else {
           print("Dont have the feedSection Data")
        }
    }
    
}

extension OptionalInformationForArgumentTableViewController: AddItemDelegate, NewFactDelegate {
    func finishedCreatingNewInstance(item: Any?) {
        self.optionalInformations.removeAll()
        self.tableView.reloadData()
        
        self.getData(fact: self.fact!)
    }
    
    
    func itemSelected(item: Any) {
        saveItemInAddOn(item: item)// Should it be possible to add an title to your new topicPost?
    }
}

extension OptionalInformationForArgumentTableViewController: CollectionViewInTableViewCellDelegate {
 
    func saveItems(section: Int, item: Any) {
        
        if let feedSection = self.feedSectionData.first(where: {$0.section == section}) {
            if let post = item as? Post {
                if let _ = feedSection.posts.first(where: {$0.documentID == post.documentID}) {
                    print("Already Got the post")
                } else {
                    feedSection.posts.append(post)
                }
            }
        } else {
            if let post = item as? Post {
                let feedSection = FeedSection(section: section, posts: [post])
                feedSectionData.append(feedSection)
            }
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
    
    func itemTapped(item: Any) {
        if let post = item as? Post {
            performSegue(withIdentifier: "toPostSegue", sender: post)
        } else if let fact = item as? Fact {
            performSegue(withIdentifier: "toFactSegue", sender: fact)
        }
    }
}


class ProposalCell: UITableViewCell {
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        
        textLabel!.font = UIFont(name: "IBMPlexSans", size: 20)
        detailTextLabel!.font = UIFont(name: "IBMPlexSans", size: 14)
        detailTextLabel?.numberOfLines = 0
        
        if #available(iOS 13.0, *) {
            textLabel?.textColor = .label
            detailTextLabel?.textColor = .secondaryLabel
            imageView?.tintColor = .tertiaryLabel
        } else {
            textLabel?.textColor = .black
            detailTextLabel?.textColor = .lightGray
            imageView?.tintColor = .darkGray
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


class OptionalInfoFooterView: UITableViewHeaderFooterView {
    
    
}
