//
//  DataHelper.swift
//  Imagine
//
//  Created by Malte Schoppe on 21.05.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import Foundation
import Firebase
import FirebaseFirestore

enum DataType {
    case jobOffer
    case facts
    case blogPosts
    case vote
    case campaign
}

enum DeepDataType {
    case arguments
    case sources
}
/*
 var collectionRef: CollectionReference!
 let language = LanguageSelection().getLanguage()
 if language == .english {
     collectionRef = db.collection("Data").document("en").collection("posts")
 } else {
     collectionRef = db.collection("Posts")
 }
 */

class DataRequest {
    
    /*  Every data from firebase which are not posts are fetched through this class
     */
    
    //MARK:- Variables
    var dataPath = ""
    let db = Firestore.firestore()
    let handyHelper = HandyHelper()
    let user = Auth.auth().currentUser
    
    //MARK:- Get Data 
    
    func getData(get: DataType, returnData: @escaping ([Any]) -> Void) {
        // "get" Variable kann "campaign" für CommunityEntscheidungen, "jobOffer" für Hilfe der Community und "fact" für COmmunites Dings sein
        
        var list = [Any]()
        
        var orderString = ""
        var descending = false
        
        var collectionRef: CollectionReference!
        let language = LanguageSelection().getLanguage()
        
        switch get {
        case .blogPosts:
            list = [BlogPost]()
            dataPath = "BlogPosts"
            if language == .english {
                dataPath = "blogPosts"
            }
            
            orderString = "createDate"
            
        case .campaign:
            list = [Campaign]()
            dataPath = "Campaigns"
            if language == .english {
                dataPath = "campaigns"
            }
            
            orderString = "supporter"
            descending = true
            
        case .vote:
            list = [Vote]()
            dataPath = "Votes"
            if language == .english {
                dataPath = "votes"
            }
            
            orderString = "endOfVoteDate"
            
        case .facts:
            list = [Fact]()
            dataPath = "Facts"
            if language == .english {
                dataPath = "topics"
            }
            
            orderString = "popularity"
            descending = true
            
        case .jobOffer:
            list = [JobOffer]()
            dataPath = "JobOffers"
            if language == .english {
                dataPath = "jobOffers"
            }
            
            orderString = "importance"
            descending = true
            
            
        }
        
        if language == .english {
            collectionRef = db.collection("Data").document("en").collection(dataPath)
        } else {
            collectionRef = db.collection(dataPath)
        }
        var ref = collectionRef.order(by: orderString, descending: descending)
        
        if get == .facts {
            if language == .english {
                collectionRef = db.collection("Data").document("en").collection("topics")
            } else {
                collectionRef = db.collection("Facts")
            }
            
            ref = collectionRef.whereField("displayOption", isEqualTo: "topic").order(by: "popularity", descending: true).limit(to: 8)
        }
        
        ref.getDocuments { (querySnapshot, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = querySnapshot {
                    
                    if snap.documents.count == 0 {
                        returnData(list)
                        return
                    }
                    for document in snap.documents {
                        let documentID = document.documentID
                        let documentData = document.data()
                        
                        switch get {
                        case .blogPosts:
                            guard let title = documentData["title"] as? String,
                                  let createTimestamp = documentData["createDate"] as? Timestamp,
                                  let subtitle = documentData["subtitle"] as? String,
                                  let poster = documentData["poster"] as? String,
                                  let profileImageURL = documentData["profileImageURL"] as? String,
                                  let category = documentData["category"] as? String,
                                  let description = documentData["description"] as? String
                            
                            else {
                                continue
                            }
                            
                            let date = createTimestamp.dateValue()
                            let stringDate = date.formatRelativeString()
                            
                            let blogPost = BlogPost()
                            blogPost.title = title
                            blogPost.subtitle = subtitle
                            blogPost.stringDate = stringDate
                            blogPost.poster = poster
                            blogPost.profileImageURL = profileImageURL
                            blogPost.category = category
                            blogPost.description = description
                            blogPost.createDate = date
                            
                            if let imageURL = documentData["imageURL"] as? String {
                                blogPost.imageURL = imageURL
                            }
                            
                            list.append(blogPost)
                        case .campaign:
                            if let campaignType = documentData["type"] as? String {
                                if campaignType == "normal" {
                                    
                                    guard let title = documentData["title"] as? String,
                                          let shortBody = documentData["summary"] as? String,
                                          let createTimestamp = documentData["createTime"] as? Timestamp,
                                          let supporter = documentData["supporter"] as? Int,
                                          let opposition = documentData["opposition"] as? Int,
                                          let category = documentData["category"] as? String
                                    else {
                                        continue    // Falls er das nicht als (String) zuordnen kann
                                    }
                                    
                                    let date = createTimestamp.dateValue()
                                    let stringDate = date.formatRelativeString()
                                    
                                    let campaign = Campaign()       // Erst neue Campaign erstellen
                                    campaign.title = title      // Dann die Sachen zuordnen
                                    campaign.cellText = shortBody
                                    campaign.documentID = documentID
                                    campaign.createDate = stringDate
                                    campaign.supporter = supporter
                                    campaign.opposition = opposition
                                    campaign.createTime = date
                                    campaign.category = self.getCampaignType(categoryString: category)
                                    
                                    if let description = documentData["description"] as? String {
                                        campaign.descriptionText = description
                                    }
                                    
                                    list.append(campaign)
                                }
                            }
                        case .vote:
                            guard let title = documentData["title"] as? String,
                                  let subtitle = documentData["subtitle"] as? String,
                                  let description = documentData["description"] as? String,
                                  let createTimestamp = documentData["createDate"] as? Timestamp,
                                  let voteTillDateTimestamp = documentData["endOfVoteDate"] as? Timestamp,
                                  let cost = documentData["cost"] as? Double,
                                  let impactString = documentData["impact"] as? String,
                                  let timeToRealization = documentData["timeToRealization"] as? Int,
                                  let costDescription = documentData["costDescription"] as? String,
                                  let impactDescription = documentData["impactDescription"] as? String,
                                  let realizationTimeDescription = documentData["realizationTimeDescription"] as? String
                            else {
                                continue
                            }
                            
                            let date = createTimestamp.dateValue()
                            let createDate = self.handyHelper.getStringDate(timestamp: createTimestamp)
                            let endDate = voteTillDateTimestamp.dateValue()
                            let endOfVoteDate = endDate.formatRelativeString()
                            let costString = self.handyHelper.getLocaleCurrencyString(number: cost)
                            
                            var impact:Impact = .light
                            
                            switch impactString {
                            case "medium":
                                impact = .medium
                            case "strong":
                                impact = .strong
                            default:
                                impact = .light
                            }
                            
                            let vote = Vote()
                            vote.title = title
                            vote.subtitle = subtitle
                            vote.description = description
                            vote.stringDate = createDate
                            vote.endOfVoteDate = endOfVoteDate
                            vote.cost = costString
                            vote.impact = impact
                            vote.timeToRealization = timeToRealization
                            vote.costDescription = costDescription
                            vote.impactDescription = impactDescription
                            vote.realizationTimeDescription = realizationTimeDescription
                            vote.documentID = documentID
                            vote.createDate = date
                            
                            list.append(vote)
                            
                        case .facts:
                            if let fact = self.addFact(currentUser: self.user, documentID: documentID, data: documentData) {
                                list.append(fact)
                            }
                        case .jobOffer:
                            guard let title = documentData["jobTitle"] as? String,
                                  let shortBody = documentData["jobShortBody"] as? String,
                                  let createTime = documentData["jobCreateTime"] as? Timestamp,
                                  let interestedCount = documentData["interestedInJob"] as? Int,
                                  let category = documentData["category"] as? String
                            else {
                                continue    // Falls er das nicht als (String) zuordnen kann
                            }
                            
                            let date = createTime.dateValue()
                            let stringDate = date.formatRelativeString()
                            
                            let jobOffer = JobOffer()       // Erst neue Campaign erstellen
                            jobOffer.title = title      // Dann die Sachen zuordnen
                            jobOffer.cellText = shortBody
                            jobOffer.documentID = documentID
                            jobOffer.stringDate = stringDate
                            jobOffer.interested = interestedCount
                            jobOffer.category = category
                            if let description = documentData["description"] as? String {
                                jobOffer.descriptionText = description
                            }
                            jobOffer.createDate = date
                            
                            list.append(jobOffer)
                        }
                        
                    }
                    returnData(list)
                } else {
                    returnData(list)
                }
            }
        }
    }
    
