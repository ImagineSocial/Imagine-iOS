//
//  NewCommunityItemTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 24.08.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import EasyTipView
import CropViewController

protocol NewFactDelegate: class {
    func finishedCreatingNewInstance(item: Any?)
}

protocol NewCommunityItemDelegate {
    func chooseImage(indexPath: IndexPath)
    func chooseTopic(indexPath: IndexPath)
    func titleTextChanged(text: String)
    func descriptionTextChanged(text: String)
    func argumentTypeChanged(type: ArgumentType)
    func presentationChanged(displayOption: DisplayOption, factDisplayName: FactDisplayName)
    func sourceChanged(source: String)
}

enum NewCommunityItemType {
    case community
    case argument
    case deepArgument
    case source
    case addOn
    case addOnYouTubePlaylistDesign
    case singleTopicAddOn
    case shareTopic
    case addOnPlaylist
}

enum ArgumentType {
    case pro
    case contra
}

enum FactDisplayName {
    case proContra
    case confirmDoubt
    case advantageDisadvantage
}

enum DisplayOption {
    case fact
    case topic
}

enum NewCommunityCellType {
    case setTitle
    case setDescription
    case setPicture
    case chooseCommunity
    case setArgumentProContra
    case chooseCommunityPresentation
    case setLink
}

class NewCommunityItemTableViewController: UITableViewController {
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var headerInfoButton: DesignableButton!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    let db = Firestore.firestore()
    
    let linkCommunityCellIdentifier = "NewCommunityLinkedCommunityCell"
    let pictureCellIdentifier = "NewCommunityPictureCell"
    let presentationCellIdentifier = "NewCommunityPresentationCell"
    let argumentCellIdentifier = "NewCommunityArgumentCell"
    let textFieldCellIdentifier = "NewCommunityTextfieldCell"
    let textCellIdentifier = "NewCommunityTextCell"
    
    let settingFooterIdentifier = "SettingFooter"
    
    let language = LanguageSelection().getLanguage()
    
    var new: NewCommunityItemType?
    
    var fact: Community?
    var argument: Argument?
    var deepArgument: Argument?
    
    var tipView: EasyTipView?
    
    var imagePicker = UIImagePickerController()
    var indexPathOfImageCell: IndexPath?
    var indexPathOfChooseTopicCell: IndexPath?
    
    weak var delegate: NewFactDelegate?
    
    var cells = [NewCommunityCellType]()
    
    //MARK:-Pickable Attributes:
    var selectedTopicIDForSingleTopicAddOn: String?
    var selectedImageFromPicker: UIImage?
    var pickedFactDisplayNames: FactDisplayName = .proContra
    var pickedDisplayOption: DisplayOption = .fact
    var proOrContra: ArgumentType = .pro
    var sourceLink: String?
    var titleText: String?
    var descriptionText: String?
    
