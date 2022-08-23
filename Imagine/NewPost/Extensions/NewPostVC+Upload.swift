//
//  NewPostVC+Upload.swift
//  Imagine
//
//  Created by Don Malte on 14.01.22.
//  Copyright © 2022 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseStorage
import FirebaseFirestore
import FirebaseFirestoreSwift

extension NewPostVC {
    
    func shareObject() {
        guard checkIfDataIsComplete(), let cell = getCell(for: .options) as? NewPostOptionCell, let title = titleText, let userID = AuthenticationManager.shared.user?.uid else {
            return
        }
        
        view.activityStartAnimating()
        sharingEnabled = false
        
        let post = Post(type: .picture, title: title, createdAt: Date())
        
        if let description = descriptionText {
            post.description = description.customFormat
        }
        
        post.language = LanguageSelection.language
        post.tags = getTags()
        post.report = reportType
        post.votes = Votes()
        
        let option = cell.option
        
        if option.postAnonymous || option.hideProfile {
            post.options = PostDesignOption(hideProfilePicture: option.hideProfile, anonymousName: option.synonymString)
        }
        
        if let community = linkedCommunity { // If there is a fact that should be linked to this post, and append its ID to the array
            post.communityID = community.id
            post.isTopicPost = true
        }
       
        post.userID = option.postAnonymous ? anonymousString : userID
        
        if !option.postAnonymous {
            post.notificationRecipients = [userID]   //So he can set notifications off in his own post
        }
        
        post.location = location
        
        let documentReference = FirestoreReference.documentRef(isTopicPost ? .topicPosts : .posts, documentID: nil)
        
        // Dann ein File FirestoreManager-Upload wo dieses Objekt zum hochladen bearbeitet wird
        
        switch selectedOption {
        case .thought:
            post.type = .thought
            
            uploadObject(object: post, documentReference: documentReference)
        case .picture:
            guard let imageData = selectedImageFromPicker?.compressedData() else {
                return
            }
            let image = UploadImage(imageData: imageData, width: selectedImageWidth, height: selectedImageHeight)
            
            StorageManager.getImageForSinglePicture(image: image, documentID: documentReference.documentID) { image in
                guard let image = image else {
                    return
                }

                post.image = image
                
                let ratio = image.width / image.height
                
                post.type = ratio > 2 ? .panorama : .picture
                
                self.uploadObject(object: post, documentReference: documentReference)
            }
        case .multiPicture:
            StorageManager.getImagesForMultiPicture(assets: multiImageAssets, documentID: documentReference.documentID) { images in
                guard let images = images else {
                    // TODO: Error Handling. There are errors and alerts along the functions but it is very nested
                    return
                }

                post.images = images
                post.type = .multiPicture
                
                self.uploadObject(object: post, documentReference: documentReference)
            }
        case .link:
            LinkManager.getLink(url: url) { link, type in
                guard let link = link else {
                    return
                }

                post.link = link
                post.type = type
                
                self.uploadObject(object: post, documentReference: documentReference)
            }
        }
    }
    
    private func uploadObject<T: Codable>(object: T, documentReference: DocumentReference) {
        FirestoreManager.uploadObject(object: object, documentReference: documentReference) { error in
            if let error = error {
                print("We have an error: ", error.localizedDescription)
            } else {
                
                if self.linkedCommunity != nil {
                    self.uploadCommunityData(documentID: documentReference.documentID)
                }
                self.uploadUserData(documentID: documentReference.documentID)
                
                if self.savePictureAfterwards { // To Save on your device, not the best solution though
                    self.savePhotoToAlbum(image: self.selectedImageFromPicker)
                }
                
                //Finish posting process
                if self.comingFromAddOnVC {
                    let post = Post.standard
                    post.documentID = documentReference.documentID
                    post.isTopicPost = true
                    
                    self.presentAlert(post: post)
                } else {
                    self.presentAlert(post: nil)
                }
            }
        }
    }
    
    func checkIfDataIsComplete() -> Bool {
        switch selectedOption {
        case .thought:
            guard titleText != nil else {
                showMissingDataAlert(message: NSLocalizedString("missing_info_alert_title", comment: "enter title pls"))
                
                return false
            }
        case .picture:
            guard selectedImageFromPicker != nil else {
                showMissingDataAlert(message: NSLocalizedString("error_choosing_picture", comment: "got no pic"))
                
                return false
            }
        case .multiPicture:
            guard multiImageAssets.count >= 2 && multiImageAssets.count <= 3 else {
                showMissingDataAlert(message: NSLocalizedString("error_choosing_multiple_pictures_message", comment: "choose more"))
                
                return false
            }
            
        case .link:
            guard let url = url, url.isValidURL else {
                showMissingDataAlert(message: NSLocalizedString("error_no_link", comment: "no link"))
                
                return false
            }
        }
        
        return true
    }
    
