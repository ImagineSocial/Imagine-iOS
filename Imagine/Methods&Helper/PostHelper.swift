//
//  PostHelper.swift
//  Imagine
//
//  Created by Malte Schoppe on 25.02.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import Foundation
import Firebase
import FirebaseFirestore
import SDWebImage
import PromiseKit


// This enum differentiates between savedPosts or posts for the "getTheSavedPosts" function
enum PostList {
    case postsFromUser
    case savedPosts
}


class PostHelper {
    
    var posts = [Post]()
    let db = Firestore.firestore()
    
    let handyHelper = HandyHelper()
    
    var initialFetch = true
    
    var lastSnap: QueryDocumentSnapshot?
    var startBeforeSnap: QueryDocumentSnapshot?
    var lastEventSnap: QueryDocumentSnapshot?
    var lastSavedPostsSnap: QueryDocumentSnapshot?
    var lastFeedPostSnap: QueryDocumentSnapshot?
    
    let factJSONString = "linkedFactID"
    
    var friends: [String]?
    var followedTopics = [String]()
    
    /* These two variables are here to make sure that we just fetch as many as there are documents and dont start at the beginning again  */
    var morePostsToFetch = true
    var totalCountOfPosts = 0
    var alreadyFetchedCount = 0
    
    func getTheUsersFriend(fetchedFriends: @escaping ([String]) -> Void) {
        if self.friends == nil {
            if let user = Auth.auth().currentUser {
                let userRef = db.collection("Users").document(user.uid).collection("friends")
                
                userRef.getDocuments { (snaps, err) in
                    if let error = err {
                        print("We have an error: \(error.localizedDescription)")
                    } else {
                        if let snaps = snaps {
                            var friends = [String]()
                            for document in snaps.documents {
                                friends.append(document.documentID)
                            }
                            
                            //Add yourself to the list so you see your full name in the feed
                            friends.append(user.uid)
                            
                            self.friends = friends
                            
                            fetchedFriends(friends)
                        } else {
                            //return empty array
                            fetchedFriends([])
                        }
                    }
                }
            } else {
                fetchedFriends([])
            }
        } else {
            
            fetchedFriends(self.friends!)
        }
    }
    
    func checkIfOPIsAFriend(userUID: String) -> Bool {
        if let friends = self.friends {
            for friend in friends {
                if friend == userUID {
                    return true
                }
            }
            return false
        } else {
            return false
        }
    }
    
    /*
     The Structure at the moment for the main feed:
     getTheUsersFriend("friends", saved in this View) { // to get the right name for the feed
        getLast15Posts() {
            getFollowedTopicIDs() { //Is called inside "getFollowedTopicPosts"
                getFollowedTopicPosts() {   // They are limited to the last date of the getLast15Posts fetch, if getMore, there is also a startAfter query, so the 15 posts fetched from the main query always limit the topicPosts
                   
     
                    func orderIt() by createTime and return the posts
                }
            }
        }
     }
     */
    
    
    //MARK: - Main Feed
    func getPostsForMainFeed(getMore:Bool, sort: PostSortOptions, returnPosts: @escaping ([Post], _ InitialFetch:Bool) -> Void) {
        
        posts.removeAll()
        
        var orderBy = "createTime"
        var descending = true
        
        switch sort {
        case .dateIncreasing:
            orderBy = "createTime"
            descending = false
        case .thanksCount:
            orderBy = "thanksCount"
            descending = true
        case .wowCount:
            orderBy = "wowCount"
            descending = true
        case .haCount:
            orderBy = "haCount"
            descending = true
        case .niceCount:
            orderBy = "niceCount"
            descending = true
        default:
            orderBy = "createTime"
            descending = true
        }
        
        if initialFetch {
            self.getFollowedTopics()
        }
        
        var collectionRef: CollectionReference!
        let language = LanguageSelection().getLanguage()
        if language == .english {
            collectionRef = db.collection("Data").document("en").collection("posts")
        } else {
            collectionRef = db.collection("Posts")
        }
                
        var postRef = collectionRef.order(by: orderBy, descending: descending).limit(to: 15)
                
        if getMore {    // If you want to get More Posts
            if let lastSnap = lastSnap {        // For the next loading batch of 20, that will start after this snapshot
                postRef = postRef.start(afterDocument: lastSnap)
                self.startBeforeSnap = lastSnap
                self.initialFetch = false
            }
        } else { // Else: you want to refresh the feed
            self.initialFetch = true
        }
        
        self.getTheUsersFriend { (_) in // First get the friends to choose which name to fetch
            
            postRef.getDocuments { (snap, error) in
                
                if let snap = snap {
                    self.lastSnap = snap.documents.last    // Last document for the next fetch cycle
                    
                    for document in snap.documents {
                        self.addThePost(document: document, isTopicPost: false, forFeed: true, language: language)
                    }
                    
                    if let lastSnap = self.lastSnap {
                        self.getFollowedTopicPosts(startSnap: self.startBeforeSnap, endSnap: lastSnap) { (posts) in
                            var combinedPosts: [Post] = posts
                            combinedPosts.append(contentsOf: self.posts)
                            let finalPosts = combinedPosts.sorted(by: { $0.createDate ?? Date() > $1.createDate ?? Date() })
                            returnPosts(finalPosts, self.initialFetch)
                        }
                    } else {
                        returnPosts(self.posts, self.initialFetch)
                    }
                } else {
                    returnPosts(self.posts, self.initialFetch)
                }
            }
        }
    }
    
    
    
