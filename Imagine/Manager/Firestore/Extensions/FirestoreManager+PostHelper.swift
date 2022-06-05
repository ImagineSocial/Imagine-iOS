//
//  FirestoreManager+Post.swift
//  Imagine
//
//  Created by Don Malte on 25.09.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import Foundation
import FirebaseFirestore
import CoreLocation

class PostHelper {
    
    static let shared = PostHelper()
    
    //MARK: - Variables
    let handyHelper = HandyHelper.shared
    let factJSONString = "linkedFactID"
    
    //
    var firestoreRequest: FirestoreRequest?
    
    
    //MARK: - Class Initilizer
    
    ///Initialization for the FirestoreRequest Class
    init(firestoreRequest: FirestoreRequest) {
        self.firestoreRequest = firestoreRequest
        
    }
    
    ///Initialization if you just need to Add a Post object
    init() {
        
    }
    
    //MARK:- addThePost
    
    ///Insert DocumentSnapshot and either get a full Post object back if "forFeed" is set to false or add the Post object to the posts array for the main feed to return the array later on
    func addThePost(document: DocumentSnapshot, isTopicPost: Bool, language: Language) -> Post? {
        
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
                    
                    let size = handyHelper.getWidthAndHeightFromVideo(urlString: gifURL)
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
                        let musicType: MusicType!
                        if type == "track" {
                            musicType = .track
                        } else {
                            musicType = .album
                        }
                        
                        let music = Music(type: musicType, name: name, artist: artist, releaseDate: releaseDate, artistImageURL: artistImage, musicImageURL: musicImage, songwhipURL: linkURL)
                        post.music = music
                        
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
                    if let repostLanguage = documentData["repostLanguage"] as? String {
                        if repostLanguage == "en" {
                            post.repostLanguage = .en
                            if post.language != .en {
                                post.type = .translation
                            }
                        } else if repostLanguage == "de" {
                            post.repostLanguage = .de
                            if post.language != .de {
                                post.type = .translation
                            }
                        }
                    } else {
                        post.type = .repost
                    }
                    if let repostIsTopicPost = documentData["repostIsTopicPost"] as? Bool {
                        post.repostIsTopicPost = repostIsTopicPost
                    }
                    
                    post.getRepost(returnRepost: { (repost) in
                        post.repost = repost
                    })
                    
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
    func getDefaultPost(document: DocumentSnapshot) -> Post? {
        
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
        let isAFriend: Bool!
        
        if let request = firestoreRequest {
            isAFriend = request.checkIfOPIsAFriend(userUID: originalPoster)
        } else {
            isAFriend = false
        }
        
        let post = Post(type: .picture, title: title, createDate: createTimestamp.dateValue())
        post.description = documentData["description"] as? String
        post.documentID = document.documentID
        post.votes.thanks = thanksCount
        post.votes.wow = wowCount
        post.votes.ha = haCount
        post.votes.nice = niceCount
        
        //Tried to export these extra values because they repeat themself in every "type" case but because of my async func "getFact" if a factID exists and move the post afterwards
        if let report = self.handyHelper.setReportType(fetchedString: reportString) {
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
            user.getUser(isAFriend: isAFriend) { user in
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
    
    
    //MARK:- Community
    
    func addCommunity(communityID: String) -> Community {
        
        if let request = firestoreRequest {
            let community = request.addFact(factID: communityID)
            
            return community
        } else {
            let community = Community()
            community.documentID = communityID
            
            return community
        }
    }
}

