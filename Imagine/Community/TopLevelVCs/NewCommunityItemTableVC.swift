//
//  NewCommunityItemTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 24.08.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseStorage
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
    func presentationChanged(displayOption: DisplayOption, factDisplayName: DiscussionTitles)
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

enum DiscussionTitles: String, Codable {
    case proContra, confirmDoubt, advantageDisadvantage
}

enum DisplayOption: String, Codable {
    case discussion
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

class NewCommunityItemTableVC: UITableViewController {
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var headerInfoButton: DesignableButton!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    let db = FirestoreRequest.shared.db
    
    let linkCommunityCellIdentifier = "NewCommunityLinkedCommunityCell"
    let pictureCellIdentifier = "NewCommunityPictureCell"
    let presentationCellIdentifier = "NewCommunityPresentationCell"
    let argumentCellIdentifier = "NewCommunityArgumentCell"
    let textFieldCellIdentifier = "NewCommunityTextfieldCell"
    let textCellIdentifier = "NewCommunityTextCell"
    
    let settingFooterIdentifier = "SettingFooter"
    
    let language = LanguageSelection.language
    
    var new: NewCommunityItemType?
    
    var community: Community?
    var argument: Argument?
    var deepArgument: Argument?
    
    var tipView: EasyTipView?
    
    var imagePicker = UIImagePickerController()
    var indexPathOfImageCell: IndexPath?
    var indexPathOfChooseTopicCell: IndexPath?
    
    weak var delegate: NewFactDelegate?
    
    var cells = [NewCommunityCellType]()
    
    //MARK: - Pickable Attributes
    
