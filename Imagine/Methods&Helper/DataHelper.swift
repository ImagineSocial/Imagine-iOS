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

class DataHelper {
    
    /*  Every data from firebase which are not posts are fetched through this class
     */
    
    // Überall noch eine Wichtigkeitsvariable einfügen
    var dataPath = ""
    let db = Firestore.firestore()
    let handyHelper = HandyHelper()
    
    func getData(get: DataType, returnData: @escaping ([Any]) -> Void) {
        // "get" Variable kann "campaign" für CommunityEntscheidungen, "jobOffer" für Hilfe der Community und "fact" für Fakten Dings sein
        
        var list = [Any]()
        
        let settings = db.settings
        settings.areTimestampsInSnapshotsEnabled = true
        db.settings = settings
        
        var orderString = ""
        var descending = false
        
        
        switch get {
        case .blogPosts:
            list = [BlogPost]()
            dataPath = "BlogPosts"
            
            orderString = "createDate"
            
        case .campaign:
            list = [Campaign]()
            dataPath = "Campaigns"
            
            orderString = "campaignSupporter"
            descending = true
            
        case .vote:
            list = [Vote]()
            dataPath = "Votes"
            
            orderString = "endOfVoteDate"
            
        case .facts:
            list = [Fact]()
            dataPath = "Facts"
            
            orderString = "createDate"
            
        case .jobOffer:
            list = [JobOffer]()
            dataPath = "JobOffers"
            
            orderString = "importance"
            descending = true
            
            let jobOffer = JobOffer()   // Der erste Eintrag
            jobOffer.title = "Wir brauchen dich!"
            jobOffer.cellText = "Wenn du glaubst, mit deinem Wissen oder Erfahrung kannst du uns helfen, aber es gibt keine passende Ausschreibung, gib uns Bescheid! Wir sind auf klüge Köpfe angewiesen!"
            jobOffer.documentID = ""
            jobOffer.createDate = "15.05.2019"
            jobOffer.interested = 0
            jobOffer.category = "Allgemein"
            
            list.append(jobOffer)
        }
        
        let ref = db.collection(dataPath).order(by: orderString, descending: descending)
        
        ref.getDocuments { (querySnapshot, err) in
            
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                for document in querySnapshot!.documents {
                    
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
                        blogPost.createDate = stringDate
                        blogPost.poster = poster
                        blogPost.profileImageURL = profileImageURL
                        blogPost.category = category
                        blogPost.description = description
                        
                        if let imageURL = documentData["imageURL"] as? String {
                            blogPost.imageURL = imageURL
                        }
                        
                        list.append(blogPost)
                    case .campaign:
                        if let campaignType = documentData["campaignType"] as? String {
                            if campaignType == "normal" {
                                
                                guard let title = documentData["campaignTitle"] as? String,
                                    let shortBody = documentData["campaignShortBody"] as? String,
                                    let createTimestamp = documentData["campaignCreateTime"] as? Timestamp,
                                    let supporter = documentData["campaignSupporter"] as? Int,
                                    let opposition = documentData["campaignOpposition"] as? Int,
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
                                campaign.category = category
                                if let description = documentData["campaignExplanation"] as? String {
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
                        vote.createDate = createDate
                        vote.endOfVoteDate = endOfVoteDate
                        vote.cost = costString
                        vote.impact = impact
                        vote.timeToRealization = timeToRealization
                        vote.costDescription = costDescription
                        vote.impactDescription = impactDescription
                        vote.realizationTimeDescription = realizationTimeDescription
                        vote.documentID = documentID
                        
                        list.append(vote)
                        
                    case .facts:
                        
                        if let fact = self.addFact(data: documentData) {
                            fact.documentID = documentID
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
                        jobOffer.createDate = stringDate
                        jobOffer.interested = interestedCount
                        jobOffer.category = category
                        if let description = documentData["description"] as? String {
                            jobOffer.descriptionText = description
                        }
                        
                        list.append(jobOffer)
                    }
                }
            }
            if get == .facts {  // Control wether or not the fact is beeing followed by the current user
                if let user = Auth.auth().currentUser {
                    self.getFollowedTopics(userUID: user.uid, factList: (list as! [Fact])) { (checkedList) in
                        returnData(checkedList)
                    }
                } else {
                    returnData(list)
                }
            } else {
                returnData(list)
            }
        }
    }
    
    func getFollowedTopics(userUID: String, factList: [Fact], checkedList: @escaping ([Fact]) -> Void) {
        let topicRef = db.collection("Users").document(userUID).collection("topics")
        
        topicRef.getDocuments { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap {
                    for document in snap.documents {
                        for fact in factList {
                            if fact.documentID == document.documentID {
                                fact.beingFollowed = true
                            }
                        }
                    }
                    checkedList(factList)
                    
                }
            }
        }
    }
    
    func addFact(data: [String: Any]) -> Fact? {
        
        guard let name = data["name"] as? String,
            let createTimestamp = data["createDate"] as? Timestamp
            else {
                return nil
        }
        
        let stringDate = self.handyHelper.getStringDate(timestamp: createTimestamp)
        
        let fact = Fact(addMoreDataCell: false)
        fact.title = name
        fact.createDate = stringDate
        if let imageURL = data["imageURL"] as? String { // Not mandatory (in fact not selectable)
            fact.imageURL = imageURL
        }
        if let description = data["description"] as? String {   // Was introduced later on
            fact.description = description
        }
        if let displayType = data["displayOption"] as? String { // Was introduced later on
            fact.displayMode = self.getDisplayType(string: displayType)
        }
        
        if let displayNames = data["factDisplayNames"] as? String {
            fact.factDisplayNames = self.getDisplayNames(string: displayNames)
        }
        
        fact.fetchComplete = true
        
        return fact
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
    
    func getDeepData(documentID: String, returnData: @escaping ([Any]) -> Void) {
        
        var argumentList = [Argument]()
        
        let ref = self.db.collection("Facts").document(documentID).collection("arguments").order(by: "upvotes", descending: true)
        
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
    
    func getDeepestArgument(factID: String, argumentID: String, deepDataType: DeepDataType , returnData: @escaping ([Any]) -> Void) {
        
        var list = [Any]()
        
        switch deepDataType {
        case .sources:
            list = [Source]()
            dataPath = "sources"
        case .arguments:
            list = [Argument]()
            dataPath = "arguments"
        }
        
        let argumentPath = self.db.collection("Facts").document(factID).collection("arguments").document(argumentID).collection(dataPath)
        
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
    var createDate = ""
    var interested = 0
    var category = ""
}

class Vote {
    var title = ""
    var subtitle = ""
    var description = ""
    var createDate = ""
    var endOfVoteDate = ""
    var cost = ""
    var costDescription = ""
    var impact = Impact.light
    var impactDescription = ""
    var timeToRealization = 0   // In month
    var realizationTimeDescription = ""
    var commentCount = 0
    var documentID = ""
}

class BlogPost {
    var isCurrentProjectsCell = false
    var title = ""
    var subtitle = ""
    var description = ""
    var createDate = ""
    var category = ""
    var poster = ""
    var profileImageURL = ""
    var imageURL = ""
}


