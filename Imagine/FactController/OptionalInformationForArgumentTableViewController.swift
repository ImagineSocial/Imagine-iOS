//
//  OptionalInformationForArgumentTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 05.03.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

enum OptionalInformationType {
    case diy
    case guilty
    case avoid
    case new
}

protocol OptionalInformationDelegate {
    func done()
}

class OptionalInformation {
    
    var headerTitle: String
    var description: String
    var documentID: String
    var fact: Fact
    
    var delegate: OptionalInformationDelegate?
    
    var items = [Any]()
//    var type: OptionalInformationType?
    
    init(headerTitle: String, description: String, documentID: String, fact: Fact) {
        self.description = description
        self.headerTitle = headerTitle
        self.documentID = documentID
        self.fact = fact
    }
    
    func getItems() {
        let ref = Firestore.firestore().collection("Facts").document(fact.documentID).collection("addOns").document(documentID).collection("items")
        
        ref.getDocuments { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap {
                    for document in snap.documents {
                        let data = document.data()
                        guard let type = data["type"] as? String else {
                            return
                        }
                        if type == "fact" {
                            let fact = Fact(addMoreDataCell: false)
                            fact.documentID = document.documentID
                            
                            self.items.append(fact)
                        } else {    // Post
                            let post = Post()
                            post.documentID = document.documentID
                            
                            if let postDescription = data["title"] as? String {
                                post.addOnTitle = postDescription
                            }
                            self.items.append(post)
                        }
                    }
                    self.delegate?.done()
                }
            }
        }
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
    var selectedOption: OptionalInformationType = .diy
    
    var addOnDocumentID: String?
    
    let db = Firestore.firestore()
    
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
    
    let addPostVC = AddPostTableViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if noOptionalInformation {
            self.exampleButton.isHidden = true
        }
        
        tableView.register(UINib(nibName: "CollectionViewInTableViewCell", bundle: nil), forCellReuseIdentifier: reuseIdentifier)
        tableView.register(ProposalCell.self, forCellReuseIdentifier: proposalCellIdentifier)
        tableView.register(AddFactCell.self, forCellReuseIdentifier: addSectionReuseIdentifier)
        tableView.separatorColor = .clear
        
        //FooterView
        let buttons = [addSectionButton, proposeNewSectionButton]
        
        for button in buttons {
            let layer = button!.layer
            layer.cornerRadius = 6
            if #available(iOS 13.0, *) {
                layer.borderColor = UIColor.label.cgColor
            } else {
                layer.borderColor = UIColor.black.cgColor
            }
            layer.borderWidth = 0.75
            
        }
        proposeNewSectionButton.titleLabel?.minimumScaleFactor = 0.5
        proposeNewSectionButton.titleLabel?.numberOfLines = 1
        proposeNewSectionButton.titleLabel?.adjustsFontSizeToFitWidth = true
        proposeNewSectionButton.titleLabel?.lineBreakMode = .byClipping
        
        exampleButton.imageView?.contentMode = .scaleAspectFit
    }
    
    func getData(fact: Fact) {
        let ref = db.collection("Facts").document(fact.documentID).collection("addOns")
        
        
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
                        
                        guard let title = data["title"] as? String, let description = data["description"] as? String else {
                            return
                        }
                        
                        let addOn = OptionalInformation(headerTitle: title, description: description, documentID: document.documentID, fact: self.fact!)
                        
                        self.optionalInformations.append(addOn)
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }

    
//    func getData(fact: Fact) {
//        let ref = db.collection("Facts").document(fact.documentID)
//
//        ref.getDocument { (snap, err) in
//            if let error = err {
//                print("We have an error: \(error.localizedDescription)")
//            } else {
//                if let snap = snap {
//                    if let data = snap.data() {
//                        if let addOns = data["addOnOptions"] as? [String] {
//                            self.loadAddOnOptions(factID: fact.documentID, addOnStrings: addOns)
//                        } else {
//                            self.noOptionalInformation = true
//                            self.tableView.reloadData()
//                        }
//                    }
//                }
//            }
//        }
//    }

