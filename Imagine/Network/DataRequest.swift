//
//  DataHelper.swift
//  Imagine
//
//  Created by Malte Schoppe on 21.05.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import Foundation
import FirebaseFirestore

enum DataType {
    case jobOffer
    case blogPosts
    case vote
}

enum DeepDataType {
    case arguments
    case sources
}

class DataRequest {
    
    /*  Every data from firebase which are not posts are fetched through this class
     */
    
    //MARK:- Variables
    var dataPath = ""
    let db = FirestoreRequest.shared.db
    let handyHelper = HandyHelper.shared
    
    //MARK:- Get Data 
    
    func getData(get: DataType, returnData: @escaping ([Any]) -> Void) {
        // "get" Variable kann "campaign" für CommunityEntscheidungen, "jobOffer" für Hilfe der Community und "fact" für COmmunites Dings sein
        
        var list = [Any]()
        
        var orderString = ""
        var descending = false
        
        var collectionRef: CollectionReference!
        let language = LanguageSelection.language
        
        switch get {
        case .blogPosts:
            list = [BlogPost]()
            dataPath = "BlogPosts"
            if language == .en {
                dataPath = "blogPosts"
            }
            
            orderString = "createDate"
            
        case .vote:
            list = [Vote]()
            dataPath = "Votes"
            if language == .en {
                dataPath = "votes"
            }
            
            orderString = "endOfVoteDate"
            
        case .jobOffer:
            list = [JobOffer]()
            dataPath = "JobOffers"
            if language == .en {
                dataPath = "jobOffers"
            }
            
            orderString = "importance"
            descending = true
            
            
        }
        
        if language == .en {
            collectionRef = db.collection("Data").document("en").collection(dataPath)
        } else {
            collectionRef = db.collection(dataPath)
        }
        var ref = collectionRef.order(by: orderString, descending: descending)
        
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
    
    
    func getDeepData(community: Community, completion: @escaping ([Any]) -> Void) {
        
        var argumentList = [Argument]()
        
        guard let communityID = community.id else {
            print("We have an error fetching arguments")
            completion(argumentList)
            return
        }
        
        var collectionRef: CollectionReference!

        if community.language == .en {
            collectionRef = db.collection("Data").document("en").collection("topics")
        } else {
            collectionRef = db.collection("Facts")
        }
        
        let ref = collectionRef.document(communityID).collection("arguments").order(by: "upvotes", descending: true)
        
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
                            continue
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
            
            completion(argumentList)
        })
    }
    
    func getDeepestArgument(community: Community, argumentID: String, deepDataType: DeepDataType , completion: @escaping ([Any]) -> Void) {
        
        var list = [Any]()
        
        guard let communityID = community.id else {
            completion(list)
            return
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
        if community.language == .en {
            collectionRef = db.collection("Data").document("en").collection("topics")
        } else {
            collectionRef = db.collection("Facts")
        }
        let argumentPath = collectionRef.document(communityID).collection("arguments").document(argumentID).collection(dataPath)
        
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
                                continue
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
            
            completion(list)
        })
    }
}
