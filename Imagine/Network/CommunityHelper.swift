//
//  CommunityHelper.swift
//  Imagine
//
//  Created by Malte Schoppe on 28.02.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseFirestore

class CommunityHelper {
    
    
    /// Fetches the first eight communities of their display option
    static func getMainCommunities(for displayOption: DisplayOption, language: Language? = nil, completion: @escaping ([Community]?) -> Void) {
        let query = FirestoreReference.collectionRef(.communities, queries: FirestoreQuery(field: "displayOption", equalTo: displayOption.rawValue), FirestoreQuery(field: "popularity", descending: true, limit: 8), language: language)
        
        FirestoreManager.shared.decode(query: query) { (result: Result<[Community], Error>) in
            switch result {
            case .success(let communities):
                completion(communities)
            case .failure(let error):
                print("We have an error fetching the main communities: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
    
    static func getAllCommunities(for displayOption: DisplayOption, language: Language? = nil, completion: @escaping ([Community]?) -> Void) {
        let query = FirestoreReference.collectionRef(.communities, queries: FirestoreQuery(field: "displayOption", equalTo: displayOption.rawValue), language: language)
        
        FirestoreManager.shared.decode(query: query) { (result: Result<[Community], Error>) in
            switch result {
            case .success(let communities):
                completion(communities)
            case .failure(let error):
                print("We have an error fetching the main communities: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
    
    
    static func getCommunity(withID id: String, language: Language? = nil, completion: @escaping (Community?) -> Void) {
        let reference = FirestoreReference.documentRef(.communities, documentID: id, language: language)
        
        FirestoreManager.shared.decodeSingle(reference: reference) { (result: Result<Community, Error>) in
            switch result {
            case .success(let community):
                completion(community)
            case .failure(let error):
                print("We have an error: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
    
    
}

// MARK: - FollowedCommunities
extension CommunityHelper {
    
    static func getFollowedCommunities(from userID: String, completion: @escaping ([Community]?) -> Void) {
        guard let userID = AuthenticationManager.shared.userID else {
            completion(nil)
            return
        }
        
        getFollowedTopicData(from: userID) { postData in
            guard let postData = postData, !postData.isEmpty else {
                completion(nil)
                return
            }
            
            loadFollowedTopics(postData: postData, completion: completion)
        }
    }
    
    static private func getFollowedTopicData(from userID: String, completion: @escaping ([PostData]?) -> Void) {
        let topicRef = FirestoreReference.collectionRef(.users, collectionReference: FirestoreCollectionReference(document: userID, collection: "topics"))
        
        FirestoreManager.shared.decode(query: topicRef) { (result: Result<[PostData], Error>) in
            switch result {
            case .success(let postData):
                completion(postData)
            case .failure(let error):
                print("We have an error fetching the post data for the followed topics: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
    
    static private func loadFollowedTopics(postData: [PostData], completion: @escaping ([Community]?) -> Void) {
        var failureIndex = 0
        var communities = [Community]()
        
        postData.enumerated().forEach { index, postDate in
            guard let id = postDate.id else {
                failureIndex += 1
                checkIfDone()
                return
            }
            
            getCommunity(withID: id, language: postDate.language) { community in
                guard let community = community else {
                    failureIndex += 1
                    checkIfDone()
                    return
                }

                communities.append(community)
                checkIfDone()
            }
        }
        
        func checkIfDone() {
            if (communities.count - failureIndex) == postData.count {
                communities = communities.sorted { $0.title ?? "" > $1.title ?? "" }
                completion(communities)
            }
        }
    }
}