    func getFollowedTopicPosts(startSnap: QueryDocumentSnapshot?, endSnap: QueryDocumentSnapshot, returnTopicPosts: @escaping ([Post]) -> Void) {
        
        var topicPosts = [Post]()
        
        var startTimestamp = Timestamp(date: Date()) //now, i.e. the first fetch
        
        if let startSnap = startSnap {  // If there is a startSnap, the fetch starts after that
            let data = startSnap.data()
            
            if let startStamp = data["createTime"] as? Timestamp {
                startTimestamp = startStamp
            }
        }
        
        let data = endSnap.data()
        if let endTimestamp = data["createTime"] as? Timestamp {
            
            self.getFollowedTopicIDs { (topics) in
                let topicTotalCount = topics.count
                var topicCount = 0
                
                if topics.count == 0 {
                    returnTopicPosts(topicPosts)
                }
                
                for topicID in topics {
                    
                    var collectionRef: CollectionReference!
                    let language = LanguageSelection().getLanguage()
                    if language == .english {
                        collectionRef = self.db.collection("Data").document("en").collection("topicPosts")
                    } else {
                        collectionRef = self.db.collection("TopicPosts")
                    }
                    let ref = collectionRef
                        .whereField("linkedFactID", isEqualTo: topicID)
                        .whereField("createTime", isLessThanOrEqualTo: startTimestamp)
                        .whereField("createTime", isGreaterThanOrEqualTo: endTimestamp)
                    
                    ref.getDocuments { (snap, err) in
                        if let error = err {
                            print("We have an error: \(error.localizedDescription)")
                            topicCount+=1
                        } else {
                            topicCount+=1
                            if let snap = snap {
                                let totalPostCount = snap.documents.count
                                var postCount = 0
                                
                                for document in snap.documents {
                                    postCount+=1
                                    
                                    if let post = self.addThePost(document: document, isTopicPost: true, forFeed: false, language: language) {
                                        topicPosts.append(post)
                                    }
                                }
                                
                                if topicCount == topicTotalCount && postCount == totalPostCount {
                                    returnTopicPosts(topicPosts)
                                }
                            }
                        }
                    }
                }
            }
        } else {
            print("We got no date")
        }
    }
    
    func getFollowedTopicIDs(returnTopicIDs: @escaping ([String]) -> Void) {
        var topics = [String]()
        if let user = Auth.auth().currentUser {
            
            let topicRef = db.collection("Users").document(user.uid).collection("topics")
            
            topicRef.getDocuments { (snap, err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    if let snap = snap {
                        for document in snap.documents {
                            topics.append(document.documentID)
                        }
                        returnTopicIDs(topics)
                    } else {
                        returnTopicIDs(topics)
                    }
                }
            }
        } else {
            returnTopicIDs(topics)
        }
    }
    
