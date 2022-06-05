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
        guard let cell = getCell(for: .options) as? NewPostOptionCell, let title = titleText, let user = AuthenticationManager.shared.user else {
            return
        }
        
        // TODO: Look what kind of post it is before this initial post is created - Link is the option but it can be different things!
        let post = Post(type: .picture, title: title, createDate: Date())
        
        if let description = descriptionText {
            post.description = description.customFormat
        }
        
        post.tags = getTags()
        post.report = reportType
        post.votes = Votes()
        
        let option = cell.option
        
        if option.postAnonymous || option.hideProfile {
            post.options = PostDesignOption(hideProfilePicture: option.hideProfile, anonymousName: option.synonymString)
        }
        
       
        post.userID = option.postAnonymous ? anonymousString : user.uid
        
        if !option.postAnonymous {
            post.notificationRecipients = [user.uid]   //So he can set notifications off in his own post
        }
        
        post.location = location
        
        let documentReference = FirestoreReference.documentRef(.posts, documentID: nil)
        
        do {
            // setData updates values or creates them if they don't exist
            try documentReference.setData(from: post)
        } catch {
            print("Error bro")
        }
    }
    
    
    @objc func shareTapped() {
        guard let userID = AuthenticationManager.shared.user?.uid else {
            self.notLoggedInAlert()
            return
        }
        
        if !sharingEnabled {
            return
        }
        
        let postRef: DocumentReference?
        var collectionRef: CollectionReference!
        let language = LanguageSelection().getLanguage()
        
        if comingFromAddOnVC || postOnlyInTopic {
            if language == .en {
                collectionRef = db.collection("Data").document("en").collection("topicPosts")
            } else {
                collectionRef = db.collection("TopicPosts")
            }
            postRef = collectionRef.document()
        } else {
            if language == .en {
                collectionRef = db.collection("Data").document("en").collection("posts")
            } else {
                collectionRef = db.collection("Posts")
            }
            postRef = collectionRef.document()
        }
        
        if titleText != nil, let postRef = postRef {
            self.view.activityStartAnimating()
            sharingEnabled = false
            
            switch selectedOption {
            case .thought:
                self.postThought(postRef: postRef, userID: userID)
            case .multiPicture:
                prepareMultiPicturePost(postRef: postRef, userID: userID)
            case .picture:
                preparePicturePost(postRef: postRef, userID: userID)
            case .link:
                prepareLinkPost(postRef: postRef, userID: userID)
            }
        } else {
            self.alert(message: NSLocalizedString("missing_info_alert_title", comment: "enter title pls"))
        }
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
    
    
    // MARK: Prepare Multi Picture
    
    func prepareMultiPicturePost(postRef: DocumentReference, userID: String) {
        if multiImageAssets.count >= 2 && multiImageAssets.count <= 3 {
            
            getImages(forPreview: false) { (data) in
                
                let count = data.count
                var index = -1
                                
                for image in data {
                    
                    index+=1
                    self.uploadImage(data: image, postRef: postRef, index: index) { (url) in
                        if let url = url {
                            self.imageURLs.append(url)
                            
                            if self.imageURLs.count == count { // Uploaded all x Pictures and stored the urls in self.imageURLs
                                self.postMultiplePictures(postRef: postRef, userID: userID)
                            }
                        }
                    }
                }
            }
        } else {
            self.alert(message: NSLocalizedString("error_choosing_multiple_pictures_message", comment: "choose more"), title: NSLocalizedString("error_title", comment: "got error"))
            self.view.activityStopAnimating()
            sharingEnabled = true
        }
    }
 
    // MARK: Prepare Picture
    func preparePicturePost(postRef: DocumentReference, userID: String) {
        guard let image = self.selectedImageFromPicker else {
            self.alert(message: NSLocalizedString("error_choosing_picture", comment: "got no pic"), title: NSLocalizedString("error_title", comment: "got error"))
            self.view.activityStopAnimating()
            sharingEnabled = true
            return
        }
        
        if let thumbnail = image.getThumbnail() {
            self.uploadThumbnailImage(postRef: postRef, image: thumbnail)   // Upload thumbnail image and store it in an internal file, upload later on. Not yet integrated in the chain of asynchrounious requests
        }
        
        if let compressedImage = self.getPictureInCompressedQuality(image: image) {
            self.uploadImage(data: compressedImage, postRef: postRef, index: nil) { url in
                
                guard let url = url else {
                    DispatchQueue.main.async {
                        self.alert(message: "We couldnt upload the image. Please try again or get in contact with the devs. Thanks!", title: "We have an error :/")
                    }
                    return
                }
                self.imageURL = url
                
                self.postPicture(postRef: postRef, userID: userID)
            }
        }
    }
    
    // MARK: Prepare Link
    func prepareLinkPost(postRef: DocumentReference, userID: String) {
        
        if let text = link {
            
            //Is GIF?
            if text.contains(".mp4") {
                self.postGIF(postRef: postRef, userID: userID)
                
                //Is Music Post?
            } else if text.contains("music.apple.com") || text.contains("open.spotify.com/") || text.contains("deezer.page.link") {
                self.getSongwhipData(link: text) { (data) in
                    if let data = data, let link = data["link"] as? String {
                        self.getLinkPreview(linkString: link) { link in
                            if let link = link {
                                self.postLink(postRef: postRef, userID: userID, link: link, songwhipData: data)
                            }
                        }
                    } else {
                        print("No Songwhip data")
                    }
                }
                
                //Is YouTube Video?
            } else if let _ = text.youtubeID {
                //check if the youtubeVideo is a music video/song
                self.getSongwhipData(link: text) { (data) in
                    if let data = data {
                        //if so get link data and post as link
                        if let link = data["link"] as? String {
                            self.getLinkPreview(linkString: link) { (link) in
                                if let link = link {
                                    self.postLink(postRef: postRef, userID: userID, link: link, songwhipData: data)
                                }
                            }
                        }
                    } else {
                        //if not post as yt video
                        self.postYTVideo(postRef: postRef, userID: userID)
                    }
                }
            } else {
                //post a normal Link but get the image and the different descriptions first
                self.getLinkPreview(linkString: text) { (link) in
                    if let link = link {
                        self.postLink(postRef: postRef, userID: userID, link: link, songwhipData: nil)
                    } else {
                        return
                    }
                }
            }
        } else {
            self.view.activityStopAnimating()
            sharingEnabled = true
            self.alert(message: NSLocalizedString("error_no_link", comment: "no link"), title: NSLocalizedString("error_title", comment: "got error"))
        }
    }
    
    //MARK: - Upload Thumbnail Image
    
    func uploadThumbnailImage(postRef: DocumentReference, image: UIImage) {
        if let compressedImage = getPictureInCompressedQuality(image: image) {  //Wont compress put give me the right Data format
            self.uploadImage(data: compressedImage, postRef: postRef, index: 100) { (url) in
                if let imageURL = url {
                    self.thumbnailImageURL = imageURL
                }
            }
        }
    }
    
    //MARK: - Prepare Upload Data
    
    private func getDefaultUploadData(userID: String) -> [String: Any] {
        
        let text = (descriptionText ?? "").trimmingCharacters(in: .newlines)
        let descriptionText = text.replacingOccurrences(of: "\n", with: "\\n")  // Save line breaks in a way that we can extract them later
        
        let title = titleText ?? ""
        let tags = getTags()
        
        var dataDictionary: [String: Any] = ["title": title, "description": descriptionText, "createTime": Timestamp(date: Date()), "thanksCount":0, "wowCount":0, "haCount":0, "niceCount":0, "report": reportType.rawValue, "tags": tags]
        
        // TODO: Dies hier
        // let options = optionView.getSettings()
        
        //Set right user reference
        let userString: String!
        let hideProfileOption: [String: Any] = ["hideProfile": true]
        
        guard let cell = getCell(for: .options) as? NewPostOptionCell else {
            
            return dataDictionary
        }
        
        let options = cell.option
        
        if options.postAnonymous {
            userString = anonymousString
            
            dataDictionary["designOptions"] = hideProfileOption
            
            if let synonym = options.synonymString {
                // Add the synonym, set in the optionView
                dataDictionary["anonymousName"] = synonym
            }
        } else {
            userString = userID
            dataDictionary["notificationRecipients"] = [userID]   //So he can set notifications off in his own post
        }
        
        // location
        if let location = location {
            dataDictionary["locationName"] = location.title
            let geoPoint = GeoPoint(latitude: location.clCoordinate.latitude, longitude: location.clCoordinate.longitude)
            dataDictionary["locationCoordinate"] = geoPoint
        }
        
        dataDictionary["originalPoster"] = userString
        
        // If you want to hide the profilePicture in a non anonymous post
        if options.hideProfile {
            dataDictionary["designOptions"] = hideProfileOption
        }
        
        return dataDictionary
    }
    
    func postThought(postRef: DocumentReference, userID: String) {
        
        var data = getDefaultUploadData(userID: userID)
        data["type"] = "thought"
        
        self.uploadTheData(documentReference: postRef, userID: userID, dataDictionary: data)
        
        print("post thought")
    }
    
    func postLink(postRef: DocumentReference, userID: String, link: Link, songwhipData: [String: Any]?) {
        var dataDictionary = getDefaultUploadData(userID: userID)
        dataDictionary["type"] = "link"
        dataDictionary["link"] = link.url
        dataDictionary["linkTitle"] = link.linkTitle
        dataDictionary["linkDescription"] = link.description
        dataDictionary["linkShortURL"] = link.shortURL
        
        if let dictionary = songwhipData {
            //Merge the uploaddata and the songwhip data to one dictionary and keep the songwhip link, not the streaming service link
            dataDictionary = dataDictionary.merging(dictionary) { (_, new) in new }
        }
        
        if let url = link.imageURL {
            dataDictionary["linkImageURL"] = url
        }
        
        self.uploadTheData(documentReference: postRef, userID: userID, dataDictionary: dataDictionary)
        print("post link")
    }
    
    func postPicture(postRef: DocumentReference, userID: String) {
        if let _ = selectedImageFromPicker, let url = imageURL {
            
            var dataDictionary = getDefaultUploadData(userID: userID)
            dataDictionary["type"] = "picture"
            dataDictionary["imageURL"] = url
            dataDictionary["imageHeight"] = Double(selectedImageHeight)
            dataDictionary["imageWidth"] = Double(selectedImageWidth)
            
            if let thumbnailURL = self.thumbnailImageURL {
                dataDictionary["thumbnailImageURL"] = thumbnailURL
            }
            
            self.uploadTheData(documentReference: postRef, userID: userID, dataDictionary: dataDictionary)
            print("post picture")
            
        } else {
            self.view.activityStopAnimating()
            sharingEnabled = true
            self.alert(message: NSLocalizedString("error_no_picture", comment: "no picture"), title: NSLocalizedString("error_title", comment: "got error"))
        }
    }
    
    func postMultiplePictures(postRef: DocumentReference, userID: String) {
        
        var dataDictionary = getDefaultUploadData(userID: userID)
        dataDictionary["type"] = "multiPicture"
        dataDictionary["imageURLs"] = self.imageURLs
        dataDictionary["imageHeight"] = Double(selectedImageHeight)
        dataDictionary["imageWidth"] = Double(selectedImageWidth)
        
        self.uploadTheData(documentReference: postRef, userID: userID, dataDictionary: dataDictionary)
        print("post multiPicture")
    }
    
    func postGIF(postRef: DocumentReference, userID: String) {
        
        //Check if GIF
        if let link = link {
            if link.contains(".mp4") {
                var dataDictionary = getDefaultUploadData(userID: userID)

                dataDictionary["type"] = "GIF"
                dataDictionary["link"] = link

                self.uploadTheData(documentReference: postRef, userID: userID, dataDictionary: dataDictionary)

                print("post GIF")
            } else {
                self.alert(message: NSLocalizedString("error_gif_wrong_ending", comment: "just .mp4"), title: NSLocalizedString("error_title", comment: "got error"))
                return
            }
        } else {
            self.alert(message: "Bitte gib einen link zu deinem GIF ein.", title: "Kein Link angegeben")
            self.view.activityStopAnimating()
            sharingEnabled = true
            
            return
        }
    }
    
    
    func postYTVideo(postRef: DocumentReference, userID: String) {
        if let link = link?.youtubeID {  // YouTubeVideo
            
            var dataDictionary = getDefaultUploadData(userID: userID)
            dataDictionary["type"] = "youTubeVideo"
            dataDictionary["link"] = link
            
            self.uploadTheData(documentReference: postRef, userID: userID, dataDictionary: dataDictionary)
            
            print("post YouTubeVideo")
        } else {
            self.view.activityStopAnimating()
            sharingEnabled = true
        }
    }
    
    //MARK: -Upload Data
    private func uploadTheData(documentReference: DocumentReference, userID: String, dataDictionary: [String: Any]) {
        
        let documentID = documentReference.documentID
        
        let language = LanguageSelection().getLanguage()
        
        var data = dataDictionary
        
        if let community = linkedCommunity { // If there is a fact that should be linked to this post, and append its ID to the array
            data["linkedFactID"] = community.documentID
            
            // Add the post to the specific fact, so that it can be looked into
            uploadCommunityPostData(postDocumentID: documentID, communityID: community.documentID, language: language)
        }
        
        
        documentReference.setData(data) { err in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
                //TODO: Inform User
            } else {
                //upload data to the user
                self.uploadUserPostData(postDocumentID: documentID, userID: userID, language: language)
                
                if self.savePictureAfterwards { // To Save on your device, not the best solution though
                    self.savePhotoToAlbum(image: self.selectedImageFromPicker)
                }
                
                //Finish posting process
                if self.comingFromAddOnVC {
                    let post = Post.standard
                    post.documentID = documentID
                    post.isTopicPost = true
                    
                    self.presentAlert(post: post)
                } else {
                    self.presentAlert(post: nil)
                }
            }
        }
    }
    
    private func savePhotoToAlbum(image: UIImage?) {
        if let selectedImage = image {
            UIImageWriteToSavedPhotosAlbum(selectedImage, nil, nil, nil)
        }
    }
    
    private func uploadUserPostData(postDocumentID: String, userID: String, language: Language) {
        
        var userRef: DocumentReference!
        
        if postAnonymous {
            //Make a reference to the poster if there should be any violations
            userRef = db.collection("AnonymousPosts").document(postDocumentID)
        } else {
            userRef = db.collection("Users").document(userID).collection("posts").document(postDocumentID)
        }
        
        
        var data: [String: Any] = ["createTime": Timestamp(date: Date())]
        
        if language == .en {
            data["language"] = "en"
        }
        
        // To fetch in a different ref when loading the posts of the topic
        if self.comingFromAddOnVC || self.postOnlyInTopic {
            data["isTopicPost"] = true
        }
        
        // Get reference to OP
        if postAnonymous {
            data["originalPoster"] = userID
        }
        
        userRef.setData(data) { (err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                print("Successfully set UserData")
            }
        }
    }
    
    private func uploadCommunityPostData(postDocumentID: String, communityID: String, language: Language) {
        var collectionRef: CollectionReference!

        if language == .en {
            collectionRef = self.db.collection("Data").document("en").collection("topics")
        } else {
            collectionRef = self.db.collection("Facts")
        }
        
        let topicRef = collectionRef.document(communityID).collection("posts").document(postDocumentID)
        
        var data: [String: Any] = ["createTime": Timestamp(date: Date())]
        
        if self.comingFromAddOnVC || postOnlyInTopic {
            data["type"] = "topicPost"  // To fetch in a different ref when loading the posts of the topic
        }
        
        topicRef.setData(data) { (err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                print("FactReference successfully added")
            }
        }
    }
    
    //MARK: Get LinkPreview
    
    func getLinkPreview(linkString: String, returnLink: @escaping (Link?) -> Void) {
        if linkString.isValidURL {
            slp.preview(linkString, onSuccess: { (response) in
                let link = Link(url: linkString, shortURL: response.canonicalUrl, imageURL: response.image, linkTitle: response.title, description: response.description)
                
                returnLink(link)

            }) { err in
                print("We have an error: \(err.localizedDescription)")
                self.alert(message: err.localizedDescription, title: NSLocalizedString("error_title", comment: "got error"))
                self.view.activityStopAnimating()
                self.sharingEnabled = true
                
                returnLink(nil)
            }
        } else {
            self.view.activityStopAnimating()
            sharingEnabled = true
            self.alert(message: NSLocalizedString("error_link_not_valid", comment: "not valid"), title: NSLocalizedString("error_title", comment: "got error"))
            
            returnLink(nil)
        }
    }

    //MARK: Get Songwhip Data
    
    func getSongwhipData(link: String, returnData: @escaping ([String: Any]?) -> Void) {
        
        if let url = URL(string: "https://songwhip.com/") {
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            let body = "{\"url\":\"\(link)\"}"
            request.httpBody = body.data(using: .utf8)
            
            
            URLSession.shared.dataTask(with: request) { (data, response, err) in
                if let error = err {
                    print("We have an error getting the songwhip Data: ", error.localizedDescription)
                } else {
                    if let data = data {
                        
                        do {
                            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] {
                                
                                guard let type = json["type"] as? String,
                                      let name = json["name"] as? String,
                                      let releaseDate = json["releaseDate"] as? String,
                                      let link = json["url"] as? String,
                                      let musicImage = json["image"] as? String,
                                      let artistData = json["artists"] as? [[String: Any]]
                                else {
                                    print("Returne ohne daten")
                                    return
                                }
                                
                                guard let date = self.getReleaseDate(stringDate: releaseDate) else { return }
                                
                                if let artistInfo = artistData.first {
                                    if let artistName = artistInfo["name"] as? String, let artistImage = artistInfo["image"] as? String {
                                        
                                        let songwhipData: [String: Any] = ["musicType": type, "name": name, "releaseDate": Timestamp(date: date), "link": link, "artist": artistName, "artistImage": artistImage, "musicImage": musicImage]
                                        
                                        returnData(songwhipData)
                                    }
                                }
                            } else {
                                print("Couldnt get the jsonData from Songwhip API Call")
                                returnData(nil)
                            }
                        } catch {
                            print("Couldnt get the jsonData from Songwhip API Call")
                            returnData(nil)
                        }
                    }
                }
            }.resume()
        }
    }
    
    //MARK: Get Music Release Date
    func getReleaseDate(stringDate: String) -> Date? {
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "de_DE")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let date = dateFormatter.date(from: stringDate)
        
        return date
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
    
    //MARK:- Finished Posting
    
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


