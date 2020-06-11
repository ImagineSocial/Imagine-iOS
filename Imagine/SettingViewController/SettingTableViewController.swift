//
//  SettingTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 23.05.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

protocol SettingCellDelegate {
    func gotChanged(type: SettingChangeType, value: Any)
    func selectPicture(type: SettingChangeType, forIndexPath: IndexPath)
}

class TopicSetting {
    var title: String
    var description: String
    var OP: String
    var isAddOnFirstView = false
    var imageURL: String?
    
    init(title: String, description: String, OP: String) {
        self.title = title
        self.description = description
        self.OP = OP
    }
}

class UserSetting {
    var name: String
    var statusText: String?
    var OP: String
    var imageURL: String?
    
    var youTubeLink: String?
    var patreonLink: String?
    var instagramLink: String?
    var twitterLink: String?
    
    init(name: String, OP: String) {
        self.name = name
        self.OP = OP
    }
}

class TableViewSetting {
    var headerText: String?
    var footerText: String?
    var cells = [TableViewSettingCell]()
}

class TableViewSettingCell {
    var type: SettingCellType
    var settingChange: SettingChangeType
    var titleText: String?
    var characterLimit: Int?
    var value: Any
    
    init(value: Any, type:SettingCellType, settingChange: SettingChangeType) {
        self.value = value
        self.type = type
        self.settingChange = settingChange
    }
}

enum SettingCellType {
    case imageCell
    case textCell
    case switchCell
}

enum SettingChangeType {
    case changeTopicTitle
    case changeTopicAddOnsAsFirstView
    case changeTopicPicture
    case changeTopicDescription
    case changeUserPicture
    case changeUserStatusText
    case changeUserInstagramLink
    case changeUserPatreonLink
    case changeUserYouTubeLink
    case changeUserTwitterLink
}

enum DestinationForSettings {
    case community
    case userProfile
}

class SettingTableViewController: UITableViewController {
    
    let db = Firestore.firestore()
    let storDB = Storage.storage().reference()
    
    var imagePicker = UIImagePickerController()
    
    var topic: Fact?
    var topicSetting: TopicSetting?
    
    var user: User?
    var userSetting: UserSetting?

    let imageSettingIdentifier = "SettingImageCell"
    let textSettingIdentifier = "SettingTextCell"
    let switchSettingIdentifier = "SettingSwitchCell"
    
    let settingHeaderIdentifier = "SettingHeader"
    let settingFooterIdentifier = "SettingFooter"
    
    var settings = [TableViewSetting]()
    var settingFor: DestinationForSettings = .community
    
    var indexPathOfImageSettingCell: IndexPath?
    var changeTypeOfImageSettingCell: SettingChangeType?