    //MARK:-
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib(nibName: "SettingFooterView", bundle: nil), forHeaderFooterViewReuseIdentifier: settingFooterIdentifier)
        
        imagePicker.delegate = self
        
        loadCells()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let tipView = tipView {
            tipView.dismiss()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let tipView = tipView {
            tipView.dismiss()
        }
    }
    
    func loadCells() {
        guard let new = new else {
            self.dismiss(animated: true, completion: nil)
            print("this is not the new new")
            return
        }
        
        switch new {
        case .community:
            headerLabel.text = NSLocalizedString("new_community_header", comment: "create new community")
            cells.append(contentsOf: [.setTitle, .setDescription, .setPicture, .chooseCommunityPresentation])
        case .argument:
            headerLabel.text = NSLocalizedString("new_argument_header", comment: "create new argument")
            cells.append(contentsOf: [.setTitle, .setDescription, .setArgumentProContra])
        case .source:
            headerLabel.text = NSLocalizedString("new_source_header", comment: "create new source")
            cells.append(contentsOf: [.setTitle, .setDescription, .setLink])
        case .deepArgument:
            guard let _ = fact, let _ = argument else {
                self.dismiss(animated: true, completion: nil)
                return
            }
            
            headerLabel.text = NSLocalizedString("new_argument_header", comment: "create new argument")
            cells.append(contentsOf: [.setTitle, .setDescription])
        case .addOnPlaylist:
            headerLabel.text = NSLocalizedString("new_addOn_header", comment: "create new addon")
            cells.append(contentsOf: [.setTitle, .setDescription])
        case .addOn:
            headerLabel.text = NSLocalizedString("new_addOn_header", comment: "create new addon")
            cells.append(contentsOf: [.setTitle, .setDescription, .setPicture])
        case .addOnYouTubePlaylistDesign:
            headerLabel.text = NSLocalizedString("new_addOn_header", comment: "create new addon")
            cells.append(contentsOf: [.setTitle, .setDescription, .setPicture])
        case .singleTopicAddOn:
            headerLabel.text = NSLocalizedString("new_addOn_header", comment: "create new addon")
            cells.append(contentsOf: [.setTitle, .setDescription, .chooseCommunity])
        case .shareTopic:
            headerLabel.text = NSLocalizedString("share_community_header_label", comment: "share community in feed")
            cells.append(contentsOf: [.setTitle, .setDescription])
        }
        print("Reload: \(cells)")
        tableView.reloadData()
    }

    // MARK: TableView

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = cells[indexPath.row]
        
        switch cell {
        case .setTitle:
            if let cell = tableView.dequeueReusableCell(withIdentifier: textCellIdentifier, for: indexPath) as? NewCommunityTextCell {
                
                cell.delegate = self
                
                if let new = new {
                    switch new {
                    case .community:
                        cell.characterLimit = Constants.characterLimits.factTitleCharacterLimit
                    case .argument:
                        cell.characterLimit = Constants.characterLimits.argumentTitleCharacterLimit
                    case .deepArgument:
                        cell.characterLimit = Constants.characterLimits.argumentTitleCharacterLimit
                    case .addOn:
                        cell.characterLimit = Constants.characterLimits.addOnTitleCharacterLimit
                    case .addOnPlaylist:
                        cell.characterLimit = Constants.characterLimits.addOnTitleCharacterLimit
                    case .addOnYouTubePlaylistDesign:
                        cell.characterLimit = Constants.characterLimits.addOnTitleCharacterLimit
                    case .singleTopicAddOn:
                        cell.characterLimit = Constants.characterLimits.addOnTitleCharacterLimit
                    case .source:
                        cell.characterLimit = Constants.characterLimits.sourceTitleCharacterLimit
                    case .shareTopic:
                        cell.characterLimit = Constants.characterLimits.postTitleCharacterLimit
                    }
                }
                
                return cell
            }
        case .setDescription:
            if let cell = tableView.dequeueReusableCell(withIdentifier: textCellIdentifier, for: indexPath) as? NewCommunityTextCell {
                cell.delegate = self
                
                cell.isTitle = false
                cell.headerTitleLabel.text = NSLocalizedString("description:", comment: "description:")
            
                if let new = new {
                    switch new {
                    case .community:
                        cell.characterLimit = Constants.characterLimits.factDescriptionCharacterLimit
                    case .addOn:
                        cell.characterLimit = Constants.characterLimits.addOnDescriptionCharacterLimit
                    case .addOnPlaylist:
                        cell.characterLimit = Constants.characterLimits.addOnDescriptionCharacterLimit
                    case .addOnYouTubePlaylistDesign:
                        cell.characterLimit = Constants.characterLimits.addOnDescriptionCharacterLimit
                    case .singleTopicAddOn:
                        cell.characterLimit = Constants.characterLimits.addOnDescriptionCharacterLimit
                    default:
                        cell.characterLimit = nil
                    }
                }
                return cell
            }
        case .setPicture:
            if let cell = tableView.dequeueReusableCell(withIdentifier: pictureCellIdentifier, for: indexPath) as? NewCommunityPictureCell {
                cell.delegate = self
                cell.indexPath = indexPath
                
                return cell
            }
        case .setLink:
            if let cell = tableView.dequeueReusableCell(withIdentifier: textFieldCellIdentifier, for: indexPath) as? NewCommunityTextfieldCell {
                cell.delegate = self
                
                return cell
            }
        case .setArgumentProContra:
            if let cell = tableView.dequeueReusableCell(withIdentifier: argumentCellIdentifier, for: indexPath) as? NewCommunityArgumentCell {
                cell.delegate = self
                cell.fact = fact
                cell.proOrContra = proOrContra
                
                return cell
            }
        case .chooseCommunity:
            if let cell = tableView.dequeueReusableCell(withIdentifier: linkCommunityCellIdentifier, for: indexPath) as? NewCommunityLinkedCommunityCell {
                cell.delegate = self
                cell.indexPath = indexPath
                
                return cell
            }
        case .chooseCommunityPresentation:
            if let cell = tableView.dequeueReusableCell(withIdentifier: presentationCellIdentifier, for: indexPath) as? NewCommunityPresentationCell {
                cell.delegate = self
                cell.pickedDisplayOption = self.pickedDisplayOption
                
                return cell
            }
        }
        
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cell = cells[indexPath.row]
        
        switch cell {
        case .setTitle:
            return 100
        case .setDescription:
            return 100
        case .setLink:
            return 75
        case .setPicture:
            return 125
        case .chooseCommunity:
            return 100
        case .chooseCommunityPresentation:
            return 250
        case .setArgumentProContra:
            return 100
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: settingFooterIdentifier) as? SettingFooterView {
            if let new = new {
                if new == .argument {
                    footerView.settingDescriptionLabel.text = NSLocalizedString("new_argument_source_footer_text", comment: "remember to add a source for credibility")
                } else if new == .shareTopic {
                    footerView.settingDescriptionLabel.text = NSLocalizedString("share_community_footer_description", comment: "share to let people know and stuff")
                } else {
                    footerView.settingDescriptionLabel.text = ""
                }
            }
            return footerView
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if let new = new {
            if new == .argument || new == .shareTopic {
                return UITableView.automaticDimension
            } else {
                return 30
            }
        }
        return 30
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        return 40
    }
    
    @IBAction func infoButtonTapped(_ sender: Any) {
        if let tipView = tipView {
            tipView.dismiss()
        } else {
            var text = ""
            switch new {
            case .singleTopicAddOn:
                text = Constants.texts.AddOns.singleTopicText
            case .addOnPlaylist:
                text = Constants.texts.AddOns.collectionText
            case .addOn:
                text = Constants.texts.AddOns.collectionText
            case .addOnYouTubePlaylistDesign:
                text = Constants.texts.AddOns.collectionText
            case .community:
                text = Constants.texts.communityText
            default:
                text = Constants.texts.addArgumentText
            }
            
            tipView = EasyTipView(text: text)
            tipView!.show(forView: headerView)
        }
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        if let _ = Auth.auth().currentUser {
            self.view.activityStartAnimating()
            self.doneButton.isEnabled = false
            self.createNewInstance()
        } else {
            self.notLoggedInAlert()
        }
    }
    
    //MARK:- SetData
    func createNewInstance() {
        guard let new = new else { return }
        switch new {
        case .argument:
            createNewArgument()
        case .deepArgument:
            createNewDeepArgument()
        case .community:
            
            var collectionRef: CollectionReference!
            if language == .english {
                collectionRef = db.collection("Data").document("en").collection("topics")
            } else {
                collectionRef = db.collection("Facts")
            }
            
            let ref = collectionRef.document()
            
            if selectedImageFromPicker != nil {
                if let user = Auth.auth().currentUser {
                    self.savePicture(userID: user.uid, topicRef: ref, new: .community)
                }
            } else {
                createNewCommunity(ref: ref, imageURL: nil)
            }
        case .source:
            createNewSource()
        case .addOnPlaylist:
            if let fact = fact {
                var collectionRef: CollectionReference!
                if fact.language == .english {
                    collectionRef = db.collection("Data").document("en").collection("topics")
                } else {
                    collectionRef = db.collection("Facts")
                }
                
                let ref = collectionRef.document(fact.documentID).collection("addOns").document()
                
                createNewAddOnPlaylist(ref: ref)
                
            }
        case .addOn:
            if let fact = fact {
                var collectionRef: CollectionReference!
                if fact.language == .english {
                    collectionRef = db.collection("Data").document("en").collection("topics")
                } else {
                    collectionRef = db.collection("Facts")
                }
                
                let ref = collectionRef.document(fact.documentID).collection("addOns").document()
                
                if selectedImageFromPicker != nil {
                    if let user = Auth.auth().currentUser {
                        self.savePicture(userID: user.uid, topicRef: ref, new: .addOn)
                    }
                } else {
                    createNewAddOn(ref: ref, imageURL: nil, isYouTubePlaylistDesign: false)
                }
            }
        case .addOnYouTubePlaylistDesign:
            if let fact = fact {
                var collectionRef: CollectionReference!
                if fact.language == .english {
                    collectionRef = db.collection("Data").document("en").collection("topics")
                } else {
                    collectionRef = db.collection("Facts")
                }
                
                let ref = collectionRef.document(fact.documentID).collection("addOns").document()
                
                if selectedImageFromPicker != nil {
                    if let user = Auth.auth().currentUser {
                        self.savePicture(userID: user.uid, topicRef: ref, new: .addOnYouTubePlaylistDesign)
                    }
                } else {
                    createNewAddOn(ref: ref, imageURL: nil, isYouTubePlaylistDesign: true)
                }
            }
        case .singleTopicAddOn:
            createNewSingleTopicAddOn()
        case .shareTopic:
            createSingleTopicPost()
        }
    }
    
    func showTitleDescriptionAlert() {
        self.alert(message: NSLocalizedString("new_community_item_error_message", comment: "you need title and description"), title: NSLocalizedString("new_community_item_error_title", comment: "the are some things missing"))
        self.view.activityStopAnimating()
    }
    
    func createSingleTopicPost() {
        if let fact = fact {
            if let title = titleText, title != "" {
                
                let OP = Auth.auth().currentUser!
                
                var collectionRef: CollectionReference!
                if fact.language == .english {
                    collectionRef = db.collection("Data").document("en").collection("posts")
                } else {
                    collectionRef = db.collection("Posts")
                }
                let ref = collectionRef.document()
                
                var description = ""
                if let descriptionText = descriptionText {
                    description = descriptionText
                }

                let dataDictionary: [String: Any] = ["title": title, "description": description, "createTime": Timestamp(date: Date()), "originalPoster": OP.uid, "thanksCount":0, "wowCount":0, "haCount":0, "niceCount":0, "type": "singleTopic", "report": "normal", "linkedFactID": fact.documentID, "notificationRecipients": [OP.uid]]
                
                ref.setData(dataDictionary) { (err) in
                    if let error = err {
                        print("We have an error: \(error.localizedDescription)")
                    } else {
                        let post = Post()
                        post.documentID = ref.documentID
                        post.title = title
                        post.language = fact.language
                        
                        let userRef = self.db.collection("Users").document(OP.uid).collection("posts").document(ref.documentID)
                        var data: [String: Any] = ["createTime": Timestamp(date: Date())]
                        
                        if fact.language == .english {
                            data["language"] = "en"
                        }
                        userRef.setData(data) { (err) in
                            if let error = err {
                                print("We have an error: \(error.localizedDescription)")
                                self.finished(item: post)   // finish anyway
                            } else {
                                self.finished(item: post)
                            }
                        }
                    }
                }
            } else {
                self.alert(message: NSLocalizedString("new_community_item_error_title", comment: "input missing"))
            }
        }
    }
    
    func createNewSingleTopicAddOn() {
        
        if let fact = fact {
            if let title = titleText, let description = descriptionText {
                if let linkedFactID = self.selectedTopicIDForSingleTopicAddOn {
                    var collectionRef: CollectionReference!
                    if fact.language == .english {
                        collectionRef = db.collection("Data").document("en").collection("topics")
                    } else {
                        collectionRef = db.collection("Facts")
                    }
                    let ref = collectionRef.document(fact.documentID).collection("addOns")
                    
                    let op = Auth.auth().currentUser!
                    
                    let data: [String: Any] = ["OP": op.uid, "headerTitle": title, "description": description, "linkedFactID": linkedFactID, "popularity": 0, "type": "singleTopic"]
                    
                    ref.addDocument(data: data) { (err) in
                        if let error = err {
                            print("We have an error: \(error.localizedDescription)")
                        } else {
                            self.finished(item: nil)// Will reload the database in the delegate
                        }
                    }
                } else {
                    self.alert(message: NSLocalizedString("new_addOnTopic_missing_community", comment: "there is no linked community"))
                }
            } else {
                self.showTitleDescriptionAlert()
            }
        }
    }
    
    func createNewAddOn(ref: DocumentReference, imageURL: String?, isYouTubePlaylistDesign: Bool) {
        
            if let title = titleText, let description = descriptionText {
                
                let op = Auth.auth().currentUser!
                
                var data: [String: Any] = ["OP": op.uid, "title": title, "description": description, "popularity": 0, "type": "default"]
                
                if isYouTubePlaylistDesign {
                    data["design"] = "youTubePlaylist"
                }
                
                ref.setData(data) { (err) in
                    if let error = err {
                        print("We have an error: \(error.localizedDescription)")
                    } else {
                        self.finished(item: nil)// Will reload the database in the delegate
                    }
                }
            } else {
                showTitleDescriptionAlert()
            }
    }
    
    func createNewAddOnPlaylist(ref: DocumentReference) {
        
            if let title = titleText, let description = descriptionText {
                
                let op = Auth.auth().currentUser!
                
                let data: [String: Any] = ["OP": op.uid, "title": title, "description": description, "popularity": 0, "type": "playlist"]
                
                ref.setData(data) { (err) in
                    if let error = err {
                        print("We have an error: \(error.localizedDescription)")
                    } else {
                        self.finished(item: nil)// Will reload the database in the delegate
                    }
                }
            } else {
                showTitleDescriptionAlert()
            }
    }
    
    func createNewSource() {
        if let fact = fact, let argument = argument {   // Only possible to add source to specific argument
            if let title = titleText, let description = descriptionText {
                if let source = sourceLink, source.isValidURL {
                    
                    var collectionRef: CollectionReference!
                    if fact.language == .english {
                        collectionRef = db.collection("Data").document("en").collection("topics")
                    } else {
                        collectionRef = db.collection("Facts")
                    }
                    
                    let argumentRef = collectionRef.document(fact.documentID).collection("arguments").document(argument.documentID).collection("sources").document()
                    
                    let op = Auth.auth().currentUser!
                    
                    let data: [String:Any] = ["title" : title, "description": description, "source": source, "OP": op.uid]
                    
                    argumentRef.setData(data, completion: { (err) in
                        if let error = err {
                            print("We have an error: \(error.localizedDescription)")
                        } else {
                            let newSource = Source(addMoreDataCell: false)
                            newSource.title = title
                            newSource.description = description
                            newSource.source = source
                            newSource.documentID = argumentRef.documentID
                            
                            self.finished(item: newSource)
                        }
                    })
                } else {
                    self.alert(message: NSLocalizedString("new_community_item_not_valid_link", comment: "not valid link"))
                }
            } else {
                showTitleDescriptionAlert()
            }
        }
    }
    
    func createNewDeepArgument() {
        if let fact = fact, let argument = argument {
            if let title = titleText, let description = descriptionText {
                var collectionRef: CollectionReference!
                if fact.language == .english {
                    collectionRef = db.collection("Data").document("en").collection("topics")
                } else {
                    collectionRef = db.collection("Facts")
                }
                let ref = collectionRef.document(fact.documentID).collection("arguments").document(argument.documentID).collection("arguments").document()
                let op = Auth.auth().currentUser!
                
                let data: [String:Any] = ["title" : title, "description": description, "OP": op.uid]
                
                ref.setData(data) { (err) in
                    if let error = err {
                        print("We have an error: \(error.localizedDescription)")
                    } else {
                        let argument = Argument(addMoreDataCell: false)
                        argument.title  = title
                        argument.description = description
                        argument.documentID = ref.documentID
                        
                        self.finished(item: argument)
                    }
                }
            } else {
                showTitleDescriptionAlert()
            }
        } else {
            self.alert(message: "Es ist ein Fehler aufgetreten. Bitte Versuche es später noch einmal!", title: "Hmm...")
        }
    }
    
    func createNewArgument() {
        if let fact = fact {
            if let title = titleText, let description = descriptionText {
                
                var collectionRef: CollectionReference!
                if fact.language == .english {
                    collectionRef = db.collection("Data").document("en").collection("topics")
                } else {
                    collectionRef = db.collection("Facts")
                }
                
                let ref = collectionRef.document(fact.documentID).collection("arguments").document()
                
                let op = Auth.auth().currentUser!
                let proOrContra = getProOrContraString()
                
                let data: [String:Any] = ["title" : title, "description": description, "proOrContra": proOrContra, "OP": op.uid, "upvotes": 0, "downvotes": 0]
                
                ref.setData(data) { (err) in
                    if let error = err {
                        print("We have an error: \(error.localizedDescription)")
                    } else {
                        let argument = Argument(addMoreDataCell: false)
                        argument.title  = title
                        argument.description = description
                        argument.proOrContra = proOrContra
                        argument.documentID = ref.documentID
                        
                        self.finished(item: argument)
                    }
                }
            } else {
                showTitleDescriptionAlert()
            }
        } else {
            self.alert(message: NSLocalizedString("new_community_weird_error", comment: "something went wrong, try later"), title: "Hmm...")
        }
    }
    
    func createNewCommunity(ref: DocumentReference, imageURL: String?) {
        
        if let op = Auth.auth().currentUser {
            if let title = titleText, let description = descriptionText {
                
                let displayOption = self.getNewFactDisplayString(displayOption: self.pickedDisplayOption)
                
                var data = [String: Any]()
                let name = title
                let description = description
                let fact = Community()
                
                data = ["follower": [op.uid],"name": name, "description": description, "createDate": Timestamp(date: Date()), "OP": op.uid, "displayOption": displayOption.displayOption, "popularity": 0]
                
                if let factDisplayName = displayOption.factDisplayNames {
                    data["factDisplayNames"] = factDisplayName
                }
                
                fact.title = name
                fact.description = description
                fact.beingFollowed = true
                fact.documentID = ref.documentID
                fact.displayOption = self.pickedDisplayOption
                fact.moderators = [op.uid]
                fact.language = language
                
                if let url = imageURL {
                    data["imageURL"] = url
                    fact.imageURL = url
                }
                if language == .english {
                    data["language"] = "en"
                }
                
                self.setUserChanges(documentID: ref.documentID) //Follow Topic and set Mod Badge
                
                ref.setData(data) { (err) in
                    if let error = err {
                        print("We have an error: \(error.localizedDescription)")
                    } else {
                        self.finished(item: fact)    // Will reload the database in the delegate
                    }
                }
            } else {
                self.showTitleDescriptionAlert()
            }
        }
    }
    
    func setUserChanges(documentID: String) {
        let header = CommunityHeaderView()
        let fact = Community()
        fact.documentID = documentID
        fact.language = language
        
        header.followTopic(community: fact)
        
        if let user = Auth.auth().currentUser {
            let ref = db.collection("Users").document(user.uid)
            ref.updateData([
                "badges" : FieldValue.arrayUnion(["mod"])
            ]) { (err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    print("Succesfully added badge")
                }
            }
        }
    }
    
    func finished(item: Any?) {
        self.view.activityStopAnimating()
        let alertController = UIAlertController(title: NSLocalizedString("thanks", comment: "thanks"), message: NSLocalizedString("new_community_successfull_added", comment: "new_community_successfull_added"), preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { (_) in
            self.dismiss(animated: true) {
                self.doneButton.isEnabled = true
                self.delegate?.finishedCreatingNewInstance(item: item)
            }
        }
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    func getProOrContraString() -> String {
        switch proOrContra {
        case .contra:
            return "contra"
        case .pro:
            return "pro"
        }
    }
    
    func getNewFactDisplayString(displayOption: DisplayOption) -> (displayOption: String, factDisplayNames: String?) {
        switch displayOption {
            case .fact:
                switch self.pickedFactDisplayNames {
                case .proContra:
                    return (displayOption: "fact", factDisplayNames: "proContra")
                case .confirmDoubt:
                    return (displayOption: "fact", factDisplayNames: "confirmDoubt")
                case .advantageDisadvantage:
                    return (displayOption: "fact", factDisplayNames: "advantage")
                }
            case .topic:
                return (displayOption: "topic", factDisplayNames: nil)
        }
    }
    
    
    //MARK:- PrepareForSegue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "selectFactSegue" {
            if let navCon = segue.destination as? UINavigationController {
                if let factVC = navCon.topViewController as? CommunityCollectionViewController {
                    factVC.addFactToPost = .newPost
                    factVC.delegate = self
                }
            }
        }
    }
}

