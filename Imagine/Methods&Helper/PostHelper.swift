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
    var lastEventSnap: QueryDocumentSnapshot?
    var lastSavedPostsSnap: QueryDocumentSnapshot?
    
    /* These two variables are here to make sure that we just fetch as many as there are documents and dont start at the beginning again  */
    var morePostsToFetch = true
    var alreadyFetchedCount = 0
    
    func getPostsForMainFeed(getMore:Bool, returnPosts: @escaping ([Post], _ InitialFetch:Bool) -> Void) {
        
        posts.removeAll()
        
        let settings = db.settings
        settings.areTimestampsInSnapshotsEnabled = true
        db.settings = settings
        
        
        
        var postRef = db.collection("Posts").order(by: "createTime", descending: true).limit(to: 20)
        
        if getMore {    // If you want to get More Posts
            if let lastSnap = lastSnap {        // For the next loading batch of 20, that will start after this snapshot
                postRef = postRef.start(afterDocument: lastSnap)
                self.initialFetch = false
            }
        } else { // Else you want to refresh the feed
            self.initialFetch = true
        }
        
        postRef.getDocuments { (querySnapshot, error) in
            
            self.lastSnap = querySnapshot?.documents.last    // Last document for the next fetch cycle
            
            for document in querySnapshot!.documents {
                self.addThePost(document: document)
            }
            self.getCommentCount(completion: {
                returnPosts(self.posts, self.initialFetch)
            })
        }
    }
    
    
    
    func getTheSavedPosts(getMore: Bool, whichPostList: PostList, userUID : String, returnPosts: @escaping ([Post], _ InitialFetch:Bool) -> Void) {
        
        // check if there are more posts to fetch
        if morePostsToFetch {
            
            posts.removeAll()
            
            var postListReference:String?
            
            switch whichPostList {
            case .postsFromUser:
                postListReference = "posts"
            case .savedPosts:
                postListReference = "saved"
            }
            print("Hier wird jetzt gearbeitet. InitialFetch: ", initialFetch)
            var documentIDsOfPosts = [String]()
            
            if let ref = postListReference {
                
                var userPostRef = db.collection("Users").document(userUID).collection(ref).order(by: "createTime", descending: true).limit(to: 20)
                
                
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
                
                
                userPostRef.getDocuments { (querySnapshot, error) in
                    if error != nil {
                        print("Wir haben einen Error bei den Userposts: \(error?.localizedDescription ?? "No error")")
                    }
                    
                    if querySnapshot!.documents.count == 0 {    // Hasnt posted or saved anything yet
                        let post = Post()
                        post.type = .nothingPostedYet
                        returnPosts([post], self.initialFetch)
                    }
                    
                    let fetchedDocsCount = querySnapshot!.documents.count
                    self.alreadyFetchedCount = self.alreadyFetchedCount+fetchedDocsCount
                    
                    let fullCollectionRef = self.db.collection("Users").document(userUID).collection(ref)
                    self.checkHowManyDocumentsThereAre(ref: fullCollectionRef)
                    
                    self.lastSavedPostsSnap = querySnapshot?.documents.last // For the next batch
                    
                    switch whichPostList {
                    case .postsFromUser:
                        for document in querySnapshot!.documents {
                            let documentID = document.documentID
                            
                            documentIDsOfPosts.append(documentID)
                        }
                        
                        self.getPostsFromDocumentIDs(documentIDs: documentIDsOfPosts, done: { (done) in
                            if done {
                                returnPosts(self.posts, self.initialFetch)
                            }
                        })
                    case .savedPosts:
                        for document in querySnapshot!.documents {
                            let docData = document.data()
                            
                            if let documentID = docData["documentID"] as? String {
                                print("DocID: ", documentID)
                                documentIDsOfPosts.append(documentID)
                            }
                        }
                        
                        self.getCommentCount(completion: { })
                        
                        self.getPostsFromDocumentIDs(documentIDs: documentIDsOfPosts, done: { (done) in
                            if done {
                                returnPosts(self.posts, self.initialFetch)
                            }
                        })
                    }
                }
            }
        } else {    // No more Posts to fetch = End of list
            print("We already have all posts fetched")
        }
    }
    
    
    func checkHowManyDocumentsThereAre(ref: CollectionReference) {
        
        ref.getDocuments { (querySnap, error) in
            if let error = error {
                print("We have an error: \(error.localizedDescription)")
            } else {
                let wholeCollectionDocumentCount = querySnap!.documents.count
                
                if wholeCollectionDocumentCount <= self.alreadyFetchedCount {
                    self.morePostsToFetch = false
                }
            }
        }
        
    }
    
    func getPostsFromDocumentIDs(documentIDs: [String], done: @escaping (Bool) -> Void) {
        
        let endIndex = documentIDs.count
        var startIndex = 0
        
        // The function has to be here for the right order
        for documentIDofPost in documentIDs {
            self.db.collection("Posts").document(documentIDofPost).getDocument{ (document, err) in
                if err != nil {
                    print("Wir haben einen Error: \(err?.localizedDescription ?? "no error")")
                } else {
                    if let document = document {
                        self.addThePost(document: document)
                        
                        startIndex = startIndex+1
                        
                        print("StartIndex: \(startIndex) | EndIndex: \(endIndex)")
                        if startIndex == endIndex {
                            done(true)
                        }
                    }
                }
            }
        }
    }
    
    
    
    
    func addThePost(document: DocumentSnapshot) {
        
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
                        return
                }
                
                
                
                let stringDate = self.handyHelper.getStringDate(timestamp: createTimestamp)
                
                // Thought
                if postType == "thought" {
                    
                    
                    let post = Post()       // Erst neuen Post erstellen
                    post.title = title      // Dann die Sachen zuordnen
                    post.description = description
                    post.type = .thought
                    post.documentID = documentID
                    post.createTime = stringDate
                    post.originalPosterUID = originalPoster
                    post.votes.thanks = thanksCount
                    post.votes.wow = wowCount
                    post.votes.ha = haCount
                    post.votes.nice = niceCount
                    
                    if let report = self.handyHelper.setReportType(fetchedString: reportString) {
                        post.report = report
                    }
                    
                    post.getUser()
                    self.posts.append(post)
                    
                    
                    // Picture
                } else if postType == "picture" {
                    
                    guard let imageURL = documentData["imageURL"] as? String,
                        let picHeight = documentData["imageHeight"] as? Double,
                        let picWidth = documentData["imageWidth"] as? Double
                        
                        else {
                            return     // Falls er das nicht als (String) zuordnen kann
                    }
                    
                    let post = Post()       // Erst neuen Post erstellen
                    post.title = title      // Dann die Sachen zuordnen
                    post.imageURL = imageURL
                    post.imageHeight = CGFloat(picHeight)
                    post.imageWidth = CGFloat(picWidth)
                    post.description = description
                    post.type = .picture
                    post.documentID = documentID
                    post.createTime = stringDate
                    post.originalPosterUID = originalPoster
                    post.votes.thanks = thanksCount
                    post.votes.wow = wowCount
                    post.votes.ha = haCount
                    post.votes.nice = niceCount
                    
                    if let report = self.handyHelper.setReportType(fetchedString: reportString) {
                        post.report = report
                    }
                    
                    post.getUser()
                    self.posts.append(post)
                    
                    // YouTubeVideo
                } else if postType == "youTubeVideo" {
                    
                    
                    guard let linkURL = documentData["link"] as? String else { return  }
                    
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
                    
                    if let report = self.handyHelper.setReportType(fetchedString: reportString) {
                        post.report = report
                    }
                    
                    post.getUser()
                    self.posts.append(post)
                    
                    //Link
                } else if postType == "link" {
                    
                    guard let linkURL = documentData["link"] as? String
                        
                        else {
                            return     // Falls er das nicht als (String) zuordnen kann
                    }
                    
                    let post = Post()       // Erst neuen Post erstellen
                    post.title = title      // Dann die Sachen zuordnen
                    post.linkURL = linkURL
                    post.description = description
                    post.type = .link
                    post.documentID = documentID
                    post.createTime = stringDate
                    post.originalPosterUID = originalPoster
                    post.votes.thanks = thanksCount
                    post.votes.wow = wowCount
                    post.votes.ha = haCount
                    post.votes.nice = niceCount
                    
                    if let report = self.handyHelper.setReportType(fetchedString: reportString) {
                        post.report = report
                    }
                    
                    post.getUser()
                    self.posts.append(post)
                    
                    // Repost
                } else if postType == "repost" || postType == "translation" {
                    
                    guard let postDocumentID = documentData["OGpostDocumentID"] as? String
                        
                        else {
                            return
                    }
                    
                    let post = Post()
                    post.type = .repost
                    post.title = title
                    post.description = description
                    post.createTime = stringDate
                    post.OGRepostDocumentID = postDocumentID
                    post.documentID = documentID
                    post.originalPosterUID = originalPoster
                    post.votes.thanks = thanksCount
                    post.votes.wow = wowCount
                    post.votes.ha = haCount
                    post.votes.nice = niceCount
                    
                    if let report = self.handyHelper.setReportType(fetchedString: reportString) {
                        post.report = report
                    }
                    
                    post.getRepost(returnRepost: { (repost) in
                        post.repost = repost
                    })
                    
                    post.getUser()
                    
                    
                    self.posts.append(post)
                }
            }
        }
    }
    
    func getEvent(completion: @escaping (Post) -> Void) {
        
        var eventRef = db.collection("Events").limit(to: 1)
        
        if let lastEventSnap = lastEventSnap {        // For the next loading batch of 20, there will be one event
            eventRef = eventRef.start(afterDocument: lastEventSnap)
        }
        
        eventRef.getDocuments { (eventSnap, err) in
            if let err = err {
                print("Wir haben einen Error beim Event: \(err.localizedDescription)")
            }
            
            for event in eventSnap!.documents {
                
                let documentID = event.documentID
                let documentData = event.data()
                
                guard let title = documentData["title"] as? String,
                    let description = documentData["description"] as? String,
                    let location = documentData["location"] as? String,
                    let type = documentData["type"] as? String,
                    let imageURL = documentData["imageURL"] as? String,
                    let imageHeight = documentData["imageHeight"] as? CGFloat,
                    let imageWidth = documentData["imageWidth"] as? CGFloat,
                    let participants = documentData["participants"] as? [String],
                    let admin = documentData["admin"] as? String,
                    let createDate = documentData["createDate"] as? Timestamp
                    
                    else {
                        continue
                }
                
                let stringDate = HandyHelper().getStringDate(timestamp: createDate)
                
                let post = Post()
                let event = Event()
                
                event.title = title
                event.description = description
                event.location = location
                event.type = type
                event.imageURL = imageURL
                event.imageWidth = imageWidth
                event.imageHeight = imageHeight
                event.participants = participants
                event.createDate = stringDate
                
                post.originalPosterUID = admin
                post.documentID = documentID
                post.type = .event
                
                post.event = event
                
                completion(post)
                
            }
            
        }
        
    }
    
    func getUsers(postList: [Post], completion: @escaping ([Post]) -> Void) {
        //Wenn die Funktion fertig ist soll returnPosts bei der anderen losgehen
        for post in postList {
            // Vorläufig Daten hinzufügen
            //              print("postID::::::" , post.documentID)
            //            if post.type == "repost" || post.type == "translation" {
            //                let postRef = db.collection("Posts").document(post.documentID)
            //                let documentData : [String:Any] = ["thanksCount": 8, "wowCount": 4, "haCount": 3, "niceCount": 2]
            //
            //                postRef.setData(documentData, merge: true)
            //            }
            
            
            // User Daten raussuchen
            let userRef = db.collection("Users").document(post.originalPosterUID)
            
            userRef.getDocument(completion: { (document, err) in
                if let document = document {
                    if let docData = document.data() {
                        let user = User()
                        
                        user.name = docData["name"] as? String ?? ""
                        user.surname = docData["surname"] as? String ?? ""
                        user.imageURL = docData["profilePictureURL"] as? String ?? ""
                        user.userUID = post.originalPosterUID
                        
                        post.user = user
                    }
                }
                
                if let err = err {
                    print("Wir haben einen Error beim User: \(err.localizedDescription)")
                }
            })
            
        }
        completion(postList)
    }
    
    
    func getCommentCount(completion: () -> Void) {
        //Wenn die Funktion fertig ist soll returnPosts bei der anderen losgehen
        
        for post in self.posts {
            // Comment Count raussuchen wenn Post
            
            if post.type != .event { // Wenn kein Event
                
                let commentRef = db.collection("Comments").document(post.documentID).collection("threads")
                
                commentRef.getDocuments { (snapshot, err) in
                    if let err = err {
                        print("Wir haben einen Error beim User: \(err.localizedDescription)")
                    }
                    if let snapshot = snapshot {
                        let number = snapshot.count
                        post.commentCount = number
                    }
                }
            }
        }
        
        completion()
    }
    
    
    
    
    
    func getChatUser(uid: String, sender: Bool, user: @escaping (ChatUser) -> Void) {
        
        let userRef = db.collection("Users").document(uid)
        
        var chatUser : ChatUser?
        
        userRef.getDocument(completion: { (document, err) in
            if let document = document {
                if let docData = document.data() {
                    
                    guard let name = docData["name"] as? String,
                        let surname = docData["surname"] as? String,
                        let imageURL = docData["profilePictureURL"] as? String
                        else {
                            return
                    }
                    
                    // Hier Avatar als UIImage einführen
                    
                    if let url = URL(string: imageURL) {
                        let defchatUser = ChatUser(displayName: "\(name) \(surname)", avatar: nil, avatarURL: url, isSender: sender)
                        
                        //                        let imageView = UIImageView()
                        //                        var image = UIImage()
                        //                        imageView.sd_setImage(with: url, completed: { (newImage, _, _, _) in
                        //
                        //                        })
                        //                        if let data = try? Data(contentsOf: url) {
                        //                            let image:UIImage = UIImage.sd_image(with: data)
                        //                        }
                        
                        chatUser = defchatUser
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
                user(daChatUser)
            }
        })
    }
}


class Votes {
    var thanks = 0
    var wow = 0
    var ha = 0
    var nice = 0
}

class ReportOptions {
    // Optisch Markieren
    let opticOptionArray = ["Spoiler", "Meinung, kein Fakt", "Sensationalismus", "Circlejerk", "Angeberisch", "Bildbearbeitung", "Schwarz-Weiß-Denken"]
    // Schlechte Absichten
    let badIntentionArray = ["Hass gegen ...","Respektlos", "Beleidigend", "(sexuell) Belästigend", "Rassistisch", "Homophob", "Gewaltunterstüztend", "Verharmlosung von Suizid", "Glauben nicht respektieren"]
    // Lüge/Täuschung
    let lieDeceptionArray = ["Fake News","Beweise verneinen", "Verschwörungstheorie"]
    // Inhalt
    let contentArray = ["Pornografie","Pedophilie", "Gewaltdarstellung", "Vorurteil"]
}
