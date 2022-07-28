//
//  SettingTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 23.05.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import MapKit
import CropViewController
import Photos
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

protocol SettingCellDelegate {
    func gotChanged(type: SettingChangeType, value: Any)
    func selectPicture(type: SettingChangeType, forIndexPath: IndexPath)
    func selectLocation(location: Location?, type: SettingChangeType, forIndexPath: IndexPath)
}

protocol ChoosenLocationDelegate {
    func gotLocation(location: Location)
}

enum TableViewSettingType {
    case normal
    case changeOrder
}

enum SettingCellType {
    case imageCell
    case textCell
    case switchCell
    case datePickerCell
    case locationCell
}

enum DestinationForSettings {
    case community
    case addOn
    case userProfile
}

class SettingTableViewController: UITableViewController {
    
    //MARK:- Variables
    let db = FirestoreRequest.shared.db
    let storDB = Storage.storage().reference()
    
    let postHelper = FirestoreRequest.shared
    let communityHelper = CommunityHelper.shared
    let dataHelper = DataRequest()
    var imagePicker = UIImagePickerController()
    
    var topic: Community?
    var topicSetting: TopicSetting?
    
    var user: User?
    var userSetting: UserSetting?
    
    var addOn: AddOn?
    var addOnSetting: AddOnSetting?
    
    var addOnItemsOrderArray: [String]?

    let imageSettingIdentifier = "SettingImageCell"
    let textSettingIdentifier = "SettingTextCell"
    let dateSettingIdentifier = "SettingDateCell"
    let switchSettingIdentifier = "SettingSwitchCell"
    let pickOrderSettingIdentifier = "SettingPickOrderCell"
    let locationSettingIdentifier = "SettingLocationCell"
    
    let settingHeaderIdentifier = "SettingHeader"
    let settingFooterIdentifier = "SettingFooter"
    
    var settings = [TableViewSetting]()
    var settingFor: DestinationForSettings = .community
    
    var indexPathOfImageSettingCell: IndexPath?
    var changeTypeOfImageSettingCell: SettingChangeType?
    
    var locationChangeType: SettingChangeType?
    var locationIndexPath: IndexPath?