    override func viewDidLoad() {
        super.viewDidLoad()

        imagePicker.delegate = self
        tableView.register(UINib(nibName: "SettingHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: settingHeaderIdentifier)
        tableView.register(UINib(nibName: "SettingFooterView", bundle: nil), forHeaderFooterViewReuseIdentifier: settingFooterIdentifier)
        
        getData()
    }
    
    func getData() {
        if let topic = topic {
            let ref = db.collection("Facts").document(topic.documentID)
            ref.getDocument { (snap, err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    if let snap = snap {
                        if let data = snap.data() {
                            guard let title = data["name"] as? String, let description = data["description"] as? String, let OP = data["OP"] as? String else { return }
                            
                            let topicSetting = TopicSetting(title: title, description: description, OP: OP)
                            
                            if let isAddOnFirstView = data["isAddOnFirstView"] as? Bool {
                                if isAddOnFirstView == true {
                                    topicSetting.isAddOnFirstView = isAddOnFirstView
                                }
                            }
                            if let imageURL = data["imageURL"] as? String {
                                topicSetting.imageURL = imageURL
                            }
                            self.topicSetting = topicSetting
                            self.setUpViewController()
                        }
                    }
                }
            }
        } else if let user = user {
            let userSetting = UserSetting(name: user.displayName, OP: user.userUID)
            
            let ref = db.collection("Users").document(user.userUID)
            ref.getDocument { (snap, err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    if let snap = snap {
                        if let data = snap.data() {
                                                        
                            if let instagramLink = data["instagramLink"] as? String {
                                userSetting.instagramLink = instagramLink
                            }
                            if let patreonLink = data["patreonLink"] as? String {
                                userSetting.patreonLink = patreonLink
                            }
                            if let youTubeLink = data["youTubeLink"] as? String {
                                userSetting.youTubeLink = youTubeLink
                            }
                            if let twitterLink = data["twitterLink"] as? String {
                                userSetting.twitterLink = twitterLink
                            }
                            userSetting.imageURL = user.imageURL
                            userSetting.statusText = user.statusQuote
                            self.userSetting = userSetting
                            self.setUpViewController()
                        }
                    }
                }
            }
        }
    }
    
    func setUpViewController() {
        switch settingFor {
        case .community:
            let setting = TableViewSetting()
            setting.headerText = "Community-Einstellungen"
            if let topicSetting = topicSetting {
                let imageCell = TableViewSettingCell(value: topicSetting.imageURL, type: .imageCell, settingChange: .changeTopicPicture)
                let nameCell = TableViewSettingCell(value: topicSetting.title, type: .textCell, settingChange: .changeTopicTitle)
                nameCell.titleText = "Titel:"
                nameCell.characterLimit = Constants.characterLimits.factTitleCharacterLimit
                
                let descriptionCell = TableViewSettingCell(value: topicSetting.description, type: .textCell, settingChange: .changeTopicDescription)
                descriptionCell.titleText = "Beschreibung:"
                descriptionCell.characterLimit = Constants.characterLimits.factDescriptionCharacterLimit
                
                let addOnAsFirstViewCell = TableViewSettingCell(value: topicSetting.isAddOnFirstView, type: .switchCell, settingChange: .changeTopicAddOnsAsFirstView)
                addOnAsFirstViewCell.titleText = "Themen Ansicht als Startbildschirm"
                setting.footerText = "Wird deine Community besser von den Unterthemen repräsentiert, als von den Beiträgen, wähle diese Option aus."
                
                setting.cells.append(contentsOf: [imageCell, nameCell, descriptionCell, addOnAsFirstViewCell])
                self.settings.append(setting)
                tableView.reloadData()
            }
        case .userProfile:
            let setting = TableViewSetting()
            setting.headerText = "Profil-Einstellungen"
            if let userSetting = userSetting {
                let imageCell = TableViewSettingCell(value: userSetting.imageURL, type: .imageCell, settingChange: .changeUserPicture)
                
                let statusCell = TableViewSettingCell(value: userSetting.statusText, type: .textCell, settingChange: .changeUserStatusText)
                statusCell.characterLimit = Constants.characterLimits.userStatusTextCharacterLimit
                statusCell.titleText = "Steckbrief:"
                
                let socialMediaSetting = TableViewSetting()
                socialMediaSetting.headerText = "Social Media Button"
                let instaCell = TableViewSettingCell(value: userSetting.instagramLink, type: .textCell, settingChange: .changeUserInstagramLink)
                instaCell.titleText = "Instagram:"
                let patreonCell = TableViewSettingCell(value: userSetting.patreonLink, type: .textCell, settingChange: .changeUserPatreonLink)
                patreonCell.titleText = "Patreon:"
                let youTubeCell = TableViewSettingCell(value: userSetting.youTubeLink, type: .textCell, settingChange: .changeUserYouTubeLink)
                youTubeCell.titleText = "YouTube:"
                let twitterCell = TableViewSettingCell(value: userSetting.twitterLink, type: .textCell, settingChange: .changeUserTwitterLink)
                twitterCell.titleText = "Twitter:"
                socialMediaSetting.footerText = "Gib einen Link zu den jeweiligen Profilen ein, um einen Button in deinem Profil zu erhalten. Weise so die Besucher auf deine anderen Social-Media Profile hin oder promote so deine persönlichen Favoriten."
                
                socialMediaSetting.cells.append(contentsOf: [patreonCell, youTubeCell, instaCell, twitterCell])
                setting.cells.append(contentsOf: [imageCell, statusCell])
                
                self.settings.append(contentsOf: [setting, socialMediaSetting])
                tableView.reloadData()
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return settings.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let setting = settings[section]
        return setting.cells.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let setting = settings[indexPath.section]
        let config = setting.cells[indexPath.row]
        
        switch config.type {
        case .imageCell:
            if let cell = tableView.dequeueReusableCell(withIdentifier: imageSettingIdentifier, for: indexPath) as? SettingImageCell {
                cell.delegate = self
                cell.config = config
                cell.indexPath = indexPath
                
                return cell
            }
        case .textCell:
            if let cell = tableView.dequeueReusableCell(withIdentifier: textSettingIdentifier, for: indexPath) as? SettingTextCell {
                cell.delegate = self
                cell.config = config
                
                return cell
            }
        case .switchCell:
            if let cell = tableView.dequeueReusableCell(withIdentifier: switchSettingIdentifier, for: indexPath) as? SettingSwitchCell {
                cell.delegate = self
                cell.config = config
                
                return cell
            }
        }
        
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let setting = settings[indexPath.section]
        let cell = setting.cells[indexPath.row]
        
        switch cell.type {
        case .textCell:
            switch cell.settingChange {
            case .changeTopicDescription:
                return 80
            case .changeUserStatusText:
                return 80
            default:
                return 35
            }
        default:
            return UITableView.automaticDimension
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let setting = settings[section]
        
        if let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: settingHeaderIdentifier) as? SettingHeaderView {
                        
            if let headerText = setting.headerText {
                headerView.settingTitleLabel.text = headerText
            } else {
                headerView.settingTitleLabel.text = ""
            }
            return headerView
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let setting = settings[section]
        if let _ = setting.headerText {
            return UITableView.automaticDimension
        } else {
            return 50
        }
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        return 40
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let setting = settings[section]
        if let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: settingFooterIdentifier) as? SettingFooterView {
            
            if let footerText = setting.footerText {
                footerView.settingDescriptionLabel.text = footerText
            } else {
                footerView.settingDescriptionLabel.text = ""
            }
            
            return footerView
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let setting = settings[section]
        if let _ = setting.footerText {
            return UITableView.automaticDimension
        } else {
            return 50
        }
    }

}

extension SettingTableViewController: SettingCellDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //MARK: - ImagePicker
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.view.activityStartAnimating()
            if let indexPath = self.indexPathOfImageSettingCell {
                if let cell = tableView.cellForRow(at: indexPath) as? SettingImageCell {
                    cell.newImage = image
                }
            }
            
            
            if let topic = topic {
                if topic.imageURL != "" {
                    deletePicture()
                    compressImage(image: image)
                } else {    // If the community got no picture
                    compressImage(image: image)
                }
            } else if let user = user {
                if user.imageURL != "" {
                    deletePicture()
                    compressImage(image: image)
                } else {    // If the user got no picture
                    compressImage(image: image)
                }
            }
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func deletePicture() {  // In Firebase Storage
        if let topic = topic {
            let imageName = "\(topic.documentID).png"
            let storageRef = storDB.child("factPictures").child(imageName)
        
            self.deletePictureInStorage(storageReference: storageRef)
        
        } else if let user = user {
            let imageName = "\(user.userUID).profilePicture.png"
            let storageRef = storDB.child("profilePictures").child(imageName)
            
            self.deletePictureInStorage(storageReference: storageRef)
        }
    }
    
    func deletePictureInStorage(storageReference: StorageReference) {
        storageReference.delete { (err) in
            if let err = err {
                print("We have an error deleting the old profile Picture: \(err.localizedDescription)")
            } else {
                print("Picture Deleted")
            }
        }
    }
    
    func compressImage(image: UIImage) {
        if let fullImage = image.jpegData(compressionQuality: 1) {
            let data = NSData(data: fullImage)
            
            let imageSize = data.count/1000
            
            
            if imageSize <= 500 {   // When the imageSize is under 500kB it wont be compressed, because you can see the difference
                // No compression
                self.savePicture(imageData: fullImage)
            } else if imageSize <= 1000 {
                if let image = image.jpegData(compressionQuality: 0.4) {
                    
                    self.savePicture(imageData: image)
                }
            } else if imageSize <= 2000 {
                if let image = image.jpegData(compressionQuality: 0.25) {
                    
                    self.savePicture(imageData: image)
                }
            } else {
                if let image = image.jpegData(compressionQuality: 0.1) {
                    
                    self.savePicture(imageData: image)
                }
            }
        }
    }
    
    
    func savePicture(imageData: Data) {
        if let topic = topic {
            let imageName = "\(topic.documentID).png"
            let storageRef = storDB.child("factPictures").child(imageName)
            
            savePictureInStorage(storageReference: storageRef, imageData: imageData)
            
        } else if let user = user {
            let imageName = "\(user.userUID).profilePicture.png"
            let storageRef = storDB.child("profilePictures").child(imageName)
            
            savePictureInStorage(storageReference: storageRef, imageData: imageData)
        }
    }
    
    func savePictureInStorage(storageReference: StorageReference, imageData: Data) {
        
        storageReference.putData(imageData, metadata: nil, completion: { (metadata, error) in
            if let error = error {
                print(error)
                return
            } else {
                print("Picture Saved")
            }
            storageReference.downloadURL(completion: { (url, err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                    return
                } else {
                    if let url = url {
                        if let type = self.changeTypeOfImageSettingCell {
                            self.gotChanged(type: type, value: url.absoluteString)
                        }
                    }
                }
            })
        })
    }
    
    func selectPicture(type: SettingChangeType, forIndexPath: IndexPath) {
        self.indexPathOfImageSettingCell = forIndexPath
        self.changeTypeOfImageSettingCell = type
        
        imagePicker.sourceType = .photoLibrary
        self.present(imagePicker, animated: true) {
            //Complete
        }
    }
    
    func gotChanged(type: SettingChangeType, value: Any) {
        var firestoreKey = ""
        var firestoreValue: Any = ""
        
        switch type {
        case .changeTopicPicture:
            firestoreKey = "imageURL"
            if let string = value as? String {
                firestoreValue = string
            } else {
                return
            }
        case .changeTopicTitle:
            firestoreKey = "name"
            if let string = value as? String {
                firestoreValue = string
            } else {
                return
            }
        case .changeTopicDescription:
            firestoreKey = "description"
            if let string = value as? String {
                firestoreValue = string
            } else {
                return
            }
        case .changeTopicAddOnsAsFirstView:
            firestoreKey = "isAddOnFirstView"
            if let bool = value as? Bool {
                firestoreValue = bool
            } else {
                return
            }
        case .changeUserPicture:
            firestoreKey = "profilePictureURL"
            
            if let string = value as? String {
                firestoreValue = string
            }
        case .changeUserStatusText:
            firestoreKey = "statusText"
            
            if let string = value as? String {
                firestoreValue = string
            }
        case .changeUserInstagramLink:
            firestoreKey = "instagramLink"
            
            if let string = value as? String {
                firestoreValue = string
            }
        case .changeUserPatreonLink:
            firestoreKey = "patreonLink"
            
            if let string = value as? String {
                firestoreValue = string
            }
        case .changeUserYouTubeLink:
            firestoreKey = "youTubeLink"
            
            if let string = value as? String {
                firestoreValue = string
            }
        case .changeUserTwitterLink:
            firestoreKey = "twitterLink"
            
            if let string = value as? String {
                firestoreValue = string
            }
        }
        
        if firestoreKey != "" {
            changeDataInFirestore(data: [firestoreKey: firestoreValue])
        } else {
            print("Dont have a valid Key:Value pair")
        }
    }
    
    func changeDataInFirestore(data: [String: Any]) {
        if let topic = topic {
            let ref = db.collection("Facts").document(topic.documentID)
            ref.updateData(data) { (err) in
                if let error = err {
                    print("We could not update the data: \(error.localizedDescription)")
                } else {
                    self.view.activityStopAnimating()
                }
            }
        } else if let user = user {
            let ref = db.collection("Users").document(user.userUID)
            ref.updateData(data) { (err) in
                if let error = err {
                    print("We could not update the data: \(error.localizedDescription)")
                } else {
                    self.view.activityStopAnimating()
                }
            }
        } else {
            print("We got no mfn topic nor user")
        }
    }
}

class SettingImageCell: UITableViewCell {
    
    @IBOutlet weak var settingImageView: DesignableImage!
    
    var delegate: SettingCellDelegate?
    var indexPath: IndexPath?
    
    var newImage: UIImage? {
        didSet {
            settingImageView.image = newImage!
        }
    }
    
    var config: TableViewSettingCell? {
        didSet {
            if let setting = config {
                if let imageURL = setting.value as? String {
                    if let url = URL(string: imageURL) {
                        settingImageView.sd_setImage(with: url, completed: nil)
                    } else {
                        settingImageView.image = UIImage(named: "default")
                    }
                }
            }
        }
    }
    
    @IBAction func changePictureTapped(_ sender: Any) {
        if let indexPath = indexPath, let setting = config {
            delegate?.selectPicture(type: setting.settingChange, forIndexPath: indexPath)
        }
    }
    
    func pictureSelected(imageURL: String) {
        if let setting = config {
            delegate?.gotChanged(type: setting.settingChange, value: imageURL)
        }
    }
    
}

class SettingTextCell: UITableViewCell, UITextViewDelegate {
    
    @IBOutlet weak var settingTitleLabel: UILabel!
    @IBOutlet weak var settingTextView: UITextView!
    @IBOutlet weak var characterLimitLabel: UILabel!
    
    var delegate: SettingCellDelegate?
    
    var config: TableViewSettingCell? {
        didSet {
            if let setting = config {
                settingTitleLabel.text = setting.titleText
                if let maxCharacter = setting.characterLimit {
                    if let value = setting.value as? String {
                        let characterLeft = maxCharacter-value.count
                        characterLimitLabel.text = String(characterLeft)
                    }
                } else {
                    characterLimitLabel.isHidden = true
                }
                if let value = setting.value as? String {
                    settingTextView.text = value
                }
            }
        }
    }
    
    func newTextReady(text: String) {
        if let setting = config {
            delegate?.gotChanged(type: setting.settingChange, value: text)
        }
    }
    
    override func awakeFromNib() {
        settingTextView.delegate = self
    }
    
    //TextViewDelegate
    func textViewDidEndEditing(_ textView: UITextView) {
        if let text = textView.text {
            if text != "" {
                newTextReady(text: text)
            }
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {       // If you hit return
            textView.resignFirstResponder()
            return false
        }
        if let setting = config {
            if let maxCharacter = setting.characterLimit {
                
                return textView.text.count + (text.count - range.length) <= maxCharacter  // Text no longer than x characters
            }
        }
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if let setting = config {
            if let maxCharacter = setting.characterLimit {
                let characterLeft = maxCharacter-textView.text.count
                self.characterLimitLabel.text = String(characterLeft)
            }
        }
    }
    
}

class SettingSwitchCell: UITableViewCell {
    
    @IBOutlet weak var settingTitleLabel: UILabel!
    @IBOutlet weak var settingSwitch: UISwitch!
    
    var delegate: SettingCellDelegate?
    
    var config: TableViewSettingCell? {
        didSet {
            if let setting = config {
                settingTitleLabel.text = setting.titleText
                
                if let value = setting.value as? Bool {
                    settingSwitch.isOn = value
                }
            }
        }
    }
    
    @IBAction func settingSwitchChanged(_ sender: Any) {
        if let setting = config {
            let switchState = settingSwitch.isOn
            delegate?.gotChanged(type: setting.settingChange, value: switchState)
        }
    }
}

class SettingHeaderView: UITableViewHeaderFooterView {
    @IBOutlet weak var settingTitleLabel: UILabel!
    
}

class SettingFooterView: UITableViewHeaderFooterView {
    
    @IBOutlet weak var settingDescriptionLabel: UILabel!
    
}