    func getCategoryLabelText(type: CampaignType) -> String {
        switch type {
        case .proposal:
            return NSLocalizedString("dataHelper_proposal_label", comment: "proposal")
        case .complaint:
            return NSLocalizedString("dataHelper_complaint_label", comment: "complaint")
        case .call:
            return NSLocalizedString("dataHelper_call_label", comment: "call for action")
        case .change:
            return NSLocalizedString("dataHelper_change_label", comment: "change")
        case .topicAddOn:
            return NSLocalizedString("dataHelper_topic_addOn", comment: "topic addOn")
        }
    }
    
    func getCampaignType(categoryString: String) -> CampaignCategory {
        
        switch categoryString {
        case "complaint":
            return CampaignCategory(title: getCategoryLabelText(type: .complaint), type: .complaint)
        case "call":
            return CampaignCategory(title: getCategoryLabelText(type: .call), type: .call)
        case "change":
            return CampaignCategory(title: getCategoryLabelText(type: .change), type: .change)
        case "topicAddOn":
            return CampaignCategory(title: getCategoryLabelText(type: .topicAddOn), type: .topicAddOn)
        default:
            return CampaignCategory(title: getCategoryLabelText(type: .proposal), type: .proposal)
        }
    }
    
    func getFollowedTopicDocuments(userUID: String, documents: @escaping ([QueryDocumentSnapshot]) -> Void) {
        let topicRef = db.collection("Users").document(userUID).collection("topics")
        
        topicRef.getDocuments { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap {
                    documents(snap.documents)
                }
            }
        }
    }
    
    
    func addFact(currentUser: Firebase.User?, documentID: String, data: [String: Any]) -> Fact? {
        
        guard let name = data["name"] as? String,
            let createTimestamp = data["createDate"] as? Timestamp,
            let OP = data["OP"] as? String
            else {
                print("Der will nicht: \(documentID), mit den Daten: \(data)")
                return nil
        }
        
        let stringDate = self.handyHelper.getStringDate(timestamp: createTimestamp)
        
        let fact = Fact()
        fact.documentID = documentID
        fact.title = name
        fact.createDate = stringDate
        fact.moderators.append(OP)  //Later there will be more moderators, so it is an array
        
        if let postCount = data["postCount"] as? Int {
            fact.postCount = postCount
        }
        
        if let follower = data["follower"] as? [String] {
            fact.followerCount = follower.count
            if let user = currentUser {
                for userID in follower {
                    if userID == user.uid {
                        fact.beingFollowed = true
                    }
                }
            }
        }
        
        if let language = data["language"] as? String {
            if language == "en" {
                fact.language = .english
            }
        }
        
        if let imageURL = data["imageURL"] as? String { // Not mandatory (in fact not selectable)
            fact.imageURL = imageURL
        }
        if let description = data["description"] as? String {   // Was introduced later on
            fact.description = description
        }
        if let displayType = data["displayOption"] as? String { // Was introduced later on
            fact.displayOption = self.getDisplayType(string: displayType)
        }
        
        if let displayNames = data["factDisplayNames"] as? String {
            fact.factDisplayNames = self.getDisplayNames(string: displayNames)
        }
        
        if let isAddOnFirstView = data["isAddOnFirstView"] as? Bool {
            fact.isAddOnFirstView = isAddOnFirstView
        }
        
        fact.fetchComplete = true
        
        return fact
    }
    
    func loadFact(fact: Fact, loadedFact: @escaping (Fact?) -> Void) {
        
        if fact.documentID == "" {
            loadedFact(nil)
        }
        
        var collectionRef: CollectionReference!
        if fact.language == .english {
            collectionRef = db.collection("Data").document("en").collection("topics")
        } else {
            collectionRef = db.collection("Facts")
        }
        let ref = collectionRef.document(fact.documentID)
        
        
        ref.getDocument { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap {
                    if let data = snap.data() {
                        if let fact = self.addFact(currentUser: self.user, documentID: snap.documentID, data: data) {
                            loadedFact(fact)
                        } else {
                            loadedFact(nil)
                        }
                    }
                }
            }
        }
    }
    
    func getDisplayType(string: String) -> DisplayOption {
        switch string {
        case "topic":
            return .topic
        default:
            return .fact
        }
    }
    
    func getDisplayNames(string: String) -> FactDisplayName {
        switch string {
        case "confirmDoubt":
            return .confirmDoubt
        case "advantage":
            return .advantageDisadvantage
        default:
            return .proContra
        }
    }
    
    func getDeepData(fact: Fact, returnData: @escaping ([Any]) -> Void) {
        
        var argumentList = [Argument]()
        
        if fact.documentID == "" {
            print("We have an error fetching arguments")
            returnData(argumentList)
        }
        
        var collectionRef: CollectionReference!
        let language = LanguageSelection().getLanguage()
        if fact.language == .english {
            collectionRef = db.collection("Data").document("en").collection("topics")
        } else {
            collectionRef = db.collection("Facts")
        }
        
        let ref = collectionRef.document(fact.documentID).collection("arguments").order(by: "upvotes", descending: true)
        
        ref.getDocuments(completion: { (snap, err) in
            if let error = err {
                print("We have an error: ", error.localizedDescription)
            } else {
                for document in snap!.documents {
                    
                    let docData = document.data()
                    let documentID = document.documentID
                    
                    guard let title = docData["title"] as? String,
                        let proOrContra = docData["proOrContra"] as? String,
                        let description = docData["description"] as? String
                        else {
                            continue    // Falls er das nicht als (String) zuordnen kann
                    }
                    
                    let upvotes = docData["upvotes"] as? Int ?? 0
                    let downvotes = docData["downvotes"] as? Int ?? 0
                    
                    let argument = Argument(addMoreDataCell: false)
                    
                    if let source = docData["source"] as? [String] {    // Unnecessary
                        argument.source = source
                    }
                    argument.title = title
                    argument.description = description
                    argument.proOrContra = proOrContra
                    argument.documentID = documentID
                    argument.upvotes = upvotes
                    argument.downvotes = downvotes
                    
                    argumentList.append(argument)
                }
            }
            let argument = Argument(addMoreDataCell: true)
            argument.proOrContra = "pro"
            
            argumentList.append(argument)
            
            let conArgument = Argument(addMoreDataCell: true)
            conArgument.proOrContra = "contra"
            
            argumentList.append(conArgument)
            
            returnData(argumentList)
        })
    }
    
    func getDeepestArgument(fact: Fact, argumentID: String, deepDataType: DeepDataType , returnData: @escaping ([Any]) -> Void) {
        
        var list = [Any]()
        
        if fact.documentID == "" {
            returnData(list)
        }
        switch deepDataType {
        case .sources:
            list = [Source]()
            dataPath = "sources"
        case .arguments:
            list = [Argument]()
            dataPath = "arguments"
        }
        
        var collectionRef: CollectionReference!
        let language = LanguageSelection().getLanguage()
        if fact.language == .english {
            collectionRef = db.collection("Data").document("en").collection("topics")
        } else {
            collectionRef = db.collection("Facts")
        }
        let argumentPath = collectionRef.document(fact.documentID).collection("arguments").document(argumentID).collection(dataPath)
        
        argumentPath.getDocuments(completion: { (snap, err) in
            
            if let error = err {
                print("Wir haben einen Error bei den tiefen Argumenten: ", error.localizedDescription)
            } else {
                
                for document in snap!.documents {
                    
                    let docData = document.data()
                    let documentID = document.documentID
                    
                    switch deepDataType {
                    case .arguments:
                        guard let title = docData["title"] as? String,
                            //                    let proOrContra = docData["proOrContra"] as? String,  // Not necessary?
                            let description = docData["description"] as? String
                            else {
                                continue    // Falls er das nicht als (String) zuordnen kann
                        }
                        
                        let argument = Argument(addMoreDataCell: false)
                        //                    argument.source = source
                        argument.title = title
                        argument.description = description
                        argument.documentID = documentID
                        //                argument.proOrContra = proOrContra
                        
                        list.append(argument)
                    case .sources:
                        guard let title = docData["title"] as? String,
                            let description = docData["description"] as? String,
                            let sourceLink = docData["source"] as? String
                            else {
                                continue
                        }
                        
                        let source = Source(addMoreDataCell: false)
                        source.title = title
                        source.description = description
                        source.source = sourceLink
                        source.documentID = documentID
                        
                        list.append(source)
                    }
                }
            }
            switch deepDataType {
            case .arguments:
                let argument = Argument(addMoreDataCell: true)
                
                list.append(argument)
            case .sources:
                    let source = Source(addMoreDataCell: true)
                    
                    list.append(source)
                }
            
            returnData(list)
        })
    }
}


class JobOffer {
    var title = ""
    var cellText = ""
    var descriptionText = ""
    var documentID = ""
    var stringDate = ""
    var interested = 0
    var category = ""
    var createDate = Date()
}

class Vote {
    var title = ""
    var subtitle = ""
    var description = ""
    var stringDate = ""
    var endOfVoteDate = ""
    var cost = ""
    var costDescription = ""
    var impact = Impact.light
    var impactDescription = ""
    var timeToRealization = 0   // In month
    var realizationTimeDescription = ""
    var commentCount = 0
    var documentID = ""
    var createDate = Date()
}

class BlogPost {
    var isCurrentProjectsCell = false
    var title = ""
    var subtitle = ""
    var description = ""
    var stringDate = ""
    var category = ""
    var poster = ""
    var profileImageURL = ""
    var imageURL = ""
    var createDate = Date()
}