extension NewCommunityItemTableViewController: NewCommunityItemDelegate, LinkFactWithPostDelegate {
    
    func chooseImage(indexPath: IndexPath) {
        self.indexPathOfImageCell = indexPath
        
        self.imagePicker.sourceType = .photoLibrary
        self.present(self.imagePicker, animated: true, completion: nil)
    }
    
    func chooseTopic(indexPath: IndexPath) {
        self.indexPathOfChooseTopicCell = indexPath
        
        performSegue(withIdentifier: "selectFactSegue", sender: nil)
    }
    
    func titleTextChanged(text: String) {
        if text == "" {
            self.titleText = nil
        } else {
            self.titleText = text
        }
    }
    
    func descriptionTextChanged(text: String) {
        if text == "" {
            self.descriptionText = nil
        } else {
            self.descriptionText = text
        }
    }
    
    func argumentTypeChanged(type: ArgumentType) {
        self.proOrContra = type
    }
    
    func presentationChanged(displayOption: DisplayOption, factDisplayName: FactDisplayName) {
        print("presentation changed: \(displayOption), \(factDisplayName)")
        self.pickedDisplayOption = displayOption
        self.pickedFactDisplayNames = factDisplayName
    }
    
    func sourceChanged(source: String) {
        if source == "" {
            self.sourceLink = nil
        } else {
            self.sourceLink = source
        }
    }
    
