//
//  MigrationManager.swift
//  Imagine
//
//  Created by Don Malte on 27.06.22.
//  Copyright © 2022 Malte Schoppe. All rights reserved.
//

import Foundation
import FirebaseFirestore

/*
 1. Fetch Object mit alter Technik und Struktur
 2. Upload Objekt mit neuem Pfad
 
 // Posts
 - Posts (de/en)
 - TopicPosts (de/en)
 
 // PostData
 - User - Posts
 - User - Saved
 - User - Topics!!! // TODO: Topics bro
 
 - Community - Posts
 
 */

class MigrationManager {
    
    static let shared = MigrationManager()
    
    let factJSONString = "linkedFactID"
    let handyHelper = HandyHelper.shared
    let db = Firestore.firestore()
    
    let firestoreRequest = FirestoreRequest.shared
    
    var posts = [Post]()
}

// MARK: - Legacy Post Code

extension MigrationManager {
    
    func migratePosts(for language: Language, fetchTopicPosts: Bool) {
        getPosts(for: language, topicPosts: fetchTopicPosts) { posts in
            guard let posts = posts else {
                return
            }
            
            let dispatchSemaphore = DispatchSemaphore(value: 0)

            posts.forEach { post in
                
                guard let documentID = post.documentID else {
                    print("No ID: \(post.title)")
                    return
                }
                let ref = FirestoreReference.documentRef(fetchTopicPosts ? .topicPosts : .posts, documentID: documentID, language: language)
                
                FirestoreManager.uploadObject(object: post, documentReference: ref) { error in
                    guard let error = error else {
                        return
                    }
                    
                    dispatchSemaphore.signal()

                    print("We have an error uploading posts: \(error.localizedDescription)")
                }
                
                dispatchSemaphore.wait()
            }
        }
    }
    