    var selectedTopicIDForSingleTopicAddOn: String?
    var selectedImageFromPicker: UIImage?
    var pickedDiscussionTitles: DiscussionTitles = .proContra
    var pickedDisplayOption: DisplayOption = .discussion
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
            guard let _ = community, let _ = argument else {
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
                        cell.characterLimit = Constants.characterLimits.communityTitleCharacterLimit
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
                        cell.characterLimit = Constants.characterLimits.communityDescriptionCharacterLimit
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
                cell.fact = community
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
        guard AuthenticationManager.shared.isLoggedIn else {
            self.notLoggedInAlert()
            return
        }
        
        self.view.activityStartAnimating()
        self.doneButton.isEnabled = false
        self.createNewInstance()
        
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
            
            let ref = FirestoreReference.documentRef(.communities, documentID: nil)
            
            if selectedImageFromPicker != nil {
                if let userID = AuthenticationManager.shared.user?.uid {
                    self.savePicture(userID: userID, topicRef: ref, new: .community)
                }
            } else {
                createNewCommunity(ref: ref, imageURL: nil)
            }
        case .source:
            createNewSource()
        case .addOnPlaylist:
            guard let community = community, let id = community.id else {
                return
            }
            let collectionReference = FirestoreCollectionReference(document: id, collection: "addOns")
            let ref = FirestoreReference.documentRef(.communities, documentID: nil, collectionReferences: collectionReference)
            
            createNewAddOnPlaylist(ref: ref)
        case .addOn:
            guard let community = community, let id = community.id else {
                return
            }
            
            let collectionReference = FirestoreCollectionReference(document: id, collection: "addOns")
            let ref = FirestoreReference.documentRef(.communities, documentID: nil, collectionReferences: collectionReference)
            
            if selectedImageFromPicker != nil {
                if let userID = AuthenticationManager.shared.user?.uid {
                    self.savePicture(userID: userID, topicRef: ref, new: .addOn)
                }
            } else {
                createNewAddOn(ref: ref, imageURL: nil, isYouTubePlaylistDesign: false)
            }
        case .addOnYouTubePlaylistDesign:
            guard let community = community, let id = community.id else {
                return
            }
            
            let collectionReference = FirestoreCollectionReference(document: id, collection: "addOns")
            let ref = FirestoreReference.documentRef(.communities, documentID: nil, collectionReferences: collectionReference)
            
            if selectedImageFromPicker != nil {
                if let userID = AuthenticationManager.shared.user?.uid {
                    self.savePicture(userID: userID, topicRef: ref, new: .addOnYouTubePlaylistDesign)
                }
            } else {
                createNewAddOn(ref: ref, imageURL: nil, isYouTubePlaylistDesign: true)
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
        guard let community = community, let communityID = community.id, let title = titleText, title != "", let userID = AuthenticationManager.shared.user?.uid else {
            self.alert(message: NSLocalizedString("new_community_item_error_title", comment: "input missing"))
            return
        }
        
        let ref = FirestoreReference.documentRef(.posts, documentID: nil)
        
        let post = Post(type: .singleTopic, title: title, createdAt: Date())
        post.description = descriptionText
        post.userID = userID
        post.notificationRecipients = [userID]
        post.communityID = communityID
        post.language = community.language
        
        FirestoreManager.uploadObject(object: post, documentReference: ref) { error in
            if let error = error {
                print("We have an error uploading a single topic post: \(error.localizedDescription)")
            } else {
                let postData = PostData(createdAt: Date(), userID: userID, language: community.language, isTopicPost: false)
                
                let collectionReference = FirestoreCollectionReference(document: userID, collection: "posts")
                let postRef = FirestoreReference.documentRef(.users, documentID: ref.documentID, collectionReferences: collectionReference)
                
                FirestoreManager.uploadObject(object: postData, documentReference: postRef) { error in
                    self.finished(item: post)
                    
                    guard let error = error else {
                        return
                    }

                    print("We have an error uploading the postData: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func createNewSingleTopicAddOn() {
        
        guard let community = community, let communityID = community.id, let title = titleText, let description = descriptionText, let linkedFactID = self.selectedTopicIDForSingleTopicAddOn, let userID = AuthenticationManager.shared.user?.uid else {
            self.showTitleDescriptionAlert()
            return
        }
        
        let collectionReference = FirestoreCollectionReference(document: communityID, collection: "addOns")
        let ref = FirestoreReference.mainRef(.communities, collectionReferences: collectionReference)
        
        let data: [String: Any] = ["OP": userID, "headerTitle": title, "description": description, "linkedFactID": linkedFactID, "popularity": 0, "type": "singleTopic"]
        
        ref.addDocument(data: data) { (err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                self.finished(item: nil)// Will reload the database in the delegate
            }
        }
    }
    
    func createNewAddOn(ref: DocumentReference, imageURL: String?, isYouTubePlaylistDesign: Bool) {
        
        guard let title = titleText, let description = descriptionText, let userID = AuthenticationManager.shared.user?.uid else {
            showTitleDescriptionAlert()
            return
        }
                
        var data: [String: Any] = ["OP": userID, "title": title, "description": description, "popularity": 0, "type": "default"]
        
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
    }
    
    func createNewAddOnPlaylist(ref: DocumentReference) {
        
        guard let title = titleText, let description = descriptionText, let userID = AuthenticationManager.shared.user?.uid else {
            showTitleDescriptionAlert()
            return
        }
        
        let data: [String: Any] = ["OP": userID, "title": title, "description": description, "popularity": 0, "type": "playlist"]
        
        ref.setData(data) { (err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                self.finished(item: nil)// Will reload the database in the delegate
            }
        }
    }
    
    func createNewSource() {
        guard let community = community, let communityID = community.id, let argument = argument, let title = titleText, let description = descriptionText, let userID = AuthenticationManager.shared.user?.uid, let source = sourceLink, source.isValidURL else {
            showTitleDescriptionAlert()
            return
        }
        
        let argumentReference = FirestoreCollectionReference(document: communityID, collection: "arguments")
        let sourceReference = FirestoreCollectionReference(document: argument.documentID, collection: "sources")
        let reference = FirestoreReference.documentRef(.communities, documentID: nil, collectionReferences: argumentReference, sourceReference)
        
        let data: [String:Any] = ["title" : title, "description": description, "source": source, "OP": userID]
        
        reference.setData(data, completion: { (err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                let newSource = Source(addMoreDataCell: false)
                newSource.title = title
                newSource.description = description
                newSource.source = source
                newSource.documentID = reference.documentID
                
                self.finished(item: newSource)
            }
        })
    }
    
    func createNewDeepArgument() {
        guard let community = community, let communityID = community.id, let argument = argument, let title = titleText, let description = descriptionText, let userID = AuthenticationManager.shared.user?.uid else {
            showTitleDescriptionAlert()
            return
        }
        
        let argumentReference = FirestoreCollectionReference(document: communityID, collection: "arguments")
        let deepArgumentReference = FirestoreCollectionReference(document: argument.documentID, collection: "arguments")
        let reference = FirestoreReference.documentRef(.communities, documentID: nil, collectionReferences: argumentReference, deepArgumentReference)
        
        let data: [String:Any] = ["title" : title, "description": description, "OP": userID]
        
        reference.setData(data) { (err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                let argument = Argument(addMoreDataCell: false)
                argument.title  = title
                argument.description = description
                argument.documentID = reference.documentID
                
                self.finished(item: argument)
            }
        }
    }
    
    func createNewArgument() {
        guard let community = community, let communityID = community.id, let title = titleText, let description = descriptionText, let userID = AuthenticationManager.shared.user?.uid else {
            showTitleDescriptionAlert()
            return
        }
        
        let argumentReference = FirestoreCollectionReference(document: communityID, collection: "arguments")
        let reference = FirestoreReference.documentRef(.communities, documentID: nil, collectionReferences: argumentReference)
        
        
        let proOrContra = getProOrContraString()
        
        let data: [String:Any] = ["title" : title, "description": description, "proOrContra": proOrContra, "OP": userID, "upvotes": 0, "downvotes": 0]
        
        reference.setData(data) { (err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                let argument = Argument(addMoreDataCell: false)
                argument.title  = title
                argument.description = description
                argument.proOrContra = proOrContra
                argument.documentID = reference.documentID
                
                self.finished(item: argument)
            }
        }
    }
    
    func createNewCommunity(ref: DocumentReference, imageURL: String?) {
        
        guard let userID = AuthenticationManager.shared.user?.uid, let title = titleText, let description = descriptionText else {
            self.showTitleDescriptionAlert()
            
            return
        }
                
        let community = Community()
        community.id = ref.documentID
        community.title = title
        community.description = description
        community.createdAt = Date()
        community.createdBy = userID
        community.moderators = [userID]
        community.displayOption = pickedDisplayOption
        community.discussionTitles = (pickedDisplayOption == .discussion) ? pickedDiscussionTitles : nil
        community.language = language
        community.imageURL = imageURL
        
        FirestoreManager.uploadObject(object: community, documentReference: ref) { error in
            guard let error = error else {
                self.followCommunity(community: community)
                self.finished(item: community)
                return
            }

            print("We have an error uploading a community: \(error.localizedDescription)")
        }
    }
    
    private func followCommunity(community: Community) {
        community.followTopic { success in
            if !success {
                print("We couldnt follow the topic: \(community.title ?? "")")
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
    
    //MARK:- PrepareForSegue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "selectFactSegue" {
            if let navCon = segue.destination as? UINavigationController {
                if let factVC = navCon.topViewController as? CommunityCollectionVC {
                    factVC.addFactToPost = .newPost
                    factVC.delegate = self
                }
            }
        }
    }
}

extension NewCommunityItemTableVC: NewCommunityItemDelegate, LinkFactWithPostDelegate {
    
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
    
    func presentationChanged(displayOption: DisplayOption, factDisplayName: DiscussionTitles) {
        print("presentation changed: \(displayOption), \(factDisplayName)")
        self.pickedDisplayOption = displayOption
        self.pickedDiscussionTitles = factDisplayName
    }
    
    func sourceChanged(source: String) {
        if source == "" {
            self.sourceLink = nil
        } else {
            self.sourceLink = source
        }
    }
    
    func selectedFact(community: Community, isViewAlreadyLoaded: Bool) {
        guard let communityID = community.id else {
            return
        }
        
        self.selectedTopicIDForSingleTopicAddOn = communityID
        
        if let indexPath = self.indexPathOfChooseTopicCell,
            let cell = tableView.cellForRow(at: indexPath) as? NewCommunityLinkedCommunityCell,
            let imageURL = community.imageURL,
            let url = URL(string: imageURL) {
            
            cell.imageURL = url
            cell.choosenTopicLabel.text = community.title
        }
    }
}

extension NewCommunityItemTableVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate, CropViewControllerDelegate {
    
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
    var pickedFactDisplayNames: DiscussionTitles = .proContra
    
    var pickedDisplayOption: DisplayOption? {
        didSet {
            if let option = pickedDisplayOption {
                if option == .discussion {
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
            self.pickedDisplayOption = .discussion
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
                switch fact.discussionTitles {
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