//MARK: - Picture Upload

extension NewPostVC {
    
    //MARK: Upload Image
    
    ///Upload Image to Database and return the urlString of the stored Image
    /// If index is set to 100 the image will be saved as a thumbnail (with an "-thumbnail" appendix)
    func uploadImage(data: Data, postRef: DocumentReference, index: Int?, imageURL: @escaping (String?) -> Void) {
        
        var imageReference = postRef.documentID
        
        if let index = index {
            if index != 100 {   //thumbnail code
                imageReference.append("-\(index)")
            } else {
                imageReference.append("-thumbnail")
            }
        }
        
        let storageRef = Storage.storage().reference().child("postPictures").child("\(imageReference).png")
        
        storageRef.putData(data, metadata: nil, completion: { (metadata, error) in    //Store image
            if let error = error {
                print("We have an error: \(error.localizedDescription)")
                
                imageURL(nil)
            }
            storageRef.downloadURL(completion: { (url, err) in  // Download url and save it
                if let error = err {
                    print("We have an error downloading the url: \(error.localizedDescription)")
                    
                    imageURL(nil)
                }
                if let url = url {
                    let stringURL = url.absoluteString
                    imageURL(stringURL)
                } else {
                    imageURL(nil)
                }
            })
        })
    }
    
    
}