    private func getPosts(for language: Language, topicPosts: Bool, completion: @escaping ([Post]?) -> Void) {
        
        var posts = [Post]()
        
        let ref = db.collection("Data").document("en").collection(topicPosts ? "topicPosts" : "posts")
        
        ref.getDocuments { [weak self] snap, error in
            
            guard let snap = snap, let self = self else {
                completion(nil)
                return
            }
            
            
            for document in snap.documents {
                if let post = self.addThePost(document: document, isTopicPost: false, language: language) {
                    posts.append(post)
                }
            }
            
            completion(posts)
        }
    }
    
    
    private func addThePost(document: DocumentSnapshot, isTopicPost: Bool, language: Language) -> Post? {
        
        let documentID = document.documentID
        if let documentData = document.data() {
            
            
            if let postType = documentData["type"] as? String {
                
                // Werte die alle haben
                guard let post = getDefaultPost(document: document) else {
                    
                    return nil
                }
                
                post.language = language
                post.isTopicPost = isTopicPost
                
                //MARK: Survey
                if postType == "survey" {
                    
                    guard let surveyType = documentData["surveyType"] as? String,
                          let question = documentData["question"] as? String
                    else { return nil }
                    
                    let defaults = UserDefaults.standard
                    let hiddenSurveyArrayString = Constants.userDefaultsStrings.hideSurveyString
                    let surveyStrings = defaults.stringArray(forKey: hiddenSurveyArrayString) ?? [String]()
                    
                    for surveyID in surveyStrings {
                        if documentID == surveyID {
                            print("Survey is hidden")
                            return nil
                        }
                    }
                    
                    var surveyTypeEnum: SurveyType = .pickOrder
                    
                    if surveyType == "pickOne" {
                        surveyTypeEnum = .pickOne
                    } else if surveyType == "comment" {
                        surveyTypeEnum = .comment
                    }
                    
                    let survey = Survey(type: surveyTypeEnum, question: question)
                    post.survey = survey
                    
                    if let firstAnswer = documentData["firstAnswer"] as? String,
                       let secondAnswer = documentData["secondAnswer"] as? String,
                       let thirdAnswer = documentData["thirdAnswer"] as? String,
                       let fourthAnswer = documentData["fourthAnswer"] as? String {
                        
                        survey.firstAnswer = firstAnswer
                        survey.secondAnswer = secondAnswer
                        survey.thirdAnswer = thirdAnswer
                        survey.fourthAnswer = fourthAnswer
                    }
                    
                    
                    return post
                    
                    //MARK: Thought
                } else if postType == "thought" {
                    
                    post.type = .thought
                    
                    return post
                    
                    //MARK: Picture
                } else if postType == "picture" {
                    
                    guard let imageURL = documentData["imageURL"] as? String,
                          let height = documentData["imageHeight"] as? Double,
                          let width = documentData["imageWidth"] as? Double
                            
                    else {
                        return nil
                    }
                    
                    let image = PostImage(url: imageURL, height: height, width: width)
                    post.image = image
                    
                    let ratio = width / height
                    if ratio > 2 {
                        post.type = .panorama
                    } else {
                        post.type = .picture
                    }
                    
                    
                    return post
                    
                    //MARK: MultiPicture
                } else if postType == "multiPicture" {
                    
                    guard let images = documentData["imageURLs"] as? [String],
                          let height = documentData["imageHeight"] as? Double,
                          let width = documentData["imageWidth"] as? Double
                    else {
                        return nil
                    }
                    
                    post.type = .multiPicture
                    
                    let postImages = images.compactMap({ PostImage(url: $0, height: height, width: width) })    // The width and height will only be correct for the first object in the array
                    post.images = postImages
                    
                    return post
                    
                    //MARK: YouTubeVideo
                } else if postType == "youTubeVideo" {
                    
                    guard let linkURL = documentData["link"] as? String else { return nil  }
                    
                    let link = Link(url: linkURL)
                    post.link = link
                    post.type = .youTubeVideo
                    
                    return post
                    
                    //MARK: GIF
                } else if postType == "GIF" {
                    
                    guard let gifURL = documentData["link"] as? String
                            
                    else {
                        return nil
                    }
                    
                    let size = gifURL.getURLVideoSize()
                    let link = Link(url: gifURL, mediaHeight: size.height, mediaWidth: size.width)
                    post.link = link
                    post.type = .GIF
                    
                    return post
                    
                } else if postType == "stop" {
                    
                    //MARK: Link
                } else if postType == "link" {
                    
                    guard let linkURL = documentData["link"] as? String else {
                        return nil
                    }
                    var link: Link?
                    
                    if let shortURL = documentData["linkShortURL"] as? String, let linkTitle = documentData["linkTitle"] as? String, let linkDescription = documentData["linkDescription"] as? String {
                        let linkImageURL = documentData["linkImageURL"] as? String
                        
                        link = Link(url: linkURL, shortURL: shortURL, imageURL: linkImageURL, linkTitle: linkTitle, description: linkDescription)
                    }
                    
                    post.link = link
                    post.type = .link
                    
                    //look for songwhip data
                    if let type = documentData["musicType"] as? String,
                       let name = documentData["name"] as? String,
                       let releaseDateTimestamp = documentData["releaseDate"] as? Timestamp,
                       let artist = documentData["artist"] as? String,
                       let artistImage = documentData["artistImage"] as? String,
                       let musicImage = documentData["musicImage"] as? String {
                        
                        let releaseDate = releaseDateTimestamp.dateValue()
                        
                        let songwhip = Songwhip(title: name, musicType: type, releaseDate: releaseDate, artist: SongwhipArtist(name: artist, image: artistImage), musicImage: musicImage)
                        post.link?.songwhip = songwhip
                    }
                    
                    return post
                    
                    //MARK: Single Topic
                } else if postType == "singleTopic"  {
                    
                    post.type = .singleTopic
                    
                    return post
                    
                    //MARK: Repost
                } else if postType == "repost" || postType == "translation" {
                    
                    guard let postDocumentID = documentData["OGpostDocumentID"] as? String
                            
                    else {
                        return nil
                    }
                    
                    let post = Post.standard
                    post.repostDocumentID = postDocumentID
                    
                    let repost = Post.standard
                    if let repostLanguage = documentData["repostLanguage"] as? String {
                        if repostLanguage == "en" {
                            repost.language = .en
                            if post.language != .en {
                                post.type = .translation
                            }
                        } else if repostLanguage == "de" {
                            repost.language = .de
                            if post.language != .de {
                                post.type = .translation
                            }
                        }
                    } else {
                        post.type = .repost
                    }
                    if let repostIsTopicPost = documentData["repostIsTopicPost"] as? Bool {
                        repost.isTopicPost = repostIsTopicPost
                    }
                    
                    post.repost = repost
                    post.getRepost { repost in
                        post.repost = repost
                    }
                    
                    return post
                }
            }
        }
        
        return nil
    }
    
    
    //MARK: - Get Default Post
    /// This function returns a Post Object with its basic variables without the type
    ///
    ///
    ///
    /// - Returns: A Post object WITHOUT the type!
    private func getDefaultPost(document: DocumentSnapshot) -> Post? {
        
        guard let documentData = document.data(),
              let title = documentData["title"] as? String,
              let reportString = documentData["report"] as? String,
              let createTimestamp = documentData["createTime"] as? Timestamp,
              let originalPoster = documentData["originalPoster"] as? String,
              let thanksCount = documentData["thanksCount"] as? Int,
              let wowCount = documentData["wowCount"] as? Int,
              let haCount = documentData["haCount"] as? Int,
              let niceCount = documentData["niceCount"] as? Int
                
        else {
            return nil
        }
        
        if reportString == "blocked" {
            return nil
        }
        
        //Check if the poster is a friend of yours
        
        let post = Post(type: .picture, title: title, createdAt: createTimestamp.dateValue())
        post.description = documentData["description"] as? String
        post.documentID = document.documentID
        post.votes.thanks = thanksCount
        post.votes.wow = wowCount
        post.votes.ha = haCount
        post.votes.nice = niceCount
        
        //Tried to export these extra values because they repeat themself in every "type" case but because of my async func "getFact" if a factID exists and move the post afterwards
        if let report = handyHelper.setReportType(fetchedString: reportString) {
            post.report = report
        }
        
        //User who receive notifications
        if let notificationRecipients = documentData["notificationRecipients"] as? [String] {
            post.notificationRecipients = notificationRecipients
        }
        
        //Linked Community
        if let communityID = documentData[factJSONString] as? String {
            post.community = self.addCommunity(communityID: communityID)
        }
        
        // User/Poster
        if originalPoster == "anonym" {
            post.anonym = true
            if let anonymousName = documentData["anonymousName"] as? String {
                post.options?.anonymousName = anonymousName
            }
        } else {
            let user = User(userID: originalPoster)
            user.loadUser() { user in
                post.user = user
            }
        }
        
        //Comment Count
        if let commentCount = documentData["commentCount"] as? Int {
            post.commentCount = commentCount
        } // else { it stays 0
        
        //Design Options
        if let designOptions = documentData["designOptions"] as? [String: Any], let hideProfile = designOptions["hideProfile"] as? Bool, hideProfile {
            post.options = PostDesignOption(hideProfilePicture: true)
        }
        
        if let locationName = documentData["locationName"] as? String, let locationCoordinates = documentData["locationCoordinate"] as? GeoPoint {
            let location = Location(title: locationName, geoPoint: locationCoordinates)
            
            post.location = location
        }
        
        if let thumbnailURL = documentData["thumbnailImageURL"] as? String {
            post.image?.thumbnailUrl = thumbnailURL
        }
        
        return post
    }
    