//    func loadAddOnOptions(factID: String, addOnStrings: [String]) {
//        if addOnStrings.count == 0 {
//            self.noOptionalInformation = true
//            self.tableView.reloadData()
//
//            return
//        }
//        for string in addOnStrings {
//
//            let ref = db.collection("Facts").document(factID).collection("addOn-\(string)")
//
//            let option = OptionalInformation(type: .diy, headerTitle: "", items: [])
//
//            switch string {
//            case "avoid":
//                option.type = .avoid
//                option.headerTitle = avoidString
//            case "guilty":
//                option.type = .guilty
//                option.headerTitle = guiltyString
//            case "diy":
//                option.type = .diy
//                option.headerTitle = diyString
//            default:
//                option.type = .diy
//                option.headerTitle = diyString
//            }
//
//            ref.getDocuments { (snap, err) in
//                if let error = err {
//                    print("We have an error: \(error.localizedDescription)")
//                } else {
//                    if let snap = snap {
//                        for document in snap.documents {
//
//                            switch option.type {
//                            case .diy:  //For now just posts
//                                    let post = Post()
//                                    post.documentID = document.documentID
//                                    let data = document.data()
//
//                                    if let postDescription = data["postDescription"] as? String {
//                                        post.addOnTitle = postDescription
//                                    }
//
//                                    option.items.append(post)
//
//                            case .avoid:    //For now nothing
//                                print("Avoid is not implemented yet")
//                            case .guilty:
//                                    let fact = Fact(addMoreDataCell: false)
//                                    fact.documentID = document.documentID
//
//                                    option.items.append(fact)
//                            }
//                        }
//
//                        // Cant add Options which are already there:
//
//                        self.pickerOptions = self.pickerOptions.filter{ $0.type != option.type }
//
//                        self.optionalInformations.append(option)
//                        self.tableView.reloadData()
//                    }
//                }
//            }
//
//        }
//    }
    
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
            
            let info = optionalInformations[indexPath.section]
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? CollectionViewInTableViewCell {
                
                cell.info = info
                cell.delegate = self
                
                return cell
            }
        }
        
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 40))
        
        let label = UILabel()
        label.frame = CGRect(x: 10, y: 5, width: headerView.frame.width-10, height: headerView.frame.height-10)
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 22)
        label.minimumScaleFactor = 0.5
        
        headerView.addSubview(label)
        
        if noOptionalInformation {
            label.text = "Erweitere das Thema"
        } else {
            let info = optionalInformations[section]
            label.text = info.headerTitle
        }
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if noOptionalInformation {
            return UITableView.automaticDimension
        } else {
            return 210
//            let info = optionalInformations[indexPath.section]
//            switch info.type {
//            case .diy:
//                return 160
//            case .guilty:
//                return 210
//            case .avoid:
//                return 210
//            }
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        let footerIdentifier = "FooterView"
        
        if let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: footerIdentifier) as? OptionalInfoFooterView {
                        
            return view
        }
        
        return nil
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
        var itemID = ""
        
        if let fact = item as? Fact {
            itemTypeString = "fact"
            itemID = fact.documentID
        } else if let post = item as? Post {
            itemID = post.documentID
            if let title = post.addOnTitle {    // Description of the added post
                addOnTitle = title
            }
        }
        
        let ref = db.collection("Facts").document(fact!.documentID).collection("addOns").document(addOnRef).collection("items").document(itemID)
        let user = Auth.auth().currentUser!
        
        var data: [String: Any] = ["type": itemTypeString, "OP": user.uid, "createDate": Timestamp(date: Date())]
        if let title = addOnTitle {
            data["title"] = title
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
    
    //MARK:-PrepareForSegue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toTopicsSegue" {
            if let vc = segue.destination as? FactCollectionViewController {
                if let type = sender as? OptionalInformationType {
                    vc.optionalInformationType = type
                    vc.addFactToPost = .optInfo
                    vc.navigationItem.hidesSearchBarWhenScrolling = false
                    vc.searchController.isActive = true
                    vc.addItemDelegate = self
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
        
        if segue.identifier == "toFactSegue" {
            if let vc = segue.destination as? ArgumentPageViewController {
                if let fact = sender as? Fact {
                    vc.fact = fact
                    
                    print("Das ist der Fakt den ich übergebe: \(fact.title), fact type: \(fact.displayMode)")
                    if fact.displayMode == .topic {
                        vc.displayMode = .topic
                    }
                }
            }
        }
        
        if segue.identifier == "toAddAPostItemSegue" {
            if let vc = segue.destination as? AddPostTableViewController {
                if let type = sender as? OptionalInformationType {
                    vc.type = type
                    vc.addItemDelegate = self
                    
                    if let fact = self.fact {
                        vc.fact = fact
                    }
                }
            }
        }
        if segue.identifier == "toNewAddOnSegue" {
            if let navCon = segue.destination as? UINavigationController {
                if let vc = navCon.topViewController as? NewFactViewController {
                    if let fact = sender as? Fact {
                        vc.new = .addOn
                        vc.fact = fact
                        vc.delegate = self
                    }
                }
            }
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
    
    var isHeightSet = false
    
    @IBAction func addSectionTapped(_ sender: Any) {
        if let _ = Auth.auth().currentUser {
            if let fact = fact {
                performSegue(withIdentifier: "toNewAddOnSegue", sender: fact)
            }
        } else {
            self.notLoggedInAlert()
        }
//        if !isHeightSet {
//            var wholeSize = self.tableView.contentSize
//            wholeSize.height = wholeSize.height+125
//
//            self.tableView.contentSize = wholeSize
//            self.tableView.setContentOffset(CGPoint(x: 0, y: 150), animated: true)
//            isHeightSet = true
//        }
//
//        if isOpen {
//
//            UIView.animate(withDuration: 0.1) {
//                self.footerViewPickerView.alpha = 0
//                self.exampleButton.alpha = 1
//                self.blueOwenImageView.alpha = 1
//                self.proposeNewSectionButton.setTitle("Neuer Vorschlag", for: .normal)
//                self.addSectionButton.alpha = 1
//                self.addSectionButton.setTitle("Hinzufügen", for: .normal)
//                self.isOpen = false
//            }
//        } else {
//           UIView.animate(withDuration: 0.1) {
//                self.footerViewPickerView.alpha = 1
//                self.exampleButton.alpha = 0
//            self.blueOwenImageView.alpha = 0
//            self.addSectionButton.alpha = 0.5
//                self.proposeNewSectionButton.setTitle("Weiter", for: .normal)
//                self.addSectionButton.setTitle("Abbrechen", for: .normal)
//            self.isOpen = true
//            }
//        }
    }
    @IBAction func proposeNewSectionTapped(_ sender: Any) {
        
        if isOpen { // Button is the next Button
//
//            if let _ = Auth.auth().currentUser {
//                var postString = "einen Beitrag"
//
//                if selectedOption == .guilty {
//                    postString = "ein Thema"
//                }
//
//                let alert = UIAlertController(title: "Füge \(postString) hinzu", message: "Wähle im nächsten Schritt \(postString) aus um es zu dem ausgewählten Add-On hinzuzufügen und die Erstellung abzuschließen.", preferredStyle: .actionSheet)
//
//                alert.addAction(UIAlertAction(title: "Alles klar", style: .default, handler: { (_) in
//                    switch self.selectedOption {
//                    case .guilty:
//                        self.performSegue(withIdentifier: "toTopicsSegue", sender: self.selectedOption)
//                    default:
//                        self.performSegue(withIdentifier: "toAddAPostItemSegue", sender: self.selectedOption)
//                    }
//                }))
//                alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel, handler: { (_) in
//                    alert.dismiss(animated: true, completion: nil)
//                }))
//                self.present(alert, animated: true, completion: nil)
//
//            } else {
//                self.notLoggedInAlert()
//            }
//
        } else {
            performSegue(withIdentifier: "toProposalSegue", sender: nil)
        }
    }
    
    @IBOutlet weak var footerViewPickerView: UIPickerView!
    @IBOutlet weak var exampleButton: DesignableButton!
    @IBOutlet weak var addSectionButton: DesignableButton!
    @IBOutlet weak var proposeNewSectionButton: DesignableButton!
    @IBOutlet weak var blueOwenImageView: UIImageView!
    
//    var pickerOptions = [OptionalInformation(type: .diy, headerTitle: "Was kann ich tun?", items: []), OptionalInformation(type: .guilty, headerTitle: "Wer ist daran Schuld?", items: []), OptionalInformation(type: .new, headerTitle: "Neues AddOn", items: [])]
    var pickerOptions = [Any]()
    //OptionalInformation(type: .avoid, headerTitle: "Wen sollte ich meiden?", items: [])
    var isOpen = false
    
    
}

extension OptionalInformationForArgumentTableViewController: AddItemDelegate, NewFactDelegate {
    
    func itemSelected(item: Any) {
        saveItemInAddOn(item: item)
    }
    
    
    func doneWithNewAddOn() {
        self.optionalInformations.removeAll()
        self.tableView.reloadData()
        
        self.getData(fact: self.fact!)
    }
    
}

extension OptionalInformationForArgumentTableViewController: CollectionViewInTableViewCellDelegate {
    
    func newPostTapped(addOnDocumentID: String) {
        
        if let _ = Auth.auth().currentUser {
            
            self.addOnDocumentID = addOnDocumentID  // Set the documentID for the addOn where "new Post" was tapped
            
            let alert = UIAlertController(title: "Füge ein Item hinzu", message: "Möchtest du einen Beitrag oder ein Thema zu diesem AddOn hinzufügen?", preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Beitrag (Post)", style: .default, handler: { (_) in
                self.performSegue(withIdentifier: "toAddAPostItemSegue", sender: self.selectedOption)
            }))
            alert.addAction(UIAlertAction(title: "Thema/Diskussion", style: .default, handler: { (_) in
                
                self.performSegue(withIdentifier: "toTopicsSegue", sender: self.selectedOption)
                
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


