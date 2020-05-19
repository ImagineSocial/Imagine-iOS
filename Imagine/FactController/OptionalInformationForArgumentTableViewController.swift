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
    
    var feedSection: FeedSection?
    var feedSectionData = [FeedSection]()
    
    var fact: Fact? {
        didSet {
            getData(fact: fact!)
        }
    }
    
    var noOptionalInformation = false
    var optionalInformationProposals = [ProposalForOptionalInformation(isFirstCell: true, headerText: "", detailText: ""), ProposalForOptionalInformation(isFirstCell: false, headerText: "Wer ist daran Schuld?", detailText: "In objektiven Diskussionen kann der Einfluss von Firmen & Einzelpersonen auf das Thema diskutiert werden"), ProposalForOptionalInformation(isFirstCell: false, headerText: "Was kann ich tun?", detailText: "Beschreibungen und Beiträge zu einfachen Mitteln für Jedermann, wie man das Problem des Themas bekämpfen/verbessern kann"),  ProposalForOptionalInformation(isFirstCell: false, headerText: "Top-News", detailText: "Übersichtlich die neuesten Nachrichten über das Thema an einem Ort finden."), ProposalForOptionalInformation(isFirstCell: false, headerText: "Beginners Guide", detailText: "Erste Schritte für interessierte Neulinge die tiefer in dieses Thema eintauchen möchten")]
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
                        
                        if let title = data["title"] as? String, let description = data["description"] as? String {
                            let addOn = OptionalInformation(style: .all, headerTitle: title, description: description, documentID: document.documentID, fact: self.fact!)
                            addOn.style = .all
                            self.optionalInformations.append(addOn)
                            
                        } else if let description = data["headerDescription"] as? String {
                            var intro: String?
                            var source: String?
                            if let introSentence = data["headerIntro"] as? String {
                                intro = introSentence
                            }
                            if let moreInfo = data["moreInformationLink"] as? String {
                                source = moreInfo
                            }
                            
                            let addOn = OptionalInformation(style: .header ,introSentence: intro, description: description, moreInformationLink: source)
                            addOn.style = .header
                            self.optionalInformations.insert(addOn, at: 0)  // Should be on top of the vc
                        } else if let documentID = data["linkedFactID"] as? String {
                            if let headerTitle = data["headerTitle"] as? String, let description = data["description"] as? String {
                                let addOn = OptionalInformation(style: .singleTopic, headerTitle: headerTitle, description: description, factDocumentID: documentID)
                                
                                print("Adde die info")
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
                if let fact = optInfo.fact {
                    performSegue(withIdentifier: "toFactSegue", sender: fact)
                }
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
                    
                    let info = optionalInformations[section]
                    
                    headerView.info = info
                    headerView.section = section
                    
                    headerView.delegate = self
                    
                    return headerView
                }
                
                
//                let headerView = AddOnHeaderView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 40))
//
//                let info = optionalInformations[section]
//                headerView.initHeader(noOptionalInformation: noOptionalInformation, info: info)
//                headerView.delegate = self
//                return headerView
            }
        }
        print("Return nil")
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
                //40
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
                return UITableView.automaticDimension
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
                return 290
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
            let newFactVC = NewFactViewController()
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
                    
                    self.optionalInformations.removeAll()
                    self.tableView.reloadData()
                    self.getData(fact: self.fact!)
                    
                    alert.dismiss(animated: true, completion: nil)
                }))
                
                self.present(alert, animated: true)
            }
        }
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
                vc.searchController.isActive = true
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
                    
                    print("Das ist der Fakt den ich übergebe: \(fact.title), fact type: \(fact.displayOption)")
                    if fact.displayOption == .topic {
                        vc.displayMode = .topic
                    }
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
        self.feedSection = nil
        
        if let feedSection = self.feedSectionData.first(where: {$0.section == section}) {
            self.feedSection = feedSection
            self.tableView.reloadData()
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