    func selectedFact(fact: Community, isViewAlreadyLoaded: Bool) {
        if fact.documentID != "" {
            self.selectedTopicIDForSingleTopicAddOn = fact.documentID
            if let indexPath = self.indexPathOfChooseTopicCell {
                if let cell = tableView.cellForRow(at: indexPath) as? NewCommunityLinkedCommunityCell {
                    if let url = URL(string: fact.imageURL) {
                        cell.imageURL = url
                        cell.choosenTopicLabel.text = fact.title
                    }
                }
            }
        }
    }
}

extension NewCommunityItemTableViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, CropViewControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let originalImage = info[.originalImage] as? UIImage {
            imagePicker.dismiss(animated: true, completion: nil)
            self.showCropView(image: originalImage)
        }
    }
    
    func showCropView(image: UIImage) {
        let cropViewController = CropViewController(image: image)
        cropViewController.delegate = self
        cropViewController.aspectRatioPreset = .preset16x9
        cropViewController.aspectRatioLockEnabled = true
        navigationController?.pushViewController(cropViewController, animated: true)
    }
    
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        setImage(image: image)
        selectedImageFromPicker = image
        navigationController?.popToViewController(self, animated: true)
    }
    
    func setImage(image: UIImage) {
        if let indexPath = self.indexPathOfImageCell {
            if let cell = tableView.cellForRow(at: indexPath) as? NewCommunityPictureCell {
                cell.choosenImage = image
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    
    
    func savePicture(userID: String, topicRef: DocumentReference, new: NewCommunityItemType) {
        
        if let image = self.selectedImageFromPicker?.jpegData(compressionQuality: 1) {
            let data = NSData(data: image)
            
            let imageSize = data.count/1000
            
            
            if imageSize <= 500 {   // When the imageSize is under 500kB it wont be compressed, because you can see the difference
                // No compression
                print("No compression")
                self.storeImage(data: image, topicRef: topicRef, userID: userID, new: new)
            } else if imageSize <= 1000 {
                if let image = self.selectedImageFromPicker?.jpegData(compressionQuality: 0.4) {
                    
                    self.storeImage(data: image, topicRef: topicRef, userID: userID, new: new)
                }
            } else if imageSize <= 2000 {
                if let image = self.selectedImageFromPicker?.jpegData(compressionQuality: 0.25) {
                    
                    self.storeImage(data: image, topicRef: topicRef, userID: userID, new: new)
                }
            } else {
                if let image = self.selectedImageFromPicker?.jpegData(compressionQuality: 0.1) {
                    
                    self.storeImage(data: image, topicRef: topicRef, userID: userID, new: new)
                }
            }
            
        }
    }
    
    func storeImage(data: Data, topicRef: DocumentReference, userID: String, new: NewCommunityItemType) {
        
        let storageRef = Storage.storage().reference().child("factPictures").child("\(topicRef.documentID).png")
        
        storageRef.putData(data, metadata: nil, completion: { (metadata, error) in    //Bild speichern
            if let error = error {
                print(error)
                return
            }
            storageRef.downloadURL(completion: { (url, err) in  // Hier wird die URL runtergezogen
                if let err = err {
                    print(err)
                    return
                }
                if let url = url {
                    if new == .community {
                        self.createNewCommunity(ref: topicRef, imageURL: url.absoluteString)
                    } else if new == .addOn {
                        self.createNewAddOn(ref: topicRef, imageURL: url.absoluteString, isYouTubePlaylistDesign: false)
                    } else if new == .addOnYouTubePlaylistDesign {
                        self.createNewAddOn(ref: topicRef, imageURL: url.absoluteString, isYouTubePlaylistDesign: true)
                    } else {
                        print("Here is no picture allowed")
                    }
                }
            })
        })
    }
    
}


class NewCommunityLinkedCommunityCell: UITableViewCell {
    @IBOutlet weak var previewImageView: DesignableImage!
    @IBOutlet weak var choosenTopicLabel: UILabel!
    
    var indexPath: IndexPath?
    var delegate: NewCommunityItemDelegate?
    
    var imageURL: URL? {
        didSet {
            previewImageView.sd_setImage(with: imageURL, completed: nil)
        }
    }
    
    @IBAction func chooseCommunityButtonTapped(_ sender: Any) {
        if let indexPath = indexPath {
            delegate?.chooseTopic(indexPath: indexPath)
        }
    }
}

class NewCommunityPictureCell: UITableViewCell {
    @IBOutlet weak var previewImageView: DesignableImage!
    @IBOutlet weak var imageViewWidthConstraint: NSLayoutConstraint!
    
    var delegate: NewCommunityItemDelegate?
    var indexPath: IndexPath?
    
    var choosenImage: UIImage? {
        didSet {
            if let image = choosenImage {
                previewImageView.image = image
            }
        }
    }
    
    @IBAction func choosePictureButtonTapped(_ sender: Any) {
        if let indexPath = indexPath {
            delegate?.chooseImage(indexPath: indexPath)
        }
    }
}

class NewCommunityPresentationCell: UITableViewCell, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var displaySegmentedControl: UISegmentedControl!
    @IBOutlet weak var displayImageView: DesignableImage!
    @IBOutlet weak var displayDescriptionLabel: UILabel!
    @IBOutlet weak var proContraPickerView: UIPickerView!
    
    var delegate: NewCommunityItemDelegate?
    
    let pickerOptions = [NSLocalizedString("discussion_pro/contra", comment: "pro/Contra"), NSLocalizedString("discussion_doubt/proof", comment: "doubt/proof"), NSLocalizedString("discussion_advantage/disadvantage", comment: "advantage/disadvantage")]
    var pickedFactDisplayNames: FactDisplayName = .proContra
    
    var pickedDisplayOption: DisplayOption? {
        didSet {
            if let option = pickedDisplayOption {
                if option == .fact {
                    setFactUI()
                    displaySegmentedControl.selectedSegmentIndex = 0
                } else {
                    setTopicUI()
                    displaySegmentedControl.selectedSegmentIndex = 1
                }
            }
        }
    }
    
    override func awakeFromNib() {
        proContraPickerView.delegate = self
        proContraPickerView.dataSource = self
    }
    
    
    @IBAction func displaySegmentedControlChanged(_ sender: Any) {
        switch displaySegmentedControl.selectedSegmentIndex {
        case 0:
            // Fact
            self.pickedDisplayOption = .fact
            setFactUI()
        case 1:
            // Topic
            self.pickedDisplayOption = .topic
            setTopicUI()
        default:
            print("Wont happen")
        }
        
        if let option = self.pickedDisplayOption {
            delegate?.presentationChanged(displayOption: option, factDisplayName: self.pickedFactDisplayNames)
        }
    }
    
    func setTopicUI() {
        UIView.animate(withDuration: 0.3, animations: {
            self.proContraPickerView.alpha = 0.5
            self.proContraPickerView.isUserInteractionEnabled = false
        }) { (_) in
            
        }
        displayDescriptionLabel.fadeTransition(0.3)
        displayDescriptionLabel.text = NSLocalizedString("new_community_topic_description", comment: "whats that now?")
        displayImageView.image = UIImage(named: "TopicDisplay")
    }
    
    func setFactUI() {
        UIView.animate(withDuration: 0.3, animations: {
            self.proContraPickerView.alpha = 1
            self.proContraPickerView.isUserInteractionEnabled = true
        }) { (_) in
            
        }
        displayDescriptionLabel.fadeTransition(0.3)
        displayDescriptionLabel.text = NSLocalizedString("new_community_discussion_description", comment: "whats that?")
        displayImageView.image = UIImage(named: "FactDisplay")
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        pickerOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        pickerOptions[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch row {
        case 0:
            self.pickedFactDisplayNames = .proContra
            
        case 1:
            self.pickedFactDisplayNames = .confirmDoubt
            
        case 2:
            self.pickedFactDisplayNames = .advantageDisadvantage
            
        default:
            print("Wrong row?")
        }
        if let option = self.pickedDisplayOption {
            delegate?.presentationChanged(displayOption: option, factDisplayName: self.pickedFactDisplayNames)
        }
    }
    
}

class NewCommunityArgumentCell: UITableViewCell {
    @IBOutlet weak var proContraSegmentedControl: UISegmentedControl!
    @IBOutlet weak var smallDescriptionLabeö: UILabel!
    
    var delegate: NewCommunityItemDelegate?
    
    var fact: Community? {
        didSet {
            if let fact = fact {
                switch fact.factDisplayNames {
                case .advantageDisadvantage:
                    proContraSegmentedControl.setTitle(NSLocalizedString("discussion_advantage", comment: "advantage"), forSegmentAt: 0)
                    proContraSegmentedControl.setTitle(NSLocalizedString("discussion_disadvantage", comment: "disadvantage"), forSegmentAt: 1)
                case .confirmDoubt:
                    proContraSegmentedControl.setTitle(NSLocalizedString("discussion_doubt", comment: "doubt"), forSegmentAt: 0)
                    proContraSegmentedControl.setTitle(NSLocalizedString("discussion_proof", comment: "proof"), forSegmentAt: 1)
                default:
                    print("Stays pro/contra")
                }
            }
        }
    }
    
    var proOrContra: ArgumentType? {
        didSet {
            if let proOrContra = proOrContra {
                switch proOrContra {
                case .contra:
                    proContraSegmentedControl.selectedSegmentIndex = 0
                default:
                    proContraSegmentedControl.selectedSegmentIndex = 1
                }
            }
        }
    }
    
    @IBAction func proContraSegmentedControlChanged(_ sender: Any) {
        if let proOrContra = proOrContra {
            delegate?.argumentTypeChanged(type: proOrContra)
        }
    }
}

class NewCommunityTextfieldCell: UITableViewCell {
    @IBOutlet weak var headerTitleLabel: UILabel!
    @IBOutlet weak var cellTextField: UITextField!
    
    var delegate: NewCommunityItemDelegate?
    
    override func awakeFromNib() {
        cellTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if let text = cellTextField.text {
            self.delegate?.sourceChanged(source: text)
        }
    }
    
}

class NewCommunityTextCell: UITableViewCell, UITextViewDelegate {
    @IBOutlet weak var headerTitleLabel: UILabel!
    @IBOutlet weak var cellTextView: UITextView!
    @IBOutlet weak var characterLimitLabel: UILabel!
    
    var delegate: NewCommunityItemDelegate?
    var characterLimit: Int? {
        didSet {
            if let limit = characterLimit {
                characterLimitLabel.text = String(limit)
            }
        }
    }
    
    var isTitle = true  //else: description
    
    override func awakeFromNib() {
        cellTextView.delegate = self
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if textView == cellTextView {  // No lineBreaks in titleTextView
            guard text.rangeOfCharacter(from: CharacterSet.newlines) == nil else {
                return textView.resignFirstResponder()
            }
            
            if let characterLimit = characterLimit {
                return textView.text.count + (text.count - range.length) <= characterLimit
            }
        }
        
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        
        if textView == cellTextView {
            if isTitle {
                self.delegate?.titleTextChanged(text: textView.text)
            } else {
                self.delegate?.descriptionTextChanged(text: textView.text)
            }
            
            if let characterLimit = characterLimit {
                let characterLeft = characterLimit-textView.text.count
                self.characterLimitLabel.text = String(characterLeft)
            }
        }
    }
    
}

class NewCommunityAddOnDesignCell: UITableViewCell {
    
    
}