    func getFollowedTopics() {
        if let user = Auth.auth().currentUser {
            let topicRef = db.collection("Users").document(user.uid).collection("topics")
            
            topicRef.getDocuments { (snap, err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    if let snap = snap {
                        for document in snap.documents {
                            self.followedTopics.append(document.documentID)
                        }
                    }
                }
            }
        }
    }
    
    
    //MARK: - Saved and User
    func getPostList(getMore: Bool, whichPostList: PostList, userUID : String, returnPosts: @escaping ([Post]?, _ InitialFetch:Bool) -> Void) {
        
        // check if there are more posts to fetch
        if morePostsToFetch {
            
            posts.removeAll()
            
            var postListReference: String!
            
            switch whichPostList {
            case .postsFromUser:
                postListReference = "posts"
            case .savedPosts:
                postListReference = "saved"
            }
            
            var documentIDsOfPosts = [Post]()
            
            var userPostRef = db.collection("Users").document(userUID).collection(postListReference).order(by: "createTime", descending: true).limit(to: 20)
            
            
            // Check if the Feed has been refreshed or the next batch is ordered
            if getMore {
                // For the next loading batch of 20, that will start after this snapshot if it is there
                if let lastSnap = lastSavedPostsSnap {
                    
                    // I think I have an issue with createDate + .start(afterDocument:) because there are some without date
                    userPostRef = userPostRef.start(afterDocument: lastSnap)
                    self.initialFetch = false
                }
            } else { // Else you want to refresh the feed
                self.initialFetch = true
            }
            
            
            userPostRef.getDocuments { (querySnapshot, err) in
                if let error = err {
                    print("Wir haben einen Error bei den Userposts: \(error.localizedDescription)")
                } else {
                    if let snap = querySnapshot {
                        if snap.documents.count == 0 {    // Hasnt posted or saved anything yet
                            let post = Post()
                            post.type = .nothingPostedYet
                            returnPosts([post], self.initialFetch)
                        } else {
                            
                            let fetchedDocsCount = snap.documents.count
                            self.alreadyFetchedCount = self.alreadyFetchedCount+fetchedDocsCount
                            
                            let fullCollectionRef = self.db.collection("Users").document(userUID).collection(postListReference)
                            self.checkHowManyDocumentsThereAre(ref: fullCollectionRef)
                            
                            self.lastSavedPostsSnap = snap.documents.last // For the next batch
                            
                            switch whichPostList {
                            case .postsFromUser:
                                for document in snap.documents {
                                    let documentID = document.documentID
                                    let data = document.data()
                                    
                                    let post = Post()
                                    post.documentID = documentID
                                    if let _ = data["isTopicPost"] as? Bool {
                                        post.isTopicPost = true
                                    }
                                    if let language = data["language"] as? String {
                                        if language == "en" {
                                            post.language = .english
                                        }
                                    }
                                    documentIDsOfPosts.append(post)
                                }
                                
                                self.getPostsFromDocumentIDs(posts: documentIDsOfPosts, done: { (_) in
                                    // Needs to be sorted because the posts are fetched without the date that they were added
                                    self.posts.sort(by: { $0.createDate?.compare($1.createDate ?? Date()) == .orderedDescending })
                                    returnPosts(self.posts, self.initialFetch)
                                })
                            case .savedPosts:
                                for document in snap.documents {
                                    let documentID = document.documentID
                                    let data = document.data()
                                    
                                    let post = Post()
                                    post.documentID = documentID
                                    if let _ = data["isTopicPost"] as? Bool {
                                        post.isTopicPost = true
                                    }
                                    if let documentID = data["documentID"] as? String {
                                        post.documentID = documentID
                                    }
                                    if let language = data["language"] as? String {
                                        if language == "en" {
                                            post.language = .english
                                        }
                                    }
                                    documentIDsOfPosts.append(post)
                                }
                                
                                
                                self.getPostsFromDocumentIDs(posts: documentIDsOfPosts, done: { (_) in
                                    // Needs to be sorted because the posts are fetched without the date that they were added
                                    self.posts.sort(by: { $0.createDate?.compare($1.createDate ?? Date()) == .orderedDescending })
                                    returnPosts(self.posts, self.initialFetch)
                                })
                            }
                        }
                    }
                }
            }
        } else {    // No more Posts to fetch = End of list
            print("We already have all posts fetched")
            returnPosts(nil, self.initialFetch)
        }
    }
    
    //MARK:- Communities
    
    func getPostsForCommunity(getMore: Bool, fact: Fact, returnPosts: @escaping ([Post]?, _ InitialFetch:Bool) -> Void) {
        
        if fact.documentID != "" {
            if morePostsToFetch {
                self.posts.removeAll()
                
                var collectionRef: CollectionReference!
                if fact.language == .english {
                    collectionRef = self.db.collection("Data").document("en").collection("topics")
                } else {
                    collectionRef = self.db.collection("Facts")
                }
                
                var ref = collectionRef.document(fact.documentID).collection("posts").order(by: "createTime", descending: true).limit(to: 20)
                var documentIDsOfPosts = [Post]()
                
                // Check if the Feed has been refreshed or the next batch is ordered
                if getMore {
                    // For the next loading batch of 20, that will start after this snapshot if it is there
                    if let lastSnap = lastFeedPostSnap {
                        
                        // I think I have an issue with createDate + .start(afterDocument:) because there are some without date
                        ref = ref.start(afterDocument: lastSnap)
                        self.initialFetch = false
                    }
                } else { // Else you want to refresh the feed
                    self.initialFetch = true
                }
                
                ref.getDocuments { (snap, err) in
                    if let error = err {
                        print("We have an error: \(error.localizedDescription)")
                    } else {
                        if let snap = snap {
                            if snap.documents.count == 0 {    // Hasnt posted or saved anything yet
                                let post = Post()
                                post.type = .nothingPostedYet
                                returnPosts([post], self.initialFetch)
                            } else {
                                //Prepare the next batch
                                let fetchedDocsCount = snap.documents.count
                                self.alreadyFetchedCount = self.alreadyFetchedCount+fetchedDocsCount
                                
                                let fullCollectionRef = collectionRef.document(fact.documentID).collection("posts")
                                self.checkHowManyDocumentsThereAre(ref: fullCollectionRef)
                                
                                self.lastFeedPostSnap = snap.documents.last // For the next batch
                                
                                // Get right post objects for next fetch
                                for document in snap.documents {
                                    let documentID = document.documentID
                                    let data = document.data()
                                    
                                    let post = Post()
                                    post.documentID = documentID
                                    post.language = fact.language
                                    
                                    if let _ = data["type"] as? String {    // Sort between normal and "JustTopic" Posts
                                        post.isTopicPost = true
                                    }
                                    
                                    documentIDsOfPosts.append(post)
                                }
                                
                                self.getPostsFromDocumentIDs(posts: documentIDsOfPosts, done: { (_) in    // First fetch the normal Posts, then the "JustTopic" Posts
                                    self.posts.sort(by: { $0.createDate?.compare($1.createDate ?? Date()) == .orderedDescending })
                                    
                                    returnPosts(self.posts, self.initialFetch)
                                })
                            }
                        }
                    }
                }
            } else {
                print("We already have all posts fetched")
                returnPosts(nil, self.initialFetch)
            }
        } else {
            print("Error: no documentID for Fact")
            returnPosts(nil, self.initialFetch)
        }
    }
    