    func addCommunity(communityID: String) -> Community {
        let community = Community()
        community.id = communityID
        
        return community
    }
}

// MARK: - User Post Data
extension MigrationManager {
    
    func migrateUserPosts(type: UserPostType) {
        
        getUsers { users in
            guard let users = users else {
                return
            }
            
            users.forEach { user in
                guard let uid = user.uid else {
                    return
                }
                
                self.getUserPosts(for: type, userUID: uid) { postData in
                    guard let postData = postData else {
                        return
                    }
                    
                    let reference = FirestoreCollectionReference(document: uid, collection: type == .user ? "posts" : "saved" )
                    let collectionReference = FirestoreReference.mainRef(.users, collectionReference: reference)
                                        
                    FirestoreManager.batchUploadPostData(postData, collectionReference: collectionReference) { error in
                        guard let error = error else {
                            print("Successfully upload topic postData")
                            return
                        }

                        print("We have an error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func getUsers(completion: @escaping ([User]?) -> Void) {
        let query = FirestoreReference.collectionRef(.users)
        
        FirestoreManager.shared.decode(query: query) { (result: Result<[User], Error>) in
            switch result {
            case .success(let users):
                completion(users)
            case .failure(let error):
                print("We have an error migrating the users: \(error.localizedDescription)")
            }
        }
    }
    
    private func getUserPosts(for postList: UserPostType, userUID: String, completion: @escaping ([PostData]?) -> Void) {
        
        var postData = [PostData]()
        
        let reference = FirestoreCollectionReference(document: userUID, collection: postList == .user ? "posts" : "saved")
        let userPostRef = FirestoreReference.collectionRef(.users, collectionReference: reference)
        
        userPostRef.getDocuments { querySnapshot, error in
            
            guard let snap = querySnapshot, error == nil, !snap.documents.isEmpty else {
                completion(nil)
                return
            }
            
            
            switch postList {
            case .user:
                for document in snap.documents {
                    let documentID = document.documentID
                    let data = document.data()
                    
                    var createdAt = Date()
                    if let timestamp = data["createTime"] as? Timestamp {
                        createdAt = timestamp.dateValue()
                    }
                    
                    var language = Language.de
                    if let postLanguage = data["language"] as? String, postLanguage == "en" {
                        language = .en
                    }
                    
                    let isTopic = data["isTopicPost"] as? Bool ?? false
                    
                    let postDate = PostData(id: documentID, createdAt: createdAt, language: language, isTopicPost: isTopic)
                    postData.append(postDate)
                }
                
                completion(postData)
            case .saved:
                for document in snap.documents {
                    let data = document.data()
                    
                    var documentID = document.documentID
                    if let storedDocumentID = data["documentID"] as? String {
                        documentID = storedDocumentID
                    }
                    
                    var createdAt = Date()
                    if let timestamp = data["createTime"] as? Timestamp {
                        createdAt = timestamp.dateValue()
                    }
                    
                    var language = Language.de
                    if let postLanguage = data["language"] as? String, postLanguage == "en" {
                        language = .en
                    }
                    
                    let isTopic = data["isTopicPost"] as? Bool ?? false
                    
                    let postDate = PostData(id: documentID, createdAt: createdAt, language: language, isTopicPost: isTopic)
                    postData.append(postDate)
                }
                
                
                completion(postData)
            }
        }
    }
}

// MARK: - Community Post Data

extension MigrationManager {
    
    func migrateCommunityPosts(language: Language) {
        getCommunities(language: language) { communities in
            guard let communities = communities else {
                return
            }

            communities.forEach { community in
                self.getCommunityPosts(for: community.id, language: language) { postData in
                    guard let postData = postData, let communityID = community.id else {
                        return
                    }
                    
                    let reference = FirestoreCollectionReference(document: communityID, collection: "posts")
                    let collectionReference = FirestoreReference.mainRef(.communityPosts, collectionReference: reference, language: language)

                    FirestoreManager.batchUploadPostData(postData, collectionReference: collectionReference) { error in
                        guard let error = error else {
                            print("Successfully upload topic postData")
                            return
                        }

                        print("We have an error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func getCommunities(language: Language, completion: @escaping ([Community]?) -> Void) {
        let ref = FirestoreReference.collectionRef(.communities, language: language)
        
        ref.getDocuments { snap, error in
            guard let snap = snap, error == nil else {
                print("We have an error: \(error?.localizedDescription ?? "")")
                completion(nil)
                return
            }
            
            
            let communities = snap.documents.compactMap { document in
                self.getCommunity(documentID: document.documentID, data: document.data())
            }
            
            completion(communities)
        }
    }
    
    private func getCommunityPosts(for communityID: String?, language: Language, completion: @escaping ([PostData]?) -> Void) {
        
        guard let communityID = communityID else {
            completion(nil)
            return
        }

        var postData = [PostData]()
        
        let reference = FirestoreCollectionReference(document: communityID, collection: "posts")
        let communityRef = FirestoreReference.collectionRef(.communityPosts, collectionReference: reference, language: language)
        
        communityRef.getDocuments { querySnapshot, error in
            
            guard let snap = querySnapshot, error == nil, !snap.documents.isEmpty else {
                completion(nil)
                return
            }
            
            for document in snap.documents {
                let documentID = document.documentID
                let data = document.data()
                
                var createdAt = Date()
                if let timestamp = data["createTime"] as? Timestamp {
                    createdAt = timestamp.dateValue()
                }
                                
                var isTopicPost = false
                if let type = data["type"] as? String {
                    if type == "topicPost" {
                        isTopicPost = true
                    } else {
                        print("#### We got a type but not a topicPost!; communityID: \(communityID)")
                    }
                }
                
                
                let postDate = PostData(id: documentID, createdAt: createdAt, language: language, isTopicPost: isTopicPost)
                postData.append(postDate)
            }
            
            completion(postData)
        }
    }
}

// MARK: - Get Community
extension MigrationManager {
    

    func migrateCommunities(language: Language) {
        getCommunities(language: language) { communities in
            guard let communities = communities else {
                return
            }

            let reference = FirestoreReference.mainRef(.communities, language: language)
            
            FirestoreManager.batchUploadCommunities(communities, collectionReference: reference) { error in
                guard let error = error else {
                    print("Batch upload for communities were successfull")
                    return
                }

                print("We have an error: \(error.localizedDescription)")
            }
        }
    }
    
    private func getCommunity(documentID: String, data: [String: Any]) -> Community? {
        
        guard let name = data["name"] as? String,
            let timestamp = data["createDate"] as? Timestamp,
            let OP = data["OP"] as? String
            else {
                print("Der will nicht: \(documentID), mit den Daten: \(data)")
                return nil
        }
        
        
        let community = Community()
        community.id = documentID
        community.title = name
        community.createdAt = timestamp.dateValue()
        community.moderators = [OP]
        community.postCount = data["postCount"] as? Int
        community.imageURL = data["imageURL"] as? String
        community.description = data["description"] as? String
        
        
        if let language = data["language"] as? String {
            if language == "en" {
                community.language = .en
            }
        }

        if let displayType = data["displayOption"] as? String { // Was introduced later on
            community.displayOption = self.getDisplayType(string: displayType)
        }
        
        if let displayNames = data["factDisplayNames"] as? String {
            community.discussionTitles = self.getDisplayNames(string: displayNames)
        }
        
        if let _ = data["isAddOnFirstView"] as? Bool {
            community.initialView = .addOn
        }
        
        return community
    }
    
    private func loadCommunity(_ community: Community, completion: @escaping (Community?) -> Void) {
        
        guard let id = community.id else {
            completion(nil)
            return
        }
        
        var collectionRef: CollectionReference!
        if community.language == .en {
            collectionRef = db.collection("Data").document("en").collection("topics")
        } else {
            collectionRef = db.collection("Facts")
        }
        let ref = collectionRef.document(id)
        
        
        ref.getDocument { [weak self] (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                guard let snap = snap, let self = self, let data = snap.data(), let community = self.getCommunity(documentID: snap.documentID, data: data) else {
                    completion(nil)
                    return
                }
                completion(community)
            }
        }
    }
    
    private func getDisplayType(string: String) -> DisplayOption {
        switch string {
        case "topic":
            return .topic
        default:
            return .discussion
        }
    }
    
    private func getDisplayNames(string: String) -> DiscussionTitles {
        switch string {
        case "confirmDoubt":
            return .confirmDoubt
        case "advantage":
            return .advantageDisadvantage
        default:
            return .proContra
        }
    }
}

// MARK: - Migrate followed Topics
extension MigrationManager {
    
    func migrateFollowedTopics() {
        getUsers { users in
            guard let users = users else {
                return
            }

            users.forEach { user in
                guard let userID = user.uid else {
                    return
                }
                
                self.getFollowedTopicDocuments(userUID: userID) { postData in
                    let reference = FirestoreReference.mainRef(.users, collectionReference: FirestoreCollectionReference(document: userID, collection: "topics"))
                    
                    FirestoreManager.batchUploadPostData(postData, collectionReference: reference) { error in
                        guard let error = error else {
                            print("Successfully upload topic postData")
                            return
                        }

                        print("We have an error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func getFollowedTopicDocuments(userUID: String, completion: @escaping ([PostData]) -> Void) {
        let topicRef = db.collection("Users").document(userUID).collection("topics")
        
        var postData = [PostData]()
        
        topicRef.getDocuments { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap {
                    for document in snap.documents {
                        
                        let data = document.data()
                        
                        var language = Language.de
                        if let fetchedLanguage = data["language"] as? String, fetchedLanguage == "en" {
                            language = .en
                        }
                        
                        let date = (data["createDate"] as? Timestamp)?.dateValue() ?? Date()
                        
                        let postDate = PostData(id: document.documentID, createdAt: date, language: language)
                        postData.append(postDate)
                        
                        if postData.count == snap.documents.count {
                            completion(postData)
                        }
                    }
                }
            }
        }
    }
}