    private func showMissingDataAlert(message: String) {
        self.view.activityStopAnimating()
        sharingEnabled = true
        self.alert(message: NSLocalizedString("error_no_link", comment: "no link"), title: NSLocalizedString("error_title", comment: "got error"))
    }
    
    
    
    // MARK: - Legacy
    
    
    @objc func shareTapped() {
        if !sharingEnabled { return }
        
        guard AuthenticationManager.shared.isLoggedIn else {
            self.notLoggedInAlert()
            return
        }
        
        shareObject()
    }

    
    @objc func donePosting() {
        if comingFromPostsOfFact {
            self.dismiss(animated: true) {
                self.newInstanceDelegate?.finishedCreatingNewInstance(item: nil)
            }
        } else {
            delegate?.posted()
            tabBarController?.selectedIndex = 0
        }
    }
    
    private func savePhotoToAlbum(image: UIImage?) {
        if let selectedImage = image {
            UIImageWriteToSavedPhotosAlbum(selectedImage, nil, nil, nil)
        }
    }
    
    private func uploadUserData(documentID: String) {
        guard let userID = AuthenticationManager.shared.user?.uid else { return }
        let collectionReference = FirestoreCollectionReference(document: userID, collection: "posts")
        let reference = FirestoreReference.documentRef(.users, documentID: documentID, collectionReferences: collectionReference)
        
        let isTopicPost = comingFromAddOnVC || isTopicPost
        let data = PostData(createdAt: Date(), userID: userID, language: LanguageSelection.language, isTopicPost: isTopicPost)
        
        FirestoreManager.uploadObject(object: data, documentReference: reference) { error in
            if let error = error {
                print("We have an error uploading the user data: ", error.localizedDescription)
            }
        }
    }
    
    private func uploadCommunityData(documentID: String) {
        guard let userID = AuthenticationManager.shared.user?.uid, let community = linkedCommunity, let communityID = community.id else { return }
        
        let collectionReference = FirestoreCollectionReference(document: communityID, collection: "posts")
        let reference = FirestoreReference.documentRef(.communities, documentID: documentID, collectionReferences: collectionReference)
        
        let data = PostData(createdAt: Date(), userID: userID, language: LanguageSelection.language, isTopicPost: isTopicPost)
        
        FirestoreManager.uploadObject(object: data, documentReference: reference) { error in
            if let error = error {
                print("We have an error uploading the community data: ", error.localizedDescription)
            }
        }
    }
    
    //MARK: Get Tags to Save
    
    func getTags() -> [String] {
        // Detect the nouns in the title and save them to Firebase in an array. We cant really search in Firebase, but we search through an array, so that way we can at least give the search function in the feedtableviewcontroller some functionality
        var tags = [String]()
        guard let title = titleText else { return [""] }
        
        let tagger = NSLinguisticTagger(tagSchemes: [.lexicalClass], options: 0)
        tagger.string = title
        let range = NSRange(location: 0, length: title.utf16.count)
        let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace]
        tagger.enumerateTags(in: range, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange, _ in
            if let tag = tag {
                let word = (title as NSString).substring(with: tokenRange)
                print("\(word): \(tag)")
                
                if tag == NSLinguisticTag(rawValue: "Noun") {
                    tags.append(word)
                }
            }
        }
        return tags
    }
    
    //MARK: - Finished Posting
    
    func presentAlert(post: Post?) {
        
        if self.comingFromAddOnVC {
            if let addOn = addOn, let post = post {
                addOn.delegate = self
                addOn.saveItem(item: post)
            }
        } else {
            // remove ActivityIndicator incl. backgroundView
            self.view.activityStopAnimating()
            sharingEnabled = true
            
            let alert = UIAlertController(title: "Done!", message: NSLocalizedString("message_after_done_posting", comment: "thanks"), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                
                self.removeInputDataAndResetView()
            }))
            self.present(alert, animated: true)
        }
    }
    
    func removeInputDataAndResetView() {
        //remove text
        
        NewPostItem.allCases.forEach { item in
            if let cell = getCell(for: item) as? NewPostBaseCell {
                cell.resetInput()
            }
        }
        
        //remove picture/s
        self.previewPictures.removeAll()
        self.selectedImageFromPicker = nil
        self.selectedImagesFromPicker.removeAll()
        self.selectedImageWidth = 0
        self.selectedImageHeight = 0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.donePosting()
        }
    }
}