    func getPreviewPicturesForCommunity(community: Fact, posts: @escaping ([Post]?) -> Void) {
        if community.documentID != "" {
            
            var collectionRef: CollectionReference!
            if community.language == .english {
                collectionRef = self.db.collection("Data").document("en").collection("topicPosts")
            } else {
                collectionRef = self.db.collection("TopicPosts")
            }
            
            let ref = collectionRef.whereField("linkedFactID", isEqualTo: community.documentID).whereField("type", isEqualTo: "picture").limit(to: 6)
            
            ref.getDocuments { (snap, err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    if let snap = snap {
                        if snap.documents.count == 0 {    // Hasnt posted or saved anything yet
                            posts(nil)
                        } else {
                            var picturePosts = [Post]()
                            var count = snap.documents.count
                            
                            for document in snap.documents {
                                
                                if let post = self.addThePost(document: document, isTopicPost: true, forFeed: false, language: community.language) {
                                    picturePosts.append(post)
                                } else {
                                    count-=1
                                }
                                if picturePosts.count == count {
                                    posts(picturePosts)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func getTotalCount() -> Int {
        return self.totalCountOfPosts
    }
    
    
    func checkHowManyDocumentsThereAre(ref: CollectionReference) {
        
        //ToDo: Return number of Posts to display in the Profile
        ref.getDocuments { (querySnap, error) in
            if let error = error {
                print("We have an error: \(error.localizedDescription)")
            } else {
                let wholeCollectionDocumentCount = querySnap!.documents.count
                
                self.totalCountOfPosts = wholeCollectionDocumentCount
                
                if wholeCollectionDocumentCount <= self.alreadyFetchedCount {
                    self.morePostsToFetch = false
                }
            }
        }
    }
    
    // MARK:- Get Posts from DocumentIDs
    func getPostsFromDocumentIDs(posts: [Post], done: @escaping ([Post]?) -> Void) {
        print("Get posts")
        let endIndex = posts.count
        var startIndex = 0
        
        if posts.count == 0 {
            done(self.posts)
        } else {
            // The function has to be here for the right order
            for post in posts {
                var ref: DocumentReference!
                var collectionRef: CollectionReference!
                
                print("Das ist der post: \(post.isTopicPost), \(post.language)")
                
                if post.isTopicPost {
                    if post.language == .english {
                        collectionRef = self.db.collection("Data").document("en").collection("topicPosts")
                    } else {
                        collectionRef = self.db.collection("TopicPosts")
                    }
                    ref = collectionRef.document(post.documentID)
                } else {
                    if post.language == .english {
                        collectionRef = self.db.collection("Data").document("en").collection("posts")
                    } else {
                        collectionRef = self.db.collection("Posts")
                    }
                    ref = collectionRef.document(post.documentID)
                }
                ref.getDocument{ (document, err) in
                    if let error =  err {
                        print("We have an error: \(error.localizedDescription)")
                    } else {
                        if let document = document {
                            
                            self.getTheUsersFriend { (_) in // First get the friends to check which name to fetch
                                self.addThePost(document: document, isTopicPost: post.isTopicPost, forFeed: true, language: post.language)
                                
                                startIndex+=1
                                
                                if startIndex == endIndex {
                                    done(self.posts)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    //MARK:- addThePost
    
    ///Insert DocumentSnapshot and either get a full Post object back if "forFeed" is set to false or add the Post object to the posts array for the main feed to return the array later on
    func addThePost(document: DocumentSnapshot, isTopicPost: Bool, forFeed: Bool, language: Language) -> Post? {
        
        let documentID = document.documentID
        if let documentData = document.data() {
            
            
            if let postType = documentData["type"] as? String {
                
                // Werte die alle haben
                guard let title = documentData["title"] as? String,
                    let description = documentData["description"] as? String,
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
                
                let dateToSort = createTimestamp.dateValue()
                let stringDate = createTimestamp.dateValue().formatForFeed()
                let isAFriend: Bool = self.checkIfOPIsAFriend(userUID: originalPoster)
                
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
                    
                    let post = Post()
                    post.documentID = documentID
                    var surveyTypeEnum: SurveyType = .pickOrder
                    
                    if surveyType == "pickOne" {
                        surveyTypeEnum = .pickOne
                    } else if surveyType == "comment" {
                        surveyTypeEnum = .comment
                    }
                    
                    let survey = Survey(type: surveyTypeEnum, question: question)
                    post.survey = survey
                    
                    if let firstAnswer = documentData["firstAnswer"] as? String, let secondAnswer = documentData["secondAnswer"] as? String, let thirdAnswer = documentData["thirdAnswer"] as? String, let fourthAnswer = documentData["fourthAnswer"] as? String {
                        
                        survey.firstAnswer = firstAnswer
                        survey.secondAnswer = secondAnswer
                        survey.thirdAnswer = thirdAnswer
                        survey.fourthAnswer = fourthAnswer
                    }
                                                
                    if forFeed {
                        self.posts.append(post)
                        return nil
                    } else {
                        return post
                    }
                    
                    // Thought
                } else if postType == "thought" {
                    
                    
                    let post = Post()
                    post.title = title
                    post.description = description
                    post.type = .thought
                    post.documentID = documentID
                    post.createTime = stringDate
                    post.originalPosterUID = originalPoster
                    post.votes.thanks = thanksCount
                    post.votes.wow = wowCount
                    post.votes.ha = haCount
                    post.votes.nice = niceCount
                    post.createDate = dateToSort
                    post.language = language
                    
                    //Tried to export these extra values because they repeat themself in every "type" case but because of my async func "getFact" if a factID exists and move the post afterwards
                    if let report = self.handyHelper.setReportType(fetchedString: reportString) {
                        post.report = report
                    }
                    
                    if let notificationRecipients = documentData["notificationRecipients"] as? [String] {
                        post.notificationRecipients = notificationRecipients
                    }
                    
                    if let factID = documentData[factJSONString] as? String {
                        post.fact = self.addFact(factID: factID)
                    }
                    
                    if originalPoster == "anonym" {
                        post.anonym = true
                        if let anonymousName = documentData["anonymousName"] as? String {
                            post.anonymousName = anonymousName
                        }
                    } else {
                        post.getUser(isAFriend: isAFriend)
                    }
                    
                    post.isTopicPost = isTopicPost
                    
                    if let commentCount = documentData["commentCount"] as? Int {
                        post.commentCount = commentCount
                    } // else { its 0
                    
                    if forFeed {
                        self.posts.append(post)
                    } else {
                        return post
                    }
                    
                    
                    // Picture
                } else if postType == "picture" {
                    
                    guard let imageURL = documentData["imageURL"] as? String,
                        let picHeight = documentData["imageHeight"] as? Double,
                        let picWidth = documentData["imageWidth"] as? Double
                        
                        else {
                            return nil
                    }

                    let post = Post()
                    
                    let ratio = picWidth / picHeight
                    if ratio > 2 {
                        post.type = .panorama
                    } else {
                        post.type = .picture
                    }
                    post.title = title
                    post.imageURL = imageURL
                    post.mediaHeight = CGFloat(picHeight)
                    post.mediaWidth = CGFloat(picWidth)
                    post.description = description
                    post.documentID = documentID
                    post.createTime = stringDate
                    post.originalPosterUID = originalPoster
                    post.votes.thanks = thanksCount
                    post.votes.wow = wowCount
                    post.votes.ha = haCount
                    post.votes.nice = niceCount
                    post.createDate = dateToSort
                    post.language = language
                    
                    if let report = self.handyHelper.setReportType(fetchedString: reportString) {
                        post.report = report
                    }
                    
                    if let notificationRecipients = documentData["notificationRecipients"] as? [String] {
                        post.notificationRecipients = notificationRecipients
                    }
                    
                    if let factID = documentData[factJSONString] as? String {
                        post.fact = self.addFact(factID: factID)
                    }
                    
                    if originalPoster == "anonym" {
                        post.anonym = true
                        if let anonymousName = documentData["anonymousName"] as? String {
                            post.anonymousName = anonymousName
                        }
                    } else {
                        post.getUser(isAFriend: isAFriend)
                    }
                    
                    post.isTopicPost = isTopicPost
                    if let commentCount = documentData["commentCount"] as? Int {
                        post.commentCount = commentCount
                    } // else { its 0
                    
                    if forFeed {
                        self.posts.append(post)
                    } else {
                        return post
                    }
                    
                    // YouTubeVideo
                } else if postType == "multiPicture" {
                    guard let images = documentData["imageURLs"] as? [String],
                        let picHeight = documentData["imageHeight"] as? Double,
                        let picWidth = documentData["imageWidth"] as? Double
                        else {
                        return nil
                    }
                    
                    let post = Post()
                    post.title = title
                    post.mediaWidth = CGFloat(picWidth)
                    post.mediaHeight = CGFloat(picHeight)
                    post.imageURLs = images
                    post.description = description
                    post.type = .multiPicture
                    post.documentID = documentID
                    post.createTime = stringDate
                    post.originalPosterUID = originalPoster
                    post.votes.thanks = thanksCount
                    post.votes.wow = wowCount
                    post.votes.ha = haCount
                    post.votes.nice = niceCount
                    post.createDate = dateToSort
                    post.language = language
                    
                    if let report = self.handyHelper.setReportType(fetchedString: reportString) {
                        post.report = report
                    }
                    
                    if let notificationRecipients = documentData["notificationRecipients"] as? [String] {
                        post.notificationRecipients = notificationRecipients
                    }
                    
                    if let factID = documentData[factJSONString] as? String {
                        post.fact = self.addFact(factID: factID)
                    }
                    
                    if originalPoster == "anonym" {
                        post.anonym = true
                        if let anonymousName = documentData["anonymousName"] as? String {
                            post.anonymousName = anonymousName
                        }
                    } else {
                        post.getUser(isAFriend: isAFriend)
                    }
                    
                    post.isTopicPost = isTopicPost
                    if let commentCount = documentData["commentCount"] as? Int {
                        post.commentCount = commentCount
                    } // else { its 0
                    
                    if forFeed {
                        self.posts.append(post)
                    } else {
                        return post
                    }
                    
                } else if postType == "youTubeVideo" {
                    
                    guard let linkURL = documentData["link"] as? String else { return nil  }
                    
                    let post = Post()
                    post.title = title
                    post.linkURL = linkURL
                    post.description = description
                    post.type = .youTubeVideo
                    post.documentID = documentID
                    post.createTime = stringDate
                    post.originalPosterUID = originalPoster
                    post.votes.thanks = thanksCount
                    post.votes.wow = wowCount
                    post.votes.ha = haCount
                    post.votes.nice = niceCount
                    post.createDate = dateToSort
                    post.language = language
                    
                    if let report = self.handyHelper.setReportType(fetchedString: reportString) {
                        post.report = report
                    }
                    
                    if let notificationRecipients = documentData["notificationRecipients"] as? [String] {
                        post.notificationRecipients = notificationRecipients
                    }
                    
                    if let factID = documentData[factJSONString] as? String {
                        post.fact = self.addFact(factID: factID)
                    }
                    
                    if originalPoster == "anonym" {
                        post.anonym = true
                        if let anonymousName = documentData["anonymousName"] as? String {
                            post.anonymousName = anonymousName
                        }
                    } else {
                        post.getUser(isAFriend: isAFriend)
                    }
                    
                    post.isTopicPost = isTopicPost
                    if let commentCount = documentData["commentCount"] as? Int {
                        post.commentCount = commentCount
                    } // else { its 0
                    
                    if forFeed {
                        self.posts.append(post)
                    } else {
                        return post
                    }
                    
                    //Link
                } else if postType == "GIF" {
                    
                    guard let gifURL = documentData["link"] as? String
                        
                        else {
                            return nil
                    }
                    
                    let post = Post()
                    post.title = title
                    post.linkURL = gifURL
                    post.description = description
                    post.type = .GIF
                    post.documentID = documentID
                    post.createTime = stringDate
                    post.originalPosterUID = originalPoster
                    post.votes.thanks = thanksCount
                    post.votes.wow = wowCount
                    post.votes.ha = haCount
                    post.votes.nice = niceCount
                    post.createDate = dateToSort
                    post.language = language
                    
                    if let report = self.handyHelper.setReportType(fetchedString: reportString) {
                        post.report = report
                    }
                    
                    if let notificationRecipients = documentData["notificationRecipients"] as? [String] {
                        post.notificationRecipients = notificationRecipients
                    }
                    
                    if let factID = documentData[factJSONString] as? String {
                        post.fact = self.addFact(factID: factID)
                    }
                    
                    if let url = URL(string: gifURL) {
                        let size = handyHelper.getWidthAndHeightFromVideo(url: url)
                        
                        if let size = size {
                            post.mediaWidth = size.width
                            post.mediaHeight = size.height
                        } else {
                            print("Couldnt get a valid Video")
                            return nil
                        }
                    }
                    
                    if originalPoster == "anonym" {
                        post.anonym = true
                        if let anonymousName = documentData["anonymousName"] as? String {
                            post.anonymousName = anonymousName
                        }
                    } else {
                        post.getUser(isAFriend: isAFriend)
                    }
                    
                    post.isTopicPost = isTopicPost
                    if let commentCount = documentData["commentCount"] as? Int {
                        post.commentCount = commentCount
                    } // else { its 0
                    
                    if forFeed {
                        self.posts.append(post)
                    } else {
                        return post
                    }
                    
                } else if postType == "stop" {
                    
                } else if postType == "link" {
                    
                    guard let linkURL = documentData["link"] as? String
                        else {
                            return nil
                    }
                    var link: Link?
                    
                    if let shortURL = documentData["linkShortURL"] as? String, let linkTitle = documentData["linkTitle"] as? String, let linkDescription = documentData["linkDescription"] as? String {
                        let linkImageURL = documentData["linkImageURL"] as? String
                        
                        link = Link(link: linkURL, title: linkTitle, description: linkDescription, shortURL: shortURL, imageURL: linkImageURL)
                    } else if !linkURL.contains("songwhip.com") {
                        notifyMalte(documentID: documentID, isTopicPost: isTopicPost)
                    }
                    
                    let post = Post()
                    post.title = title
                    post.linkURL = linkURL
                    post.link = link
                    post.description = description
                    post.type = .link
                    post.documentID = documentID
                    post.createTime = stringDate
                    post.originalPosterUID = originalPoster
                    post.votes.thanks = thanksCount
                    post.votes.wow = wowCount
                    post.votes.ha = haCount
                    post.votes.nice = niceCount
                    post.createDate = dateToSort
                    post.language = language
                    
                    //look for songwhip data
                    if let type = documentData["musicType"] as? String,
                       let name = documentData["name"] as? String,
                       let releaseDateTimestamp = documentData["releaseDate"] as? Timestamp,
                       let artist = documentData["artist"] as? String,
                       let artistImage = documentData["artistImage"] as? String,
                       let musicImage = documentData["musicImage"] as? String {
                        
                        let releaseDate = releaseDateTimestamp.dateValue()
                        let musicType: MusicType!
                        if type == "track" {
                            musicType = .track
                        } else {
                            musicType = .album
                        }
                        
                        let music = Music(type: musicType, name: name, artist: artist, releaseDate: releaseDate, artistImageURL: artistImage, musicImageURL: musicImage, songwhipURL: linkURL)
                        post.music = music
                        
                    } else {
                        print("Couldnt get songwhip data")
                    }
                    
                    if let report = self.handyHelper.setReportType(fetchedString: reportString) {
                        post.report = report
                    }
                    
                    if let notificationRecipients = documentData["notificationRecipients"] as? [String] {
                        post.notificationRecipients = notificationRecipients
                    }
                    
                    if let factID = documentData[factJSONString] as? String {
                        post.fact = self.addFact(factID: factID)
                    }
                    
                    if originalPoster == "anonym" {
                        post.anonym = true
                        if let anonymousName = documentData["anonymousName"] as? String {
                            post.anonymousName = anonymousName
                        }
                    } else {
                        post.getUser(isAFriend: isAFriend)
                    }
                    
                    post.isTopicPost = isTopicPost
                    if let commentCount = documentData["commentCount"] as? Int {
                        post.commentCount = commentCount
                    } // else { its 0
                    
                    if forFeed {
                        self.posts.append(post)
                    } else {
                        return post
                    }
                    
                } else if postType == "singleTopic"  {
                    
                    let post = Post()
                    post.title = title
                    post.description = description
                    post.type = .singleTopic
                    post.documentID = documentID
                    post.createTime = stringDate
                    post.originalPosterUID = originalPoster
                    post.votes.thanks = thanksCount
                    post.votes.wow = wowCount
                    post.votes.ha = haCount
                    post.votes.nice = niceCount
                    post.createDate = dateToSort
                    post.language = language
                    
                    if let report = self.handyHelper.setReportType(fetchedString: reportString) {
                        post.report = report
                    }
                    
                    if let notificationRecipients = documentData["notificationRecipients"] as? [String] {
                        post.notificationRecipients = notificationRecipients
                    }
                    
                    if let factID = documentData[factJSONString] as? String {
                        post.fact = self.addFact(factID: factID)
                    }
                    
                    if originalPoster == "anonym" {
                        post.anonym = true
                        if let anonymousName = documentData["anonymousName"] as? String {
                            post.anonymousName = anonymousName
                        }
                    } else {
                        post.getUser(isAFriend: isAFriend)
                    }
                    
                    post.isTopicPost = isTopicPost
                    if let commentCount = documentData["commentCount"] as? Int {
                        post.commentCount = commentCount
                    } // else { its 0
                    
                    if forFeed {
                        self.posts.append(post)
                    } else {
                        return post
                    }
                    
                    
                    // Repost
                } else if postType == "repost" || postType == "translation" {
                    
                    guard let postDocumentID = documentData["OGpostDocumentID"] as? String
                        
                        else {
                            return nil
                    }
                    
                    let post = Post()
                    post.repostDocumentID = postDocumentID
                    if let repostLanguage = documentData["repostLanguage"] as? String {
                        if repostLanguage == "en" {
                            post.repostLanguage = .english
                            if post.language != .english {
                                post.type = .translation
                            }
                        } else if repostLanguage == "de" {
                            post.repostLanguage = .german
                            if post.language != .german {
                                post.type = .translation
                            }
                        }
                    } else {
                        post.type = .repost
                    }
                    if let repostIsTopicPost = documentData["repostIsTopicPost"] as? Bool {
                        post.repostIsTopicPost = repostIsTopicPost
                    }
                    post.title = title
                    post.description = description
                    post.createTime = stringDate
                    post.documentID = documentID
                    post.originalPosterUID = originalPoster
                    post.votes.thanks = thanksCount
                    post.votes.wow = wowCount
                    post.votes.ha = haCount
                    post.votes.nice = niceCount
                    post.createDate = dateToSort
                    post.language = language
                    
                    if let report = self.handyHelper.setReportType(fetchedString: reportString) {
                        post.report = report
                    }
                    
                    if let notificationRecipients = documentData["notificationRecipients"] as? [String] {
                        post.notificationRecipients = notificationRecipients
                    }
                    
                    if let factID = documentData[factJSONString] as? String {
                        post.fact = self.addFact(factID: factID)
                    }
                    
                    if originalPoster == "anonym" {
                        post.anonym = true
                        if let anonymousName = documentData["anonymousName"] as? String {
                            post.anonymousName = anonymousName
                        }
                    } else {
                        post.getUser(isAFriend: isAFriend)
                    }
                    
                    post.isTopicPost = isTopicPost
                    if let commentCount = documentData["commentCount"] as? Int {
                        post.commentCount = commentCount
                    } // else { its 0
                    
                    post.getRepost(returnRepost: { (repost) in
                        post.repost = repost
                    })
                    if forFeed {
                        self.posts.append(post)
                    } else {
                        return post
                    }
                }
            }
        }
        
        return nil
    }
    
    //MARK:- Stuff
    
    func notifyMalte(documentID: String, isTopicPost: Bool) {
        let maltesUID = "CZOcL3VIwMemWwEfutKXGAfdlLy1"
        let notificationRef = db.collection("Users").document(maltesUID).collection("notifications").document()
        let notificationData: [String: Any] = ["type": "message", "message": "Wir haben einen Link ohne URLPreview", "name": "System", "chatID": "Egal", "sentAt": Timestamp(date: Date()), "postID": documentID, "isTopicPost": isTopicPost]
        
        notificationRef.setData(notificationData) { (err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                print("Successfully set notification")
            }
        }
    }
    
    func addFact(factID: String) -> Fact {
        let fact = Fact()
        fact.documentID = factID
        for topic in self.followedTopics {
            if factID == topic {
                fact.beingFollowed = true
            }
        }
        return fact
    }
    
    func loadPost(post: Post, loadedPost: @escaping (Post?) -> Void) {
        let ref: DocumentReference!
        
        if post.documentID == "" {   // NewAddOnTableVC
            loadedPost(nil)
        }
        
        var collectionRef: CollectionReference!
        if post.isTopicPost {
            if post.language == .english {
                collectionRef = self.db.collection("Data").document("en").collection("topicPosts")
            } else {
                collectionRef = self.db.collection("TopicPosts")
            }
            ref = collectionRef.document(post.documentID)
        } else {
            if post.language == .english {
                collectionRef = self.db.collection("Data").document("en").collection("posts")
            } else {
                collectionRef = self.db.collection("Posts")
            }
            ref = collectionRef.document(post.documentID)
        }
        
        ref.getDocument { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap {
                    if let fullPost = self.addThePost(document: snap, isTopicPost: post.isTopicPost, forFeed: false, language: post.language){
                        loadedPost(fullPost)
                    }
                }
            }
        }
    }
    
    func getChatUser(uid: String, sender: Bool, user: @escaping (ChatUser) -> Void) {
        
        let userRef = db.collection("Users").document(uid)
        
        var chatUser : ChatUser?
        
        userRef.getDocument(completion: { (document, err) in
            if let document = document {
                if let docData = document.data() {
                    
                    guard let name = docData["name"] as? String,
                        let surname = docData["surname"] as? String
                        else {
                            return
                    }
                    
                    // Hier Avatar als UIImage einführen
                    
                    if let imageURL = docData["profilePictureURL"] as? String {
                        
                        if let url = URL(string: imageURL) {
                            let defchatUser = ChatUser(displayName: "\(name) \(surname)", avatar: nil, avatarURL: url, isSender: sender)
                            
                            chatUser = defchatUser
                        }
                    } else {
                        let defchatUser = ChatUser(displayName: "\(name) \(surname)", avatar: nil, avatarURL: nil, isSender: sender)
                        chatUser = defchatUser
                    }
                }
            }
            if let err = err {
                print("Wir haben einen Error beim User: \(err.localizedDescription)")
            }
            
            if let daChatUser = chatUser{
                user(daChatUser)    // Return User
            }
        })
    }
}


class Event {
    var title = ""
    var description = ""
    var time = ""
    var location = ""
    var type = ""
    var imageURL = ""
    var createDate = ""
    var imageHeight:CGFloat = 0
    var imageWidth:CGFloat = 0
    var participants = [String]()
    var admin = User()
    
}