    //MARK:- View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        imagePicker.delegate = self
        tableView.register(UINib(nibName: "SettingHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: settingHeaderIdentifier)
        tableView.register(UINib(nibName: "SettingFooterView", bundle: nil), forHeaderFooterViewReuseIdentifier: settingFooterIdentifier)
        
        getData()
    }
    
    //MARK:- Get Data
    func getData() {
        
        // Set the custom settings and fetch additional information if neccessarry
        
        if let community = topic, let communityID = community.id {
            
            let ref = FirestoreReference.documentRef(.communities, documentID: communityID, language: community.language)
            
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
        } else if let user = user, let userID = user.uid {
            let userSetting = UserSetting(name: user.name ?? "", OP: userID)
            
            let ref = db.collection("Users").document(userID)
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
                            if let songwhipLink = data["songwhipLink"] as? String {
                                userSetting.songwhipLink = songwhipLink
                            }
                            if let instagramDescription = data["instagramDescription"] as? String {
                                userSetting.instagramDescription = instagramDescription
                            }
                            if let patreonDescription = data["patreonDescription"] as? String {
                                userSetting.patreonDescription = patreonDescription
                            }
                            if let youTubeDescription = data["youTubeDescription"] as? String {
                                userSetting.youTubeDescription = youTubeDescription
                            }
                            if let twitterDescription = data["twitterDescription"] as? String {
                                userSetting.twitterDescription = twitterDescription
                            }
                            if let songwhipDescription = data["songwhipDescription"] as? String {
                                userSetting.songwhipDescription = songwhipDescription
                            }
                            
                            if let birthday = data["birthday"] as? Timestamp {
                                let date = birthday.dateValue()
                                userSetting.birthday = date
                            }
                            
                            if let locationName = data["locationName"] as? String, let locationCoordinate = data["locationCoordinate"] as? GeoPoint {
                                
                                let geoPoint = GeoPoint(latitude: locationCoordinate.latitude, longitude: locationCoordinate.longitude)
                                let location = Location(title: locationName, geoPoint: geoPoint)
                                
                                userSetting.location = location
                            }
                            if let locationIsPublic = data["locationIsPublic"] as? Bool {
                                userSetting.locationIsPublic = locationIsPublic
                            }
                            
                            userSetting.imageURL = user.imageURL
                            userSetting.statusText = user.statusText
                            self.userSetting = userSetting
                            self.setUpViewController()
                        }
                    }
                }
            }
        } else if let addOn = addOn {
            let addOnSetting = AddOnSetting(style: addOn.style, community: addOn.community, addOnDocumentID: addOn.documentID, description: addOn.description, items: addOn.items)
            
            addOnSetting.title = addOn.headerTitle
            addOnSetting.imageURL = addOn.imageURL
            addOnSetting.itemOrder = addOn.itemOrder
            
            self.addOnSetting = addOnSetting
            self.setUpViewController()
        }
    }
    
    //MARK:- Set Up View and Data
    
    func setUpViewController() {
        
        // Add the custom SettingCells with the current database data
        switch settingFor {
        case .community:
            let setting = TableViewSetting(type: .normal, headerText: NSLocalizedString("setting_community_header_text", comment: "community settings"))
            
            if let topicSetting = topicSetting {
                let imageCell = TableViewSettingCell(value: topicSetting.imageURL ?? "", type: .imageCell, settingChange: .changeTopicPicture)
                let nameCell = TableViewSettingCell(value: topicSetting.title, type: .textCell, settingChange: .changeTopicTitle)
                nameCell.titleText = NSLocalizedString("title:", comment: "title:")
                nameCell.characterLimit = Constants.characterLimits.communityTitleCharacterLimit
                
                let descriptionCell = TableViewSettingCell(value: topicSetting.description, type: .textCell, settingChange: .changeTopicDescription)
                descriptionCell.titleText = NSLocalizedString("description:", comment: "description:")
                descriptionCell.characterLimit = Constants.characterLimits.communityDescriptionCharacterLimit
                
                let addOnAsFirstViewCell = TableViewSettingCell(value: topicSetting.isAddOnFirstView, type: .switchCell, settingChange: .changeTopicAddOnsAsFirstView)
                addOnAsFirstViewCell.titleText = NSLocalizedString("setting_community_addOn_as_start", comment: "as startview?")
                setting.footerText = NSLocalizedString("setting_community_addOn_as_start_description", comment: "description what that means")
                
                setting.cells.append(contentsOf: [imageCell, nameCell, descriptionCell, addOnAsFirstViewCell])
                self.settings.append(setting)
                tableView.reloadData()
            }
        case .userProfile:
            let setting = TableViewSetting(type: .normal, headerText: NSLocalizedString("setting_user_header_text", comment: "user settings:"))

            if let userSetting = userSetting {
                let imageCell = TableViewSettingCell(value: userSetting.imageURL ?? "", type: .imageCell, settingChange: .changeUserPicture)
                
                let statusCell = TableViewSettingCell(value: userSetting.statusText ?? "", type: .textCell, settingChange: .changeUserStatusText)
                statusCell.characterLimit = Constants.characterLimits.userStatusTextCharacterLimit
                statusCell.titleText = NSLocalizedString("setting_user_personal_bio", comment: "write about yourself")
                
                let socialMediaSetting = TableViewSetting(type: .normal, headerText: "Social Media Buttons")
                
                let instaCell = TableViewSettingCell(value: userSetting.instagramLink ?? "", type: .textCell, settingChange: .changeUserInstagramLink)
                instaCell.titleText = "Instagram:"
                let instaDescrCell = TableViewSettingCell(value: userSetting.instagramDescription ?? "", type: .textCell, settingChange: .changeUserInstagramDescription)
                instaDescrCell.titleText = "Beschreibung:"
                instaDescrCell.characterLimit = Constants.characterLimits.socialMediaDescriptionCharacterLimit
                let patreonCell = TableViewSettingCell(value: userSetting.patreonLink ?? "", type: .textCell, settingChange: .changeUserPatreonLink)
                patreonCell.titleText = "Patreon:"
                let patreonDescrCell = TableViewSettingCell(value: userSetting.patreonDescription ?? "", type: .textCell, settingChange: .changeUserPatreonDescription)
                patreonDescrCell.titleText = "Beschreibung:"
                patreonDescrCell.characterLimit = Constants.characterLimits.socialMediaDescriptionCharacterLimit
                let youTubeCell = TableViewSettingCell(value: userSetting.youTubeLink ?? "", type: .textCell, settingChange: .changeUserYouTubeLink)
                youTubeCell.titleText = "YouTube:"
                let youTubeDescrCell = TableViewSettingCell(value: userSetting.youTubeDescription ?? "", type: .textCell, settingChange: .changeUserYouTubeDescription)
                youTubeDescrCell.titleText = "Beschreibung:"
                youTubeDescrCell.characterLimit = Constants.characterLimits.socialMediaDescriptionCharacterLimit
                let twitterCell = TableViewSettingCell(value: userSetting.twitterLink ?? "", type: .textCell, settingChange: .changeUserTwitterLink)
                twitterCell.titleText = "Twitter:"
                let twitterDescrCell = TableViewSettingCell(value: userSetting.twitterDescription ?? "", type: .textCell, settingChange: .changeUserTwitterDescription)
                twitterDescrCell.titleText = "Beschreibung:"
                twitterDescrCell.characterLimit = Constants.characterLimits.socialMediaDescriptionCharacterLimit
                let songwhipCell = TableViewSettingCell(value: userSetting.songwhipLink ?? "", type: .textCell, settingChange: .changeUserSongwhipLink)
                songwhipCell.titleText = "Songwhip:"
                let songwhipDescrCell = TableViewSettingCell(value: userSetting.songwhipDescription ?? "", type: .textCell, settingChange: .changeUserSongwhipDescription)
                songwhipDescrCell.titleText = "Beschreibung:"
                songwhipDescrCell.characterLimit = Constants.characterLimits.socialMediaDescriptionCharacterLimit
                socialMediaSetting.footerText = NSLocalizedString("setting_social_media_button_description", comment: "what are these about?")
                
                let voluntarySettings = TableViewSetting(type: .normal, headerText: NSLocalizedString("setting_user_personal_info", comment: "personal infos"))
                voluntarySettings.footerText = NSLocalizedString("setting_user_personal_info_description", comment: "what is it about?")
                
                let ageCell = TableViewSettingCell(value: userSetting.birthday ?? "", type: .datePickerCell, settingChange: .changeUserAge)
                ageCell.titleText = NSLocalizedString("setting_user_birthday", comment: "Birthday:")
                let locationCell = TableViewSettingCell(value: userSetting.location ?? "", type: .locationCell, settingChange: .changeUserLocation)
                locationCell.titleText = "Location:"
                let locationIsPublicCell = TableViewSettingCell(value: userSetting.locationIsPublic, type: .switchCell, settingChange: .changeUserLocationPublicity)
                locationIsPublicCell.titleText = NSLocalizedString("setting_user_location_public", comment: "is location public`?")
                
                voluntarySettings.cells.append(contentsOf: [ageCell, locationCell, locationIsPublicCell])
                
                socialMediaSetting.cells.append(contentsOf: [youTubeCell, youTubeDescrCell, instaCell, instaDescrCell, twitterCell, twitterDescrCell, patreonCell, patreonDescrCell, songwhipCell, songwhipDescrCell])
                setting.cells.append(contentsOf: [imageCell, statusCell])
                
                self.settings.append(contentsOf: [setting, socialMediaSetting, voluntarySettings])
                tableView.reloadData()
            }
        case .addOn:
            let setting = TableViewSetting(type: .normal, headerText: NSLocalizedString("setting_addOn_header_text", comment: "Topic settings:"))

            if let addOnSetting = addOnSetting {
                let imageCell = TableViewSettingCell(value: addOnSetting.imageURL ?? "", type: .imageCell, settingChange: .changeAddOnPicture)
                
                let titleCell = TableViewSettingCell(value: addOnSetting.title ?? "", type: .textCell, settingChange: .changeAddOnTitle)
                titleCell.characterLimit = Constants.characterLimits.addOnTitleCharacterLimit
                titleCell.titleText = NSLocalizedString("title:", comment: "title:")
                
                let descriptionCell = TableViewSettingCell(value: addOnSetting.description, type: .textCell, settingChange: .changeAddOnDescription)
                descriptionCell.characterLimit = Constants.characterLimits.addOnDescriptionCharacterLimit
                descriptionCell.titleText = NSLocalizedString("description:", comment: "descriprion:")
                
                setting.cells.append(contentsOf: [imageCell, titleCell, descriptionCell])
                self.settings.append(setting)
                
                if addOnSetting.style == .collection {
                    let orderSetting = TableViewSetting(type: .changeOrder, headerText: NSLocalizedString("setting_addOn_change_order", comment: "change order as you like"))
                    orderSetting.addOnItems = addOnSetting.items
                    self.getAddOnItemsForOrderArrangement(items: orderSetting.addOnItems)
                    
                    self.tableView.isEditing = true
                    
                    self.settings.append(orderSetting)
                }
                
                self.tableView.reloadData()
            }
        }
    }
    
    
    //MARK: - AddOnData for Ordering
    var itemList = [AddOnItem]()
    var listCount = 0
    
    func getAddOnItemsForOrderArrangement(items: [AddOnItem]) {
        self.listCount = items.count
        
        for item in items {
            if let post = item.item as? Post, let documentID = post.documentID {
                self.postHelper.loadPost(post: post) { (post) in
                    if let post = post {
                        let item = AddOnItem(documentID: documentID, item: post)
                        self.itemList.append(item)
                        self.addNewList()
                    } else {
                        print("Aint nobody got a post!")
                    }
                }
            } else if let community = item.item as? Community {
                self.communityHelper.loadCommunity(community) { community in
                    if let community = community, let communityID = community.id {
                        let item = AddOnItem(documentID: communityID, item: community)
                        self.itemList.append(item)
                        self.addNewList()
                    } else {
                        print(" Aint nobody got a community!")
                    }
                }
            }
        }
    }
    
    func addNewList() {
        if itemList.count == listCount {        //When ready
            if let setting = self.settings.first(where: {$0.type == .changeOrder}) {
                
                if let addOnSetting = addOnSetting {
                    if let orderList = addOnSetting.itemOrder {
                        let sorted = itemList.compactMap { obj in   // Compare the orderList against the documentIDs
                        orderList.index(of: obj.documentID).map { idx in (obj, idx) }
                        }.sorted(by: { $0.1 < $1.1 } ).map { $0.0 }
                        
                        setting.addOnItems = sorted
                        self.tableView.reloadData()
                    } else {
                        var newOrderArray = [String]()
                        
                        itemList = itemList.reversed()
                        for item in itemList {
                            newOrderArray.append(item.documentID)
                        }
                        
                        addOnSetting.itemOrder = newOrderArray
                        self.gotChanged(type: .changeAddOnItemOrderArray, value: newOrderArray)
                        
                        setting.addOnItems = itemList
                        self.tableView.reloadData()
                    }
                }
            } else {
                print(" Aint nobody got a changeOrder Section!")
            }
        } else {
            print("Not high enough")
        }
    }

    // MARK: - TableView Data Source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return settings.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let setting = settings[section]
        switch setting.type {
        case .normal:
            return setting.cells.count
        case .changeOrder:
            return setting.addOnItems.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let setting = settings[indexPath.section]
        
        switch setting.type {
        case .normal:
            let config = setting.cells[indexPath.row]
            
            switch config.type {
            case .imageCell:
                if let cell = tableView.dequeueReusableCell(withIdentifier: imageSettingIdentifier, for: indexPath) as? SettingImageCell {
                    cell.delegate = self
                    cell.settingFor = settingFor
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
            case .datePickerCell:
                if let cell = tableView.dequeueReusableCell(withIdentifier: dateSettingIdentifier, for: indexPath) as? SettingDateCell {
                    cell.delegate = self
                    cell.config = config
                    
                    return cell
                }
            case .locationCell:
                if let cell = tableView.dequeueReusableCell(withIdentifier: locationSettingIdentifier, for: indexPath) as? SettingLocationCell {
                    cell.delegate = self
                    cell.config = config
                    cell.indexPath = indexPath
                    
                    return cell
                }
            }
        case .changeOrder:
            let item = setting.addOnItems[indexPath.row]
            
            print("Das ist das Item: \(item)")
            if let cell = tableView.dequeueReusableCell(withIdentifier: pickOrderSettingIdentifier, for: indexPath) as? SettingPickOrderCell {
                if let post = item.item as? Post {
                    cell.post = post
                } else if let fact = item.item as? Community {
                    cell.community = fact
                }
                
                return cell
            }
        }
        
        
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        let setting = settings[indexPath.section]
        
        if setting.type == .changeOrder {
            return true
        } else {
            return false
        }
    }
    
    //MARK:- TableView Delegate
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let setting = settings[indexPath.section]
        
        switch setting.type {
        case .normal:
            let cell = setting.cells[indexPath.row]
        
            switch cell.type {
            case .textCell:
                switch cell.settingChange {
                case .changeTopicDescription:
                    return 100
                case .changeUserStatusText:
                    return 100
                case .changeAddOnTitle:
                    return 75
                case .changeAddOnDescription:
                    return 100
                case .changeUserYouTubeDescription:
                    return 75
                case .changeUserSongwhipDescription:
                    return 75
                case .changeUserTwitterDescription:
                    return 75
                case .changeUserInstagramDescription:
                    return 75
                case .changeUserPatreonDescription:
                    return 75
                default:
                    return 40
                }
            case .datePickerCell:
                return 100
            case .locationCell:
                return 50
            default:
                return UITableView.automaticDimension
            }
        case .changeOrder:
            return 50
        }
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }

    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let reorderedRow = self.settings[sourceIndexPath.section].addOnItems.remove(at: sourceIndexPath.row)
        self.settings[destinationIndexPath.section].addOnItems.insert(reorderedRow, at: destinationIndexPath.row)

        if let addOnSetting = addOnSetting {
            if let _ = addOnSetting.itemOrder {
                var array = [String]()
                
                for item in settings[destinationIndexPath.section].addOnItems {
                    array.append(item.documentID)
                }
                print("Das ist der removedS, das ist der ganze Array: \(array)")
                self.gotChanged(type: .changeAddOnItemOrderArray, value: array)
//                let movedObject = orderArray[sourceIndexPath.row]
//                orderArray.remove(at: sourceIndexPath.row)
//                orderArray.insert(movedObject, at: destinationIndexPath.row)
//
//                print("Das ist der removedString: \(movedObject), das ist der ganze Array: \(orderArray)")
//                self.gotChanged(type: .changeAddOnItemOrderArray, value: orderArray)
            }
        }
   }
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        
        let sourceSection = sourceIndexPath.section
        let destSection = proposedDestinationIndexPath.section

        if destSection < sourceSection {
            return IndexPath(row: 0, section: sourceSection)
        } else if destSection > sourceSection {
            return IndexPath(row: self.tableView(tableView, numberOfRowsInSection:sourceSection)-1, section: sourceSection)
        }

        return proposedDestinationIndexPath
    }
    
    
    //MARK:- TableViewDelegate Header & Footer
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let setting = settings[section]
        
        if let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: settingHeaderIdentifier) as? SettingHeaderView {
                        
            
            headerView.settingTitleLabel.text = setting.headerText
            
            
            return headerView
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return UITableView.automaticDimension
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

//MARK:- Location Extension

extension SettingTableViewController: ChoosenLocationDelegate {
    
    func gotLocation(location: Location) {
        if let type = self.locationChangeType {
            gotChanged(type: type, value: location)
            if let indexPath = locationIndexPath {
                if let cell = tableView.cellForRow(at: indexPath) as? SettingLocationCell {
                    cell.choosenLocationLabel.text = location.title
                }
            }
        }
    }
}

//MARK:- Image Picker & CropView Extension

extension SettingTableViewController: UIImagePickerControllerDelegate, CropViewControllerDelegate {
    
    //MARK: UIImagePicker
    
    func showImagePicker() {
        imagePicker.sourceType = .photoLibrary
        self.present(imagePicker, animated: true) {
            //Complete
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imagePicker.dismiss(animated: true, completion: nil)
            showCropView(image: image)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    //MARK: CropViewController
    
    func showCropView(image: UIImage) {
        let cropViewController = CropViewController(image: image)
        cropViewController.delegate = self
        if let _ = addOn {
            cropViewController.aspectRatioPreset = .preset16x9
        } else if let _ = topic {    //User & Topic Image must be square
            cropViewController.aspectRatioPreset = .preset16x9
        } else {
            cropViewController.aspectRatioPreset = .presetSquare
        }
        cropViewController.aspectRatioLockEnabled = true
        navigationController?.pushViewController(cropViewController, animated: true)
    }
    
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        
        if let indexPath = self.indexPathOfImageSettingCell {
            if let cell = tableView.cellForRow(at: indexPath) as? SettingImageCell {
                cell.newImage = image
            }
        }
        
        self.view.activityStartAnimating()
        
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
        } else if let addOn = addOn {
            if addOn.imageURL != "" {
                deletePicture()
                compressImage(image: image)
            } else {
                compressImage(image: image)
            }
        }
        
        navigationController?.popToViewController(self, animated: true)
    }
    
    //MARK: Change User URL
    
    func savePictureURLInUserAuth(imageURL: String) {
        
        guard let user = Auth.auth().currentUser, let url = URL(string: imageURL) else {
            return
        }
        let changeRequest = user.createProfileChangeRequest()
        
        changeRequest.photoURL = url

        changeRequest.commitChanges { error in
            if error != nil {
                // An error happened.
                print("Wir haben einen error beim changeRequest: \(String(describing: error?.localizedDescription))")
            } else {
                // Profile updated.
                print("changeRequest hat geklappt")
            }
        }
    }
    
    //MARK: Save Picture in Storage
    
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
    
    func savePicture(imageData: Data) {
        if let topic = topic, let id = topic.id {
            let imageName = "\(id).png"
            let storageRef = storDB.child("factPictures").child(imageName)
            
            savePictureInStorage(storageReference: storageRef, imageData: imageData)
        } else if let user = user, let uid = user.uid {
            let imageName = "\(uid).profilePicture.png"
            let storageRef = storDB.child("profilePictures").child(imageName)
            
            savePictureInStorage(storageReference: storageRef, imageData: imageData)
        } else if let addOn = addOn {
            let imageName = "\(addOn.documentID).png"
            let storageRef = storDB.child("factPictures").child("addOnPictures").child(imageName)
            
            savePictureInStorage(storageReference: storageRef, imageData: imageData)
        }
    }
    
    //MARK: Delete Picture in Storage
    
    func deletePictureInStorage(storageReference: StorageReference) {
        storageReference.delete { (err) in
            if let err = err {
                print("We have an error deleting the old profile Picture: \(err.localizedDescription)")
            } else {
                print("Picture Deleted")
            }
        }
    }
    
    func deletePicture() {  // In Firebase Storage
        if let topic = topic, let topicID = topic.id {
            let imageName = "\(topicID).png"
            let storageRef = storDB.child("factPictures").child(imageName)
            
            self.deletePictureInStorage(storageReference: storageRef)
        
        } else if let user = user, let uid = user.uid {
            let imageName = "\(uid).profilePicture.png"
            let storageRef = storDB.child("profilePictures").child(imageName)
            
            self.deletePictureInStorage(storageReference: storageRef)
        } else if let addOn = addOn {
            let imageName = "\(addOn.documentID).png"
            let storageRef = storDB.child("factPictures").child("addOnPictures").child(imageName)
            
            self.deletePictureInStorage(storageReference: storageRef)
        }
    }
    
    
    
    //MARK: Image Helper
    func selectPicture(type: SettingChangeType, forIndexPath: IndexPath) {
        self.indexPathOfImageSettingCell = forIndexPath
        self.changeTypeOfImageSettingCell = type
        
        switch PHPhotoLibrary.authorizationStatus() {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { (status) in
                if status == .authorized {
                    self.showImagePicker()
                } else {
                    self.alert(message: NSLocalizedString("photoAccess_permission_denied_text", comment: "how you can change that"), title: "Something seems to be wrong")
                }
            }
        case .restricted, .denied:
            alert(message: NSLocalizedString("photoAccess_permission_denied_text", comment: "how you can change that"), title: "Something seems to be wrong")
        case .authorized:
            showImagePicker()
        case .limited:
            self.showImagePicker()
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
}

//MARK:- SettingCellDelegate

extension SettingTableViewController: SettingCellDelegate, UINavigationControllerDelegate {
        
    func selectLocation(location: Location?, type: SettingChangeType, forIndexPath: IndexPath) {
        self.locationChangeType = type
        self.locationIndexPath = forIndexPath
        
        let vc = MapViewController()
        vc.location = location
        vc.locationDelegate = self
        
        navigationController?.pushViewController(vc, animated: true)
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
                self.savePictureURLInUserAuth(imageURL: string)
            } else {
                return
            }
        case .changeUserStatusText:
            firestoreKey = "statusText"
            
            if let string = value as? String {
                firestoreValue = string
            } else {
                return
            }
        case .changeUserAge:
            firestoreKey = "birthday"
            
            if let date = value as? Date {
                let timestamp = Timestamp(date: date)
                firestoreValue = timestamp
            } else {
                return
            }
        case .changeUserLocation:
            
            if let location = value as? Location {
                firestoreKey = "locationName"
                firestoreValue = location.title
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.gotChanged(type: .changeUserLocation, value: location.clCoordinate)
                }
            } else if let coordinate = value as? CLLocationCoordinate2D {
                firestoreKey = "locationCoordinate"
                let geoPoint = GeoPoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
                firestoreValue = geoPoint
            } else {
                return
            }
        case .changeUserLocationPublicity:
            firestoreKey = "locationIsPublic"
            
            if let isIt = value as? Bool {
                firestoreValue = isIt
            } else {
                return
            }
        case .changeUserInstagramLink:
            firestoreKey = "instagramLink"
            
            if let string = value as? String {
                firestoreValue = string
            } else {
                return
            }
        case .changeUserPatreonLink:
            firestoreKey = "patreonLink"
            
            if let string = value as? String {
                firestoreValue = string
            } else {
                return
            }
        case .changeUserYouTubeLink:
            firestoreKey = "youTubeLink"
            
            if let string = value as? String {
                firestoreValue = string
            } else {
                return
            }
        case .changeUserTwitterLink:
            firestoreKey = "twitterLink"
            
            if let string = value as? String {
                firestoreValue = string
            } else {
                return
            }
        case .changeUserSongwhipLink:
            firestoreKey = "songwhipLink"
            
            if let string = value as? String {
                firestoreValue = string
            } else {
                return
            }
        case .changeUserInstagramDescription:
            firestoreKey = "instagramDescription"
            
            if let string = value as? String {
                firestoreValue = string
            } else {
                return
            }
        case .changeUserPatreonDescription:
            firestoreKey = "patreonDescription"
            
            if let string = value as? String {
                firestoreValue = string
            } else {
                return
            }
        case .changeUserYouTubeDescription:
            firestoreKey = "youTubeDescription"
            
            if let string = value as? String {
                firestoreValue = string
            } else {
                return
            }
        case .changeUserTwitterDescription:
            firestoreKey = "twitterDescription"
            
            if let string = value as? String {
                firestoreValue = string
            } else {
                return
            }
        case .changeUserSongwhipDescription:
            firestoreKey = "songwhipDescription"
            
            if let string = value as? String {
                firestoreValue = string
            } else {
                return
            }
        case .changeAddOnPicture:
            firestoreKey = "imageURL"
            
            if let string = value as? String {
                firestoreValue = string
            } else {
                return
            }
        case .changeAddOnTitle:
            firestoreKey = "title"
            
            if let string = value as? String {
                firestoreValue = string
            } else {
                return
            }
        case .changeAddOnDescription:
            firestoreKey = "description"
            
            if let string = value as? String {
                firestoreValue = string
            } else {
                return
            }
        case .changeAddOnItemOrderArray:
            firestoreKey = "itemOrder"
            
            if let array = value as? [String] {
                firestoreValue = array
            } else {
                return
            }
        }
        
        if firestoreKey != "" {
            changeDataInFirestore(data: [firestoreKey: firestoreValue])
        } else {
            print("Dont have a valid Key:Value pair")
        }
    }
    
    func changeDataInFirestore(data: [String: Any]) {
        if let topic = topic, let topicID = topic.id {
            let ref = FirestoreReference.documentRef(.communities, documentID: topicID, language: topic.language)
            
            ref.updateData(data) { (err) in
                if let error = err {
                    print("We could not update the data: \(error.localizedDescription)")
                } else {
                    self.view.activityStopAnimating()
                }
            }
        } else if let userID = user?.uid {
            let ref = db.collection("Users").document(userID)
            
            ref.updateData(data) { (err) in
                if let error = err {
                    print("We could not update the data: \(error.localizedDescription)")
                } else {
                    self.view.activityStopAnimating()
                }
            }
        } else if let addOn = addOn, let communityID = addOn.community.id {
            var collectionRef: CollectionReference!
            if addOn.community.language == .en {
                collectionRef = db.collection("Data").document("en").collection("topics")
            } else {
                collectionRef = db.collection("Facts")
            }
            
            let ref = collectionRef.document(communityID).collection("addOns").document(addOn.documentID)
            ref.updateData(data) { (err) in
                if let error = err {
                    print("We could not update the data: \(error.localizedDescription)")
                } else {
                    self.view.activityStopAnimating()
                }
            }
        }
        else {
            print("We got no mfn topic nor user")
        }
    }
}

//MARK:- SettingHeader
class SettingHeaderView: UITableViewHeaderFooterView {
    @IBOutlet weak var settingTitleLabel: UILabel!
    
}

//MARK:- SettingFooter
class SettingFooterView: UITableViewHeaderFooterView {
    
    @IBOutlet weak var settingDescriptionLabel: UILabel!
    
}
